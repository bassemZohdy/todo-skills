#!/usr/bin/env bash
# Runs one trial scenario with a fresh Claude Code agent in headless mode and checks the result.
# Usage: [TRIAL_LABEL=<word>] [TRIAL_TIMEOUT=<seconds>] [TRIAL_REUSE=1] bash tests/trials/run-claude.sh <runs-dir> <scenario> [model]
# Needs the claude CLI (logged in), git, and whatever the scenario's toolchain needs (node 22; java 17 + maven for the Java ones).
# Layout: the scratch project is <runs-dir>/w-<random>/repo, a new one for every invocation, so that the working folder the
# agent is given does not name the scenario (TRIAL_REUSE=1: a second invocation continues the project of the one before).
# Every invocation writes its own folder <runs-dir>/<scenario>/evidence/<UTC time>-<pid>[-label]/ with project.txt (the
# project's path below <runs-dir>), setup.log, prompt.txt, command.txt, session.jsonl (claude's stream-json session: every tool
# call and result, which tdd-order.sh scores), agent.err (its stderr), agent.log and report.txt (the final answer), agent-exit.txt,
# assert.log, assert-exit.txt, outcome.txt and SHA256SUMS. A new folder is created with mkdir (never -p), so nothing earlier is
# overwritten; nothing is deleted. TRIAL_TIMEOUT is the agent's time limit in seconds (default 1500).
# outcome.txt is PASS, FAIL, INFRA_ERROR (agent exit not 0, for example 124 after the timeout, or a verifier that failed) or
# UNVERIFIED (no report). Assertions run through assert-exec.sh, isolated by default on native Windows.
# The agent runs shell commands and edits files without asking, so run it in a throwaway environment you control.
set -u
runs="${1:?usage: run-claude.sh <runs-dir> <scenario> [model]}"; scenario="${2:?scenario}"; model="${3:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tests/trials/trial-lib.sh
. "$here/trial-lib.sh"
limit="$(trial_limit)" || exit 2   # the agent's time limit in seconds, refused before anything is made
mkdir -p "$runs/$scenario/evidence"; runs="$(cd "$runs" && pwd)"; sd="$runs/$scenario"
# The scratch project is not in the scenario's folder: its path is the working folder the prompt gives the agent, and that
# must not name the scenario. It is <runs>/w-<random>/repo, a new one for every invocation, and project.txt in the evidence
# folder points to it (relative to <runs>); score.sh follows that. TRIAL_REUSE=1 continues the project of this scenario's
# newest invocation instead (or <runs>/<scenario>/repo of the old layout).
proj="$(trial_project "$runs" "$scenario")" || exit 2
repo="$runs/$proj"
id="$(date -u +%Y%m%dT%H%M%SZ)-$$${TRIAL_LABEL:+-$TRIAL_LABEL}"
ev="$sd/evidence/$id"
mkdir "$ev" 2>/dev/null || { echo "evidence folder $ev already exists; refusing to overwrite"; exit 2; }
printf '%s\n' "$proj" > "$ev/project.txt"
if [ -d "$repo" ] && [ -n "$(ls -A "$repo" 2>/dev/null)" ]; then
  echo "reused the existing repo $repo (setup not run)" > "$ev/setup.log"
elif ! bash "$here/setup.sh" "$repo" "$scenario" >"$ev/setup.log" 2>&1; then
  printf 'INFRA_ERROR\n' > "$ev/outcome.txt"; echo "setup failed (see $ev/setup.log)"; exit 2
fi
bash "$here/prompt.sh" "$repo" "$scenario" > "$ev/prompt.txt" || { printf 'INFRA_ERROR\n' > "$ev/outcome.txt"; echo "no prompt"; exit 2; }
prompt="$(cat "$ev/prompt.txt")"
args=(-p "$prompt" --output-format stream-json --verbose --permission-mode acceptEdits --allowedTools "Bash,Read,Write,Edit,Glob,Grep" --add-dir "$repo")
[ -z "$model" ] || args+=(--model "$model")
# TRIAL_CLAUDE_ARGS adds claude flags, for example "--setting-sources project,local --strict-mcp-config" to keep user plugins out.
# shellcheck disable=SC2206
[ -z "${TRIAL_CLAUDE_ARGS:-}" ] || args+=(${TRIAL_CLAUDE_ARGS})
# The limit is applied by the timeout program; where there is none (macOS unless coreutils is installed) nothing limits the
# run, and command.txt says so instead of naming a limit that was not applied.
tmo=(); tpre=""; tnote="   # no timeout program on this host: the limit of $limit seconds was not applied"
if command -v timeout >/dev/null 2>&1; then tmo=(timeout "$limit"); tpre="timeout $limit "; tnote=""; fi
printf 'cd %s && %sclaude -p <prompt.txt> --output-format stream-json --verbose --permission-mode acceptEdits --allowedTools "Bash,Read,Write,Edit,Glob,Grep" --add-dir %s%s%s\n' "$repo" "$tpre" "$repo" "${model:+ --model $model}" "$tnote" > "$ev/command.txt"
# The agent's environment must not name the run either: no TRIAL_LABEL, and OLDPWD is the project, put into the environment of the
# agent by env itself: bash 3.2 (macOS) did not pass on an OLDPWD that the runner exported by hand, so the agent saw none (FIX-142).
( cd "$repo" && env -u TRIAL_LABEL OLDPWD="$repo" ${tmo[@]+"${tmo[@]}"} claude "${args[@]}" ) >"$ev/session.jsonl" 2>"$ev/agent.err"
code=$?
printf '%s\n' "$code" > "$ev/agent-exit.txt"
python3 -I "$here/claude-result.py" "$ev/session.jsonl" > "$ev/report.txt" 2>>"$ev/agent.err"
rrc=$?
cp "$ev/report.txt" "$ev/agent.log"
bash "$here/snapshot-git.sh" "$repo" > "$ev/git-state.txt" 2>&1   # before assert.sh, which may check out branches
TRIAL_REPORT="$ev/report.txt" bash "$here/assert-exec.sh" "$repo" "$scenario" >"$ev/assert.log" 2>&1
arc=$?
printf '%s\n' "$arc" > "$ev/assert-exit.txt"
if [ "$code" != 0 ]; then outcome=INFRA_ERROR
elif [ ! -s "$ev/session.jsonl" ]; then outcome=INFRA_ERROR; echo "claude wrote no session stream (see agent.err)" > "$ev/infra-signature.txt"
elif [ "$rrc" != 0 ]; then outcome=INFRA_ERROR; echo "the report could not be read from the session stream (see agent.err)" > "$ev/infra-signature.txt"
elif [ ! -s "$ev/report.txt" ]; then outcome=UNVERIFIED
elif [ "$arc" = 0 ]; then outcome=PASS
elif [ "$arc" = 1 ]; then outcome=FAIL
else outcome=INFRA_ERROR; fi   # the verifier itself failed or timed out (FIX-041)
printf '%s\n' "$outcome" > "$ev/outcome.txt"
( cd "$ev" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -- * > SHA256SUMS; else shasum -a 256 -- * > SHA256SUMS; fi )
tail -3 "$ev/assert.log"; echo "outcome: $outcome ($ev)"
[ "$outcome" = PASS ]
