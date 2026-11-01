#!/usr/bin/env bash
# Runs todo-lint.sh and todo-stop-hook.sh against the static fixtures in tests/fixtures.
# A fixture named ok-*.md must pass. A fixture named I<n>-*.md must fail with "FAIL I<n>:". W<n>-*.md (W1-W3) must pass with "WARN W<n>:".
# ok-*.md fixtures must also print no WARN line.
# Usage: bash tests/run.sh      Needs bash, awk, grep and sed. Creates no files.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lint="$root/skills/todo/scripts/todo-lint.sh"
hook="$root/skills/todo/scripts/todo-stop-hook.sh"
fx="$root/tests/fixtures"
changelog="$fx/changelog/CHANGELOG.md"
pass=0
fail=0

ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

for f in "$fx"/*.md; do
  name="$(basename "$f" .md)"
  expect="${name%%-*}"
  out="$(bash "$lint" "$f" "$changelog" 2>&1)"
  rc=$?
  if [ "$expect" = "W1" ] || [ "$expect" = "W2" ] || [ "$expect" = "W3" ]; then
    if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q "WARN $expect:"; then ok "$name"; else bad "$name: expected WARN $expect with rc=0, got rc=$rc: $out"; fi
  elif [ "$expect" = "ok" ]; then
    if [ "$rc" -eq 0 ]; then if printf '%s\n' "$out" | grep -q "^WARN"; then bad "$name: unexpected warning: $out"; else ok "$name"; fi; else bad "$name: expected OK, got: $out"; fi
  else
    if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q "FAIL $expect:"; then ok "$name"; else bad "$name: expected FAIL $expect, got rc=$rc: $out"; fi
  fi
done

# The plugin version equals the newest released CHANGELOG version.
pv="$(sed -nE 's/.*"version" *: *"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' "$root/.claude-plugin/plugin.json" | head -1)"
cv="$(sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' "$root/CHANGELOG.md" | head -1)"
if [ -n "$pv" ] && { [ -z "$cv" ] || [ "$pv" = "$cv" ]; }; then ok "plugin version $pv matches the changelog (${cv:-no release yet})"; else bad "plugin.json version '$pv' does not match newest CHANGELOG version '$cv'"; fi

# The repository's own backlog must follow its own rules.
out="$(cd "$root" && bash "$lint" TODO.md CHANGELOG.md 2>&1)"
if [ $? -eq 0 ]; then ok "this repository's TODO.md and CHANGELOG.md lint clean"; else bad "repo backlog: $out"; fi

# Stop hook: valid backlog allows the stop (no output).
out="$(printf '{"stop_hook_active": false}' | TODO_FILE="$fx/ok-valid.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook allows stop on a valid backlog"; else bad "hook printed output on a valid backlog: $out"; fi

# Stop hook: invalid backlog blocks.
out="$(printf '{"stop_hook_active": false}' | TODO_FILE="$fx/I1-two-active.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if printf '%s' "$out" | grep -q '"decision":"block"'; then ok "hook blocks on an invalid backlog"; else bad "hook did not block: $out"; fi

# Stop hook: never blocks twice in a row (loop guard).
out="$(printf '{"stop_hook_active": true}' | TODO_FILE="$fx/I1-two-active.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook honours stop_hook_active"; else bad "hook ignored stop_hook_active: $out"; fi

# Stop hook: no TODO.md means nothing to enforce.
out="$(printf '{}' | TODO_FILE="$fx/does-not-exist.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook is silent without a TODO.md"; else bad "hook printed output without TODO.md: $out"; fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
