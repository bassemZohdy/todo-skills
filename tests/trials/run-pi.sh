#!/usr/bin/env bash
# Runs one trial scenario with a fresh pi agent (https://github.com/badlogic/pi-mono, a minimal coding harness) in
# print mode and checks the result. The twin of run-claude.sh: same layout, same verdicts, same evidence files.
# Usage: [TRIAL_LABEL=<word>] [TRIAL_PI_PROVIDER=zai] bash tests/trials/run-pi.sh <runs-dir> <scenario> [model]
# Default model: glm-5.3 on provider zai (needs ZAI_API_KEY in the environment). Needs the pi CLI, git, and whatever the
# scenario's toolchain needs (node 22; java 17 + maven for the Java ones).
# pi has no permission prompts, so the agent runs shell commands and edits files without asking: run it only in a
# throwaway environment. It is started with no extensions, no pi skills and no AGENTS.md/CLAUDE.md discovery, so the
# only skill text it sees is what the trial prompt points it at (.claude/skills/ in the scratch repo), exactly as for
# the other agents. The tool allowlist is "read,bash,edit,write" (TRIAL_PI_TOOLS overrides it); on native Windows pi
# has no bash tool, its shell tool is "powershell", so the default there is "read,powershell,edit,write" and the agent
# starts Git Bash from it.
# Layout and evidence files as in run-claude.sh, plus session/ (pi's own session log: every tool call and result),
# versions.txt, verifier.txt (isolated or not) and tool-calls.txt (zero is INFRA_ERROR).
# outcome.txt is PASS, FAIL, INFRA_ERROR (agent exit not 0, for example 124 after the timeout) or UNVERIFIED (no report).
set -u
runs="${1:?usage: run-pi.sh <runs-dir> <scenario> [model]}"; scenario="${2:?scenario}"; model="${3:-glm-5.3}"
provider="${TRIAL_PI_PROVIDER:-zai}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
sd="$runs/$scenario"; mkdir -p "$sd/evidence"; repo="$(cd "$sd" && pwd)/repo"
id="$(date -u +%Y%m%dT%H%M%SZ)-$$${TRIAL_LABEL:+-$TRIAL_LABEL}"
ev="$(cd "$sd" && pwd)/evidence/$id"   # absolute: pi runs after a cd into the repo and gets --session-dir "$ev/session"
mkdir "$ev" 2>/dev/null || { echo "evidence folder $ev already exists; refusing to overwrite"; exit 2; }
if [ -d "$repo" ] && [ -n "$(ls -A "$repo" 2>/dev/null)" ]; then
  echo "reused the existing repo $repo (setup not run)" > "$ev/setup.log"
elif ! bash "$here/setup.sh" "$repo" "$scenario" >"$ev/setup.log" 2>&1; then
  printf 'INFRA_ERROR\n' > "$ev/outcome.txt"; echo "setup failed (see $ev/setup.log)"; exit 2
fi
bash "$here/prompt.sh" "$repo" "$scenario" > "$ev/prompt.txt" || { printf 'INFRA_ERROR\n' > "$ev/outcome.txt"; echo "no prompt"; exit 2; }
prompt="$(cat "$ev/prompt.txt")"
case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) deftools="read,powershell,edit,write" ;; *) deftools="read,bash,edit,write" ;; esac
tools="${TRIAL_PI_TOOLS:-$deftools}"
args=(-p --provider "$provider" --model "$model" --tools "$tools" --session-dir "$ev/session"
      --no-extensions --no-skills --no-context-files --no-prompt-templates --no-themes)
# TRIAL_PI_ARGS adds pi flags, for example "--thinking high".
# shellcheck disable=SC2206
[ -z "${TRIAL_PI_ARGS:-}" ] || args+=(${TRIAL_PI_ARGS})
printf 'cd %s && timeout 1500 pi -p --provider %s --model %s --tools %s --session-dir <evidence>/session --no-extensions --no-skills --no-context-files --no-prompt-templates --no-themes %s<prompt.txt>\n' \
  "$repo" "$provider" "$model" "$tools" "${TRIAL_PI_ARGS:+$TRIAL_PI_ARGS }" > "$ev/command.txt"
# Pin what ran: the repo's evidence always names the agent version. verifier.txt says whether assert.sh ran isolated.
{ printf 'pi %s
provider %s
model %s
thinking %s
tools %s
node %s
' "$(pi --version 2>&1 | head -1)" "$provider" "$model"     "${TRIAL_PI_ARGS:-default}" "$tools" "$(node -v 2>&1 | head -1)"; java -version 2>&1 | head -1; } > "$ev/versions.txt"
case "$(uname -s 2>/dev/null)" in MINGW*|MSYS*|CYGWIN*) [ "${TRIAL_WINDOWS_ISOLATION:-1}" = 1 ] && v=isolated || v="UNISOLATED (TRIAL_WINDOWS_ISOLATION=0): not equal to the isolated Windows batches" ;; *) [ "${TRIAL_LINUX_ISOLATION:-0}" = 1 ] && v=isolated || v="unisolated (controller permissions)" ;; esac
printf 'verifier: %s
' "$v" > "$ev/verifier.txt"
tmo=(); command -v timeout >/dev/null 2>&1 && tmo=(timeout 1500)
( cd "$repo" && ${tmo[@]+"${tmo[@]}"} pi "${args[@]}" -- "$prompt" ) >"$ev/agent.log" 2>&1
code=$?
printf '%s\n' "$code" > "$ev/agent-exit.txt"
cp "$ev/agent.log" "$ev/report.txt"
bash "$here/snapshot-git.sh" "$repo" > "$ev/git-state.txt" 2>&1   # before assert.sh, which may check out branches
TRIAL_REPORT="$ev/report.txt" bash "$here/assert-exec.sh" "$repo" "$scenario" >"$ev/assert.log" 2>&1
arc=$?
printf '%s\n' "$arc" > "$ev/assert-exit.txt"
# pi started with an allowlist it cannot satisfy runs with no tools at all and still answers, so a run with zero tool calls
# is an environment fault, never a skill FAIL. Count the tool calls in pi's own session log.
calls="$(cat "$ev"/session/*.jsonl 2>/dev/null | grep -o '"type":"toolCall"' | wc -l | tr -d ' ')"
printf '%s
' "${calls:-0}" > "$ev/tool-calls.txt"
if [ "$code" != 0 ]; then outcome=INFRA_ERROR
elif [ "${calls:-0}" = 0 ]; then outcome=INFRA_ERROR; echo "no tool call in the pi session: pi ran without tools (see $ev/session)" > "$ev/infra-signature.txt"
elif [ ! -s "$ev/report.txt" ]; then outcome=UNVERIFIED
elif [ "$arc" = 0 ]; then outcome=PASS
elif [ "$arc" = 1 ]; then outcome=FAIL
else outcome=INFRA_ERROR; fi   # the verifier itself failed or timed out (FIX-041)
printf '%s\n' "$outcome" > "$ev/outcome.txt"
# Checksums cover every evidence file, pi's session log included; written to a temp name first so the sum file never lists itself.
( cd "$ev" && if command -v sha256sum >/dev/null 2>&1; then sum=(sha256sum); else sum=(shasum -a 256); fi && find . -type f -print0 | sort -z | xargs -0 "${sum[@]}" > ../SHA256SUMS.$$ && mv ../SHA256SUMS.$$ SHA256SUMS )
tail -3 "$ev/assert.log"; echo "outcome: $outcome ($ev)"
[ "$outcome" = PASS ]
