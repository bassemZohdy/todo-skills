#!/usr/bin/env bash
# Runs one trial scenario with a fresh Claude Code agent in headless mode and checks the result.
# Usage: bash tests/trials/run-claude.sh <runs-dir> <scenario> [model]
# Needs the claude CLI (logged in), git, and whatever the scenario's toolchain needs (node 22; java 17 + maven for the Java ones).
# Writes <runs-dir>/<scenario>/{repo,setup.log,agent.log,assert.log}; never deletes anything. The agent works only in the repo folder.
# The agent runs shell commands and edits files without asking, so run it in a throwaway environment you control.
set -u
runs="${1:?usage: run-claude.sh <runs-dir> <scenario> [model]}"; scenario="${2:?scenario}"; model="${3:-}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$runs/$scenario"; repo="$(cd "$runs/$scenario" && pwd)/repo"
bash "$here/setup.sh" "$repo" "$scenario" >"$runs/$scenario/setup.log" 2>&1 || { echo "setup failed"; exit 2; }
prompt="$(bash "$here/prompt.sh" "$repo" "$scenario")"
args=(-p "$prompt" --permission-mode acceptEdits --allowedTools "Bash,Read,Write,Edit,Glob,Grep" --add-dir "$repo")
[ -z "$model" ] || args+=(--model "$model")
( cd "$repo" && timeout 1500 claude "${args[@]}" ) >"$runs/$scenario/agent.log" 2>&1
echo "agent exit: $?" >>"$runs/$scenario/agent.log"
bash "$here/assert.sh" "$repo" "$scenario" >"$runs/$scenario/assert.log" 2>&1
rc=$?; tail -3 "$runs/$scenario/assert.log"; exit $rc
