#!/usr/bin/env bash
# Checks that score.sh does not let a scenario pass without a recorded agent run, and keeps every scenario in the totals.
# Builds a small batch in a temporary directory (no agent needed):
#   baseline-red     untouched repo, no agent evidence      -> UNVERIFIED (its assertions pass by doing nothing)
#   status-readonly  untouched repo, agent exit 124      -> INFRA_ERROR
#   ci-local         agent exit 0 but outcome.txt says INFRA_ERROR -> INFRA_ERROR
#   release-ask      untouched repo, agent exit 0 + a report -> PASS
#   report           untouched repo, agent exit 0 + a report -> FAIL
#   happy-path       a scenario folder without any repo                   -> UNVERIFIED, still counted
# Usage: bash tests/trials/test-score-outcomes.sh
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TRIAL_WINDOWS_ISOLATION=0   # stub-only bookkeeping test: no sandbox needed on Windows hosts
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
mk baseline-red baseline-red
mk status-readonly status-readonly; ev status-readonly 20260101T000000Z-1 124
mk ci-local ci-local; ev ci-local 20260101T000000Z-1 0 INFRA_ERROR
mk release-ask release-ask; ev release-ask 20260101T000000Z-1 0
mk report report; ev report 20260101T000000Z-1 0
mkdir -p "$runs/happy-path"

out="$(bash "$here/score.sh" "$runs" 2>&1)"
line() { printf '%s\n' "$out" | grep -E "^[A-Z_]+ +$1( |$)"; }

line baseline-red | grep -q '^UNVERIFIED' && ok "no agent evidence: UNVERIFIED, not PASS" || bad "unverified scenario: $(line baseline-red)"
line status-readonly | grep -q '^INFRA_ERROR' && ok "agent exit 124: INFRA_ERROR" || bad "infra scenario: $(line status-readonly)"
line ci-local | grep -q '^INFRA_ERROR' && ok "outcome.txt INFRA_ERROR overrides a clean exit" || bad "blocked scenario: $(line ci-local)"
line release-ask | grep -q '^PASS' && ok "agent exit 0 with a report and passing assertions: PASS" || bad "passed scenario: $(line release-ask)"
line report | grep -q '^FAIL' && ok "failing assertions: FAIL" || bad "failed scenario: $(line report)"
line happy-path | grep -q '^UNVERIFIED' && ok "scenario folder without a repo is UNVERIFIED" || bad "missing scenario: $(line happy-path)"
printf '%s\n' "$out" | grep -q 'TRIAL SCORE 16.7% (1/6 scenarios pass)' && ok "every scenario stays in the totals (1/6)" || bad "totals line: $(printf '%s\n' "$out" | grep 'TRIAL SCORE')"
printf '%s\n' "$out" | grep -q 'UNVERIFIED 2' && printf '%s\n' "$out" | grep -q 'INFRA_ERROR 2' && ok "totals break out UNVERIFIED and INFRA_ERROR" || bad "breakdown missing: $(printf '%s\n' "$out" | tail -3)"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
