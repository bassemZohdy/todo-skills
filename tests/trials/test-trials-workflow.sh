#!/usr/bin/env bash
# Checks .github/workflows/trials.yml (TASK-118): it starts only on manual trigger, pins every action to a commit, reads no
# secret, may not write to the repository, runs on Ubuntu and macOS, and installs only CLI versions that are named. The checks run
# on the real file and must fail on copies that break each rule. No agent and no network needed.
# Usage: bash tests/trials/test-trials-workflow.sh    Works in a temporary directory that it removes at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
wf="$here/../../.github/workflows/trials.yml"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

# Prints one line per broken rule; no output means the file follows every rule.
problems() {
  f="$1"
  [ -f "$f" ] || { echo "missing: $f"; return; }
  on_block="$(awk '/^on:/{p=1;next} /^[A-Za-z]/{p=0} p' "$f")"
  printf '%s\n' "$on_block" | grep -qE '^  workflow_dispatch:' || echo "no workflow_dispatch trigger"
  printf '%s\n' "$on_block" | grep -E '^  [A-Za-z_]+:' | grep -vE '^  workflow_dispatch:' | sed 's/^ */other trigger: /'
  # every action is pinned to a 40-character commit
  grep -E '^[[:space:]]*-?[[:space:]]*uses:' "$f" | grep -vE 'uses:[[:space:]]*[^@[:space:]]+@[0-9a-f]{40}([[:space:]]|$)' | sed 's/^ */unpinned action: /'
  grep -qE '\$\{\{[[:space:]]*secrets\.' "$f" && echo "reads a secret"
  grep -qE '^permissions:' "$f" || echo "no top-level permissions"
  grep -E '^[[:space:]]+[a-z-]+:[[:space:]]*write' "$f" | sed 's/^ */write permission: /'
  grep -q 'ubuntu-latest' "$f" || echo "no ubuntu-latest"
  grep -q 'macos-latest' "$f" || echo "no macos-latest"
  # every npm install of a CLI names its version
  grep -E 'npm (install|i) ' "$f" | grep -vE '@[0-9]+\.[0-9]+\.[0-9]+' | sed 's/^ */unversioned install: /'
}

out="$(problems "$wf")"
if [ -z "$out" ]; then ok "trials.yml follows every rule"; else bad "trials.yml breaks a rule:"; printf '%s\n' "$out" | sed 's/^/        /'; fi

# a second check on the facts the task promises: both CLIs, pinned
grep -qE '@openai/codex@[0-9]+\.[0-9]+\.[0-9]+' "$wf" 2>/dev/null && ok "installs a named Codex CLI version" || bad "no pinned Codex CLI install"
grep -qE '@anthropic-ai/claude-code@[0-9]+\.[0-9]+\.[0-9]+' "$wf" 2>/dev/null && ok "installs a named Claude Code CLI version" || bad "no pinned Claude Code CLI install"

# the negative cases: a copy that breaks one rule must be reported
if [ -f "$wf" ]; then
  neg() {  # name, sed expression applied to a copy
    sed -E "$2" "$wf" > "$tmp/$1.yml"
    if [ -n "$(problems "$tmp/$1.yml")" ]; then ok "a copy that $3 is reported"; else bad "a copy that $3 passes"; fi
  }
  neg push 's/^  workflow_dispatch:/  push:\n  workflow_dispatch:/' "adds a push trigger"
  neg pr 's/^  workflow_dispatch:/  pull_request:\n  workflow_dispatch:/' "adds a pull_request trigger"
  neg sched 's/^  workflow_dispatch:/  schedule:\n  workflow_dispatch:/' "adds a schedule trigger"
  neg unpin '0,/(uses:[[:space:]]*[^@[:space:]]+)@[0-9a-f]{40}/s//\1@v4/' "uses an unpinned action"
  neg secret '0,/^    steps:/s//    env:\n      K: ${{ secrets.OPENAI_API_KEY }}\n    steps:/' "reads a secret"
  neg write 's/^  contents: read/  contents: write/' "may write to the repository"
  neg unver 's/(npm (install|i) .*)@[0-9]+\.[0-9]+\.[0-9]+/\1/' "installs a CLI without a version"
  neg nomac 's/macos-latest/ubuntu-latest/' "drops macOS"
fi
[ -f "$wf" ] && ! grep -qE '^on:' "$wf" && bad "no on: block"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
