#!/usr/bin/env bash
# Runs one trial scenario with a fresh Claude Code agent in headless mode and checks the result.
# Usage: [TRIAL_LABEL=<word>] bash tests/trials/run-claude.sh <runs-dir> <scenario> [model]
# Needs the claude CLI (logged in), git, and whatever the scenario's toolchain needs (node 22; java 17 + maven for the Java ones).
# Layout: <runs-dir>/<scenario>/repo is the scratch project (set up on the first run, reused afterwards, so a second
# invocation continues the same repo). Every invocation writes its own folder <runs-dir>/<scenario>/evidence/<UTC time>-<pid>[-label]/
# with setup.log, prompt.txt, command.txt, agent.log, agent-exit.txt, report.txt, assert.log, assert-exit.txt, outcome.txt and
# SHA256SUMS. A new folder is created with mkdir (never -p), so nothing earlier is overwritten; nothing is deleted.
# outcome.txt is PASS, FAIL, INFRA_ERROR (agent exit not 0, for example 124 after the timeout, or a verifier that failed) or
# UNVERIFIED (no report). Assertions run through assert-exec.sh, isolated by default on native Windows.
# The agent runs shell commands and edits files without asking, so run it in a throwaway environment you control.
set -u
runs="${1:?usage: run-claude.sh <runs-dir> <scenario> [model]}"; scenario="${2:?scenario}"; model="${3:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sd="$runs/$scenario"; mkdir -p "$sd/evidence"; repo="$(cd "$sd" && pwd)/repo"
id="$(date -u +%Y%m%dT%H%M%SZ)-$$${TRIAL_LABEL:+-$TRIAL_LABEL}"
ev="$sd/evidence/$id"
mkdir "$ev" 2>/dev/null || { echo "evidence folder $ev already exists; refusing to overwrite"; exit 2; }
if [ -d "$repo" ] && [ -n "$(ls -A "$repo" 2>/dev/null)" ]; then
  echo "reused the existing repo $repo (setup not run)" > "$ev/setup.log"
elif ! bash "$here/setup.sh" "$repo" "$scenario" >"$ev/setup.log" 2>&1; then
  printf 'INFRA_ERROR\n' > "$ev/outcome.txt"; echo "setup failed (see $ev/setup.log)"; exit 2
fi
bash "$here/prompt.sh" "$repo" "$scenario" > "$ev/prompt.txt" || { printf 'INFRA_ERROR\n' > "$ev/outcome.txt"; echo "no prompt"; exit 2; }
prompt="$(cat "$ev/prompt.txt")"
args=(-p "$prompt" --permission-mode acceptEdits --allowedTools "Bash,Read,Write,Edit,Glob,Grep" --add-dir "$repo")
[ -z "$model" ] || args+=(--model "$model")
# TRIAL_CLAUDE_ARGS adds claude flags, for example "--setting-sources project,local --strict-mcp-config" to keep user plugins out.
# shellcheck disable=SC2206
[ -z "${TRIAL_CLAUDE_ARGS:-}" ] || args+=(${TRIAL_CLAUDE_ARGS})
printf 'cd %s && timeout 1500 claude -p <prompt.txt> --permission-mode acceptEdits --allowedTools "Bash,Read,Write,Edit,Glob,Grep" --add-dir %s%s\n' "$repo" "$repo" "${model:+ --model $model}" > "$ev/command.txt"
tmo=(); command -v timeout >/dev/null 2>&1 && tmo=(timeout 1500)   # macOS has no timeout unless coreutils is installed
( cd "$repo" && ${tmo[@]+"${tmo[@]}"} claude "${args[@]}" ) >"$ev/agent.log" 2>&1
code=$?
printf '%s\n' "$code" > "$ev/agent-exit.txt"
cp "$ev/agent.log" "$ev/report.txt"
bash "$here/snapshot-git.sh" "$repo" > "$ev/git-state.txt" 2>&1   # before assert.sh, which may check out branches
TRIAL_REPORT="$ev/report.txt" bash "$here/assert-exec.sh" "$repo" "$scenario" >"$ev/assert.log" 2>&1
arc=$?
printf '%s\n' "$arc" > "$ev/assert-exit.txt"
if [ "$code" != 0 ]; then outcome=INFRA_ERROR
elif [ ! -s "$ev/report.txt" ]; then outcome=UNVERIFIED
elif [ "$arc" = 0 ]; then outcome=PASS
elif [ "$arc" = 1 ]; then outcome=FAIL
else outcome=INFRA_ERROR; fi   # the verifier itself failed or timed out (FIX-041)
printf '%s\n' "$outcome" > "$ev/outcome.txt"
( cd "$ev" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -- * > SHA256SUMS; else shasum -a 256 -- * > SHA256SUMS; fi )
tail -3 "$ev/assert.log"; echo "outcome: $outcome ($ev)"
[ "$outcome" = PASS ]
