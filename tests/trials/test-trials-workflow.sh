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

# the negative cases: a copy that breaks one rule must differ from the file and be reported. Only commands that BSD sed and awk
# (macOS) have are used: no 0,/re/ address, no \n in a replacement and no interval in an awk regex (FIX-122).
if [ -f "$wf" ]; then
  check() {  # name, what the copy does; the copy is already in $tmp/<name>.yml
    if cmp -s "$wf" "$tmp/$1.yml"; then bad "the copy that $2 is identical to trials.yml"
    elif [ -n "$(problems "$tmp/$1.yml")" ]; then ok "a copy that $2 is reported"
    else bad "a copy that $2 passes"; fi
  }
  addtrigger() {  # name, trigger line: inserts the trigger under on:
    awk -v t="$2" '{ print } /^on:/ { print t }' "$wf" > "$tmp/$1.yml"
  }
  addtrigger push '  push:'; check push "adds a push trigger"
  addtrigger pr '  pull_request:'; check pr "adds a pull_request trigger"
  addtrigger sched '  schedule:'; check sched "adds a schedule trigger"
  n="$(grep -n 'uses:' "$wf" | head -1 | cut -d: -f1)"
  sed "${n}s/@[0-9a-f]*/@v4/" "$wf" > "$tmp/unpin.yml"; check unpin "uses an unpinned action"
  { cat "$wf"; printf '      - run: echo ${{ secrets.OPENAI_API_KEY }}\n'; } > "$tmp/secret.yml"; check secret "reads a secret"
  sed 's/^  contents: read/  contents: write/' "$wf" > "$tmp/write.yml"; check write "may write to the repository"
  sed -E 's/(npm (install|i) .*)@[0-9]+\.[0-9]+\.[0-9]+/\1/' "$wf" > "$tmp/unver.yml"; check unver "installs a CLI without a version"
  sed 's/macos-latest/ubuntu-latest/' "$wf" > "$tmp/nomac.yml"; check nomac "drops macOS"
fi
[ -f "$wf" ] && ! grep -qE '^on:' "$wf" && bad "no on: block"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
