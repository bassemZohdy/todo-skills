#!/usr/bin/env bash
# Tests the trial harness itself (no agent needed): every scenario must set up, and an agent that does
# nothing must FAIL every scenario except the read-only ones, where doing nothing is the right answer.
# This keeps assert.sh from drifting into checks that pass by default.
# Usage: bash tests/trials/selftest.sh    Works in a temporary directory that it removes at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly_ok=" release-ask status-readonly "   # baseline-red also needs a report that names the red baseline (assert.sh, TRIAL_REPORT)
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
scenarios="$(sed -n 's/^# Scenarios: //p; s/^#   //p' "$here/setup.sh" | tr '|' '\n' | tr -d ' ' | grep .)"
for s in $scenarios; do
  mkdir -p "$tmp/$s"
  if ! bash "$here/setup.sh" "$tmp/$s/repo" "$s" >/dev/null 2>&1; then fail=$((fail+1)); echo "FAIL  $s: setup failed"; continue; fi
  bash "$here/prompt.sh" "$tmp/$s/repo" "$s" >/dev/null 2>&1 || { fail=$((fail+1)); echo "FAIL  $s: no prompt"; continue; }
  if bash "$here/assert.sh" "$tmp/$s/repo" "$s" >/dev/null 2>&1; then got=pass; else got=fail; fi
  case "$readonly_ok" in *" $s "*) want=pass ;; *) want=fail ;; esac
  if [ "$got" = "$want" ]; then pass=$((pass+1)); echo "PASS  $s: untouched setup gives $want, as expected"
  else fail=$((fail+1)); echo "FAIL  $s: untouched setup gives $got, expected $want"; fi
done
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
