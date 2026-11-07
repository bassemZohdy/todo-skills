#!/usr/bin/env bash
# Checks that every scenario's prompt asks for as much work as its assertions require (no agent needed).
# /todo-continue runs ONE node per invocation. A scenario whose assert.sh needs a drained root and whose starting tree has
# child nodes therefore cannot be reached in "one invocation": its prompt must not say "Stop after one invocation"
# and must tell the agent to run the command again until the tree is drained.
# Usage: bash tests/trials/test-prompt-assert.sh    Works in a temporary directory that it removes at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

block() { # the assert.sh case block of one scenario
  awk -v s="$1" '
    $0 ~ ("^" s "\\)") || $0 ~ ("\\|" s "[|)]") || $0 ~ ("^" s "\\|") { on = 1; next }
    on && /^  ;;/ { on = 0 }
    on' "$here/assert.sh"
}

scenarios="$(sed -n 's/^# Scenarios: //p; s/^#   //p' "$here/setup.sh" | tr '|' '\n' | tr -d ' ' | grep .)"
checked=0
for s in $scenarios; do
  repo="$tmp/$s/repo"; mkdir -p "$tmp/$s"
  bash "$here/setup.sh" "$repo" "$s" >/dev/null 2>&1 || { bad "$s: setup failed"; continue; }
  prompt="$(bash "$here/prompt.sh" "$repo" "$s" 2>/dev/null)" || { bad "$s: no prompt"; continue; }
  needs_drain=no; has_children=no
  block "$s" | grep -q 'no roots left' && needs_drain=yes
  # a child node is a task line whose ID has a dot, indented under its parent (TODO.md as it is on any branch at setup)
  for ref in $(git -C "$repo" for-each-ref --format='%(refname)' refs/heads 2>/dev/null); do
    git -C "$repo" show "$ref:TODO.md" 2>/dev/null | grep -Eq '^ +- \[.\] \*\*[A-Z]+-[0-9]+\.[0-9]+' && has_children=yes
  done
  [ "$has_children" = yes ] || { [ -f "$repo/TODO.md" ] && grep -Eq '^ +- \[.\] \*\*[A-Z]+-[0-9]+\.[0-9]+' "$repo/TODO.md" && has_children=yes; }
  if [ "$needs_drain" = yes ] && [ "$has_children" = yes ]; then
    checked=$((checked + 1))
    if printf '%s\n' "$prompt" | grep -q 'Stop after one invocation'; then
      bad "$s: assert.sh needs a drained tree with children, but the prompt says to stop after one invocation"
    elif printf '%s\n' "$prompt" | grep -qi 'again\|until'; then
      ok "$s: prompt asks to repeat the command until the tree is drained"
    else
      bad "$s: assert.sh needs a drained tree with children, but the prompt does not say to repeat the command"
    fi
  fi
done
[ "$checked" -gt 0 ] && ok "at least one multi-node scenario was checked ($checked)" || bad "no multi-node scenario was checked"
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
