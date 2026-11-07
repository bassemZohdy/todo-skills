#!/usr/bin/env bash
# Checks that the baseline-red trial needs the agent's report: an unchanged repository alone must not pass.
# No agent: it feeds assert.sh hand-written reports (TRIAL_REPORT) for an untouched baseline-red repository.
# Usage: bash tests/trials/test-baseline-red-report.sh    Works in a temporary directory that it removes at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

bash "$here/setup.sh" "$tmp/repo" baseline-red >/dev/null 2>&1 || { echo "setup failed"; exit 1; }
verdict() { TRIAL_REPORT="${1:-}" bash "$here/assert.sh" "$tmp/repo" baseline-red >/dev/null 2>&1 && echo accepted || echo rejected; }

printf 'Done.\n' > "$tmp/silent.txt"
: > "$tmp/empty.txt"
printf 'The task FEAT-001 was reviewed. Everything looks fine.\n' > "$tmp/wrong.txt"
printf 'Baseline red: python3 -m unittest discover -s tests fails (test_add).\n' > "$tmp/nofix.txt"
printf 'Report: baseline red. `python3 -m unittest discover -s tests` fails: tests.test_calc.CalcTest.test_add (-1 != 3).\nNext: /todo-add "fix the failing baseline: tests.test_calc.CalcTest.test_add" --type fix --priority P0\n' > "$tmp/good.txt"

[ "$(verdict)" = rejected ] && ok "no report at all: rejected although the repository is unchanged" || bad "missing report accepted"
[ "$(verdict "$tmp/does-not-exist.txt")" = rejected ] && ok "report file missing: rejected" || bad "nonexistent report accepted"
[ "$(verdict "$tmp/empty.txt")" = rejected ] && ok "empty report: rejected" || bad "empty report accepted"
[ "$(verdict "$tmp/silent.txt")" = rejected ] && ok "silent report ('Done.'): rejected" || bad "silent report accepted"
[ "$(verdict "$tmp/wrong.txt")" = rejected ] && ok "report that does not mention the red baseline: rejected" || bad "wrong report accepted"
[ "$(verdict "$tmp/nofix.txt")" = rejected ] && ok "report without a fix suggestion: rejected" || bad "report without a fix accepted"
[ "$(verdict "$tmp/good.txt")" = accepted ] && ok "report naming the red baseline, the failing test and a FIX: accepted" || bad "good report rejected"
git -C "$tmp/repo" -c user.email=t@t -c user.name=t commit -q --allow-empty -m "chore: the agent changed something"
[ "$(verdict "$tmp/good.txt")" = rejected ] && ok "good report but the repository changed: rejected" || bad "changed repository accepted"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
