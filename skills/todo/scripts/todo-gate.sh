#!/usr/bin/env bash
# todo-gate.sh - runs a node's Done when commands and its regression command, and fails when a run executed no tests.
# Usage: bash todo-gate.sh <ID> [--regression "<cmd>"] [--baseline <n>] [--todo TODO.md]     (run from the repository root)
# Done when commands are the backticked commands on the node's "Done when:" line; "regression: `cmd`" on that line is the
# regression command, otherwise --regression is used. Without either, only Done when is run and a note says so.
# Output: one "GATE <step>: PASS|FAIL ..." line per command. Exit 0 all gates pass, 1 a gate failed, 2 usage or node not found.
# It executes the commands written in TODO.md, so lint (I10) should have passed first.
id=""; reg=""; base=""; todo="TODO.md"
while [ $# -gt 0 ]; do
  case "$1" in
    --regression) reg="$2"; shift 2 ;;
    --baseline) base="$2"; shift 2 ;;
    --todo) todo="$2"; shift 2 ;;
    *) id="$1"; shift ;;
  esac
done
[ -n "$id" ] && [ -f "$todo" ] || { echo "usage: todo-gate.sh <ID> [--regression cmd] [--baseline n] [--todo file]"; exit 2; }

line="$(awk -v id="$id" '
  index($0, "**" id "**") && /^ *- \[/ { on = 1; next }
  on && /^ *- \[/ { exit }
  on && /Done when:/ { print; exit }' "$todo")"
[ -n "$line" ] || { echo "GATE: no Done when found for $id"; exit 2; }

count_of() { # prints the number of tests that ran, or empty when unknown
  local o="$1" n
  n="$(printf '%s\n' "$o" | sed -nE 's/^Ran ([0-9]+) tests? in .*/\1/p' | tail -1)"
  [ -z "$n" ] && n="$(printf '%s\n' "$o" | sed -nE 's/.* ([0-9]+) passed.*/\1/p' | tail -1)"
  [ -z "$n" ] && n="$(printf '%s\n' "$o" | sed -nE 's/^Tests:.* ([0-9]+) passed.*/\1/p' | tail -1)"
  [ -z "$n" ] && n="$(printf '%s\n' "$o" | sed -nE 's/^ok .*|^test result: ok\. ([0-9]+) passed.*/\1/p' | tail -1)"
  printf '%s' "$n"
}
zero_tests() { printf '%s\n' "$1" | grep -Eiq 'Ran 0 tests|no tests (found|ran)|collected 0 items|0 passing|Tests: +0 |running 0 tests|NO TESTS RAN'; }
run_one() { # step name, command
  local step="$1" cmd="$2" out rc n
  out="$(bash -c "$cmd" 2>&1)"; rc=$?
  n="$(count_of "$out")"
  if [ "$rc" -ne 0 ]; then echo "GATE $step: FAIL exit $rc: $cmd"; printf '%s\n' "$out" | tail -5; return 1; fi
  if zero_tests "$out"; then echo "GATE $step: FAIL ran no tests: $cmd"; return 1; fi
  echo "GATE $step: PASS${n:+ ($n tests)}: $cmd"
  LAST_COUNT="$n"; return 0
}

regline="$(printf '%s\n' "$line" | grep -oE 'regression: *`[^`]+`' | sed -E 's/^regression: *`//; s/`$//')"
[ -z "$reg" ] && reg="$regline"
dw="$(printf '%s\n' "$line" | sed -E 's/regression: *`[^`]+`//' | grep -oE '`[^`]+`' | sed -E 's/^`//; s/`$//')"
rc=0; LAST_COUNT=""
while IFS= read -r c; do [ -n "$c" ] && { run_one "done-when" "$c" || rc=1; }; done <<< "$dw"
if [ -n "$reg" ]; then
  run_one "regression" "$reg" || rc=1
  if [ "$rc" -eq 0 ] && [ -n "$base" ] && [ -n "$LAST_COUNT" ] && [ "$LAST_COUNT" -lt "$base" ]; then
    echo "GATE regression: FAIL $LAST_COUNT tests is fewer than the baseline $base"; rc=1
  fi
else
  echo "GATE regression: SKIPPED no regression command (add regression: on the Done when line or pass --regression)"
fi
exit "$rc"
