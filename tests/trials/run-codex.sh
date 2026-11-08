#!/usr/bin/env bash
# Runs one trial scenario with a fresh Codex process (codex exec) and checks the result. Same layout and verdicts as run-claude.sh.
# Usage: [TRIAL_LABEL=<word>] bash tests/trials/run-codex.sh <runs-dir> <scenario>
# Needs the codex CLI, logged in, git, and the scenario's toolchain. Put <runs-dir> OUTSIDE the temp folder (see codex-exec.sh).
# <runs-dir>/<scenario>/repo.todo is created for the lane worktrees; codex-exec.sh makes it a writable root.
# Every invocation writes <runs-dir>/<scenario>/evidence/<UTC time>-<pid>[-label]/ with setup.log, prompt.txt, command.txt,
# session.log, session-id.txt, git-state.txt, agent-exit.txt, report.txt, assert.log, assert-exit.txt, outcome.txt and SHA256SUMS; nothing earlier is overwritten.
# outcome.txt: PASS, FAIL, INFRA_ERROR (codex exit not 0, e.g. 124 after the timeout, or the output shows a sandbox or host block, see
# infra-signature.sh; the matching line is kept in infra-signature.txt) or UNVERIFIED (no report).
set -u
runs="${1:?usage: run-codex.sh <runs-dir> <scenario>}"; scenario="${2:?scenario}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case "$(cd "$runs" 2>/dev/null && pwd)/" in */[Tt]emp/*|/tmp/*|*/AppData/Local/Temp/*) echo "WARNING: $runs is under a temp folder; the Windows sandbox may leave it writable. Use another folder." >&2 ;; esac
sd="$runs/$scenario"; mkdir -p "$sd/evidence"; sd="$(cd "$sd" && pwd)"; repo="$sd/repo"
id="$(date -u +%Y%m%dT%H%M%SZ)-$$${TRIAL_LABEL:+-$TRIAL_LABEL}"
ev="$sd/evidence/$id"
mkdir "$ev" 2>/dev/null || { echo "evidence folder $ev already exists; refusing to overwrite"; exit 2; }
if [ -e "$repo" ] && [ -n "$(ls -A "$repo" 2>/dev/null)" ]; then
  echo "reused the existing repo $repo (setup not run)" > "$ev/setup.log"
else
  bash "$here/setup.sh" "$repo" "$scenario" >"$ev/setup.log" 2>&1 \
    || { printf 'INFRA_ERROR\n' > "$ev/outcome.txt"; echo "setup failed (see $ev/setup.log)"; exit 2; }
fi
case "$scenario" in lanes|multi-module) mkdir -p "$repo.todo" ;; esac
bash "$here/prompt.sh" "$repo" "$scenario" > "$ev/prompt.txt" || { printf 'INFRA_ERROR\n' > "$ev/outcome.txt"; echo "no prompt"; exit 2; }
printf 'bash tests/trials/codex-exec.sh %s %s/prompt.txt %s/report.txt   # see codex-exec.sh for the codex flags\n' "$repo" "$ev" "$ev" > "$ev/command.txt"
bash "$here/codex-exec.sh" "$repo" "$ev/prompt.txt" "$ev/report.txt" >"$ev/session.log" 2>&1
code=$?
printf '%s\n' "$code" > "$ev/agent-exit.txt"
[ -f "$ev/report.txt" ] || : > "$ev/report.txt"
grep -m1 '^session id:' "$ev/session.log" > "$ev/session-id.txt" 2>/dev/null || : > "$ev/session-id.txt"   # proof of a fresh session
bash "$here/snapshot-git.sh" "$repo" > "$ev/git-state.txt" 2>&1                                             # before assert.sh, which may check out branches
TRIAL_REPORT="$ev/report.txt" bash "$here/assert-exec.sh" "$repo" "$scenario" >"$ev/assert.log" 2>&1
arc=$?
printf '%s\n' "$arc" > "$ev/assert-exit.txt"
if [ "$code" != 0 ]; then outcome=INFRA_ERROR
elif [ ! -s "$ev/report.txt" ]; then outcome=UNVERIFIED
elif [ "$arc" = 0 ]; then outcome=PASS
elif [ "$arc" = 1 ]; then outcome=FAIL
else outcome=INFRA_ERROR; fi   # the verifier itself failed or timed out (FIX-041)
# a block by the sandbox or the host is not a skill failure: say INFRA_ERROR and keep the matching line as the reason
if [ "$outcome" != PASS ] && sig="$(bash "$here/infra-signature.sh" "$ev/report.txt" "$ev/session.log")"; then
  outcome=INFRA_ERROR; printf '%s\n' "$sig" > "$ev/infra-signature.txt"
fi
printf '%s\n' "$outcome" > "$ev/outcome.txt"
( cd "$ev" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -- * > SHA256SUMS; else shasum -a 256 -- * > SHA256SUMS; fi )
tail -3 "$ev/assert.log"; echo "outcome: $outcome ($ev)"
[ "$outcome" = PASS ]
