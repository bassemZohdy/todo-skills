#!/usr/bin/env bash
# todo-gate.sh - runs a node's Done when commands and its regression command, and fails when a run executed no tests.
# Usage: bash todo-gate.sh <ID> [--regression "<cmd>"] [--baseline <n>] [--todo TODO.md]     (run from the repository root)
# Done when commands are the backticked commands on the node's "Done when:" line; "regression: `cmd`" on that line is the
# regression command, otherwise --regression is used. Without either, only Done when is run and a note says so.
# Output: one "GATE <step>: PASS|FAIL ..." line per command. Exit 0 all gates pass, 1 a gate failed, 2 usage or node not found, 3 Done when passed but no regression was run.
# It executes the commands written in TODO.md (and --regression) after the same forbidden-command check as lint I10.
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

line="$(tr -d '\r' < "$todo" | awk -v id="$id" '
  index($0, "**" id "**") && /^ *- \[/ { on = 1; next }
  on && /^ *- \[/ { exit }
  on && /Done when:/ { print; exit }')"
[ -n "$line" ] || { echo "GATE: no Done when found for $id"; exit 2; }

count_of() { # prints the number of tests that passed/ran, or empty when unknown
  local o="$1" n
  n="$(printf '%s\n' "$o" | sed -nE 's/^Ran ([0-9]+) tests? in .*/\1/p' | tail -1)"                                  # unittest
  [ -z "$n" ] && n="$(printf '%s\n' "$o" | sed -nE 's/.*(^|[^0-9])([0-9]+) passed.*/\2/p' | tail -1)"            # pytest, jest
  [ -z "$n" ] && n="$(printf '%s\n' "$o" | sed -nE 's/^ *([0-9]+) passing.*/\1/p' | tail -1)"                    # mocha
  [ -z "$n" ] && n="$(printf '%s\n' "$o" | sed -nE 's/^Tests run: ([0-9]+),.*/\1/p' | tail -1)"                 # maven (last summary line)
  if [ -z "$n" ] && printf '%s\n' "$o" | grep -q '^test result: '; then                                          # cargo: sum over targets
    n="$(printf '%s\n' "$o" | sed -nE 's/^test result: [a-z]+\. ([0-9]+) passed.*/\1/p' | awk '{s += $1} END {print s + 0}')"
  fi
  printf '%s' "$n"
}
zero_tests() { printf '%s\n' "$1" | grep -Eiq 'Ran 0 tests|no tests (found|ran)|collected 0 items|(^|[^0-9])0 passing|Tests: +0 |NO TESTS RAN'; }
forbidden() { printf '%s\n' "$1" | grep -Eq '(^|[^A-Za-z])sudo([^A-Za-z]|$)|(^|[ ;&|])rm +-[A-Za-z]*[rRfF]|(curl|wget)[^|]*[|] *(sh|bash)|git +(-C +[^ ]+ +)?(push|reset +--hard|clean)|chmod +-R|mkfs|dd +if=|-delete( |$)|(npm|yarn|pnpm|cargo|twine|gem) +(publish|push)|[.]ssh/|id_rsa|[.]aws/credentials'; }
run_one() { # step name, command
  local step="$1" cmd="$2" out rc n
  if forbidden "$cmd"; then echo "GATE $step: FAIL forbidden command, not run: $cmd"; return 1; fi
  out="$(bash -c "$cmd" 2>&1)"; rc=$?
  n="$(count_of "$out")"
  if [ "$rc" -ne 0 ]; then echo "GATE $step: FAIL exit $rc: $cmd"; printf '%s\n' "$out" | tail -5; return 1; fi
  if zero_tests "$out" || [ "$n" = "0" ]; then echo "GATE $step: FAIL ran no tests: $cmd"; return 1; fi
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
  if [ "$rc" -eq 0 ] && [ -n "$base" ]; then
    if [ -z "$LAST_COUNT" ]; then echo "GATE regression: NOTE test count not recognised, baseline $base not compared; compare the counts by hand"
    elif [ "$LAST_COUNT" -lt "$base" ]; then echo "GATE regression: FAIL $LAST_COUNT tests is fewer than the baseline $base"; rc=1; fi
  fi
else
  echo "GATE regression: SKIPPED no regression command (add regression: on the Done when line or pass --regression)"
  [ "$rc" -eq 0 ] && rc=3
fi
exit "$rc"
