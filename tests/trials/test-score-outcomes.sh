#!/usr/bin/env bash
# Checks that score.sh does not let a scenario pass without a recorded agent run, and keeps every scenario in the totals.
# Builds a small batch in a temporary directory (no agent needed):
#   unverified  baseline-red, untouched repo, no agent evidence      -> UNVERIFIED (its assertions pass by doing nothing)
#   infra       status-readonly, untouched repo, agent exit 124      -> INFRA_ERROR
#   blocked     status-readonly, agent exit 0 but outcome.txt says INFRA_ERROR -> INFRA_ERROR
#   passed      status-readonly, untouched repo, agent exit 0 + a report -> PASS
#   missing     a scenario folder without any repo                   -> UNVERIFIED, still counted
# Usage: bash tests/trials/test-score-outcomes.sh
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

runs="$tmp/runs"; mkdir -p "$runs"
mk() { # mk <folder> <scenario>
  mkdir -p "$runs/$1"; bash "$here/setup.sh" "$runs/$1/repo" "$2" >/dev/null 2>&1 || { bad "setup $2"; return 1; }
}
ev() { # ev <folder> <id> <agent-exit> [outcome]
  local d="$runs/$1/evidence/$2"; mkdir -p "$d"
  printf '%s\n' "$3" > "$d/agent-exit.txt"; printf 'Report: nothing to do.\n' > "$d/report.txt"
  [ -z "${4:-}" ] || printf '%s\n' "$4" > "$d/outcome.txt"
}
mk unverified baseline-red
mk infra status-readonly;   ev infra 20260101T000000Z-1 124
mk blocked status-readonly; ev blocked 20260101T000000Z-1 0 INFRA_ERROR
mk passed status-readonly;  ev passed 20260101T000000Z-1 0
mkdir -p "$runs/missing"

out="$(bash "$here/score.sh" "$runs" 2>&1)"
line() { printf '%s\n' "$out" | grep -E "^[A-Z_]+ +$1( |$)"; }

line unverified | grep -q '^UNVERIFIED' && ok "no agent evidence: UNVERIFIED, not PASS" || bad "unverified scenario: $(line unverified)"
line infra | grep -q '^INFRA_ERROR' && ok "agent exit 124: INFRA_ERROR" || bad "infra scenario: $(line infra)"
line blocked | grep -q '^INFRA_ERROR' && ok "outcome.txt INFRA_ERROR overrides a clean exit" || bad "blocked scenario: $(line blocked)"
line passed | grep -q '^PASS' && ok "agent exit 0 with a report and passing assertions: PASS" || bad "passed scenario: $(line passed)"
line missing | grep -q '^UNVERIFIED' && ok "scenario folder without a repo is UNVERIFIED" || bad "missing scenario: $(line missing)"
printf '%s\n' "$out" | grep -q 'TRIAL SCORE 20.0% (1/5 scenarios pass)' && ok "every scenario stays in the totals (1/5)" || bad "totals line: $(printf '%s\n' "$out" | grep 'TRIAL SCORE')"
printf '%s\n' "$out" | grep -q 'UNVERIFIED 2' && printf '%s\n' "$out" | grep -q 'INFRA_ERROR 2' && ok "totals break out UNVERIFIED and INFRA_ERROR" || bad "breakdown missing: $(printf '%s\n' "$out" | tail -3)"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
