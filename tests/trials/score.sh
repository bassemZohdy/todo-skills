#!/usr/bin/env bash
# Scores a batch of finished trials. Read-only.
# Layout: <runs-dir>/<scenario>/repo/ as made by `setup.sh <runs-dir>/<scenario>/repo <scenario>`, and the agent's
# evidence in <runs-dir>/<scenario>/evidence/<id>/ as written by run-claude.sh (the newest <id> counts). Older batches with
# agent.log directly in the scenario folder are still read.
# Only names listed by setup.sh are scenario folders; each is counted even if incomplete.
#   PASS         the agent ran (exit 0, a report) and every check in assert.sh passes
#   FAIL         the agent ran and at least one check fails
#   INFRA_ERROR  the agent exited non-zero (for example 124, a timeout), or evidence/<id>/outcome.txt says INFRA_ERROR
#                (written by whoever saw a permission denial or sandbox block)
#   UNVERIFIED   there is no repo, or no record that an agent ran. A repo that satisfies the checks without an agent run
#                (the read-only scenarios do) is never a PASS
# The trial score is PASS over all scenarios. The check rate is printed too, but it flatters.
# TRIAL_SKIP=<regex> leaves out checks whose name matches, for steps the trial environment itself refuses
# (for example a sandbox that denies writes under .git/hooks). Skips are printed; never use it to hide a skill bug.
# Usage: [TRIAL_SKIP=regex] bash tests/trials/score.sh <runs-dir>
set -u
runs="${1:?usage: score.sh <runs-dir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skip="${TRIAL_SKIP:-}"
# Use the setup script's scenario list, also used by selftest.sh, as the source
# of truth so batch evidence and unrelated metadata never become scenarios.
scenarios="$(sed -n '/^# Scenarios:/,/^# Needs /p' "$here/setup.sh" | sed '$d; s/^# Scenarios: //; s/^# *//; s/|/ /g')"
n=0; ok=0; P=0; T=0; nfail=0; ninfra=0; nunv=0
for d in "$runs"/*/; do
  [ -d "$d" ] || continue
  s="$(basename "$d")"; known=no
  for scenario in $scenarios; do [ "$scenario" != "$s" ] || known=yes; done
  [ "$known" = yes ] || continue
  n=$((n + 1))
  repo=""
  if [ -d "$d/repo" ]; then repo="$d/repo"
  else repo="$(find "$d" -mindepth 1 -maxdepth 1 -type d ! -name '*.todo' ! -name evidence | head -1)"; fi
  if [ -z "$repo" ]; then
    printf '%-11s %-22s no repo in the scenario folder\n' UNVERIFIED "$s"; nunv=$((nunv + 1)); continue
  fi
  # the agent's record: newest evidence folder, else the old agent.log
  evd=""; [ -d "$d/evidence" ] && evd="$(ls -1 "$d/evidence" 2>/dev/null | sort | tail -1)"
  code=""; outcome=""; report=""; multi=""
  if [ -n "$evd" ]; then
    e="$d/evidence/$evd"
    [ -f "$e/agent-exit.txt" ] && code="$(tr -d ' \r\n' < "$e/agent-exit.txt")"
    [ -f "$e/outcome.txt" ] && outcome="$(tr -d ' \r\n' < "$e/outcome.txt")"
    [ -f "$e/multi-outcome.txt" ] && multi="$(tr -d ' \r\n' < "$e/multi-outcome.txt")"
    # A controller interrupted between invocations has no final verdict yet.
    if [ -z "$multi" ] && [ -f "$e/prompt.txt" ] && grep -Fq 'The controller will run it again in a fresh session' "$e/prompt.txt"; then multi=UNVERIFIED; fi
    [ -s "$e/report.txt" ] && report=yes
    export TRIAL_REPORT="$e/report.txt"
  elif [ -f "$d/agent.log" ]; then
    code="$(sed -n 's/^agent exit: *//p' "$d/agent.log" | tail -1 | tr -d ' \r')"
    [ -n "$(grep -v '^agent exit:' "$d/agent.log" | tr -d ' \r\n')" ] && report=yes
    export TRIAL_REPORT="$d/agent.log"
  else
    unset TRIAL_REPORT
  fi
  if [ -z "$code" ]; then
    printf '%-11s %-22s no record that an agent ran\n' UNVERIFIED "$s"; nunv=$((nunv + 1)); continue
  fi
  if [ "$outcome" = INFRA_ERROR ] || [ "$code" != 0 ]; then
    printf '%-11s %-22s agent exit %s%s\n' INFRA_ERROR "$s" "$code" "$([ "$outcome" = INFRA_ERROR ] && echo ', marked INFRA_ERROR')"; ninfra=$((ninfra + 1)); continue
  fi
  if [ "$multi" = INFRA_ERROR ]; then
    printf '%-11s %-22s multi-session controller reported infrastructure failure\n' INFRA_ERROR "$s"; ninfra=$((ninfra + 1)); continue
  elif [ -n "$multi" ] && [ "$multi" != PASS ] && [ "$multi" != FAIL ]; then
    printf '%-11s %-22s multi-session result: %s\n' UNVERIFIED "$s" "$multi"; nunv=$((nunv + 1)); continue
  fi
  if [ -z "$report" ]; then
    printf '%-11s %-22s agent exit 0 but no report\n' UNVERIFIED "$s"; nunv=$((nunv + 1)); continue
  fi
  out="$(bash "$here/assert-exec.sh" "$repo" "$s" 2>&1 | grep -E '^(PASS|FAIL)  ')"
  if [ -n "$skip" ]; then
    printf '%s\n' "$out" | grep -E "^(PASS|FAIL)  .*($skip)" | sed "s/^/    SKIP /"
    out="$(printf '%s\n' "$out" | grep -Ev "^(PASS|FAIL)  .*($skip)")"
  fi
  p="$(printf '%s\n' "$out" | grep -c '^PASS')"; f="$(printf '%s\n' "$out" | grep -c '^FAIL')"
  P=$((P + p)); T=$((T + p + f))
  if [ $((p + f)) -eq 0 ]; then
    printf '%-11s %-22s no checks ran\n' UNVERIFIED "$s"; nunv=$((nunv + 1)); continue
  fi
  if [ "$f" = 0 ] && [ "$multi" != FAIL ]; then ok=$((ok + 1)); v=PASS; else nfail=$((nfail + 1)); v=FAIL; fi
  printf '%-11s %-22s %d/%d checks\n' "$v" "$s" "$p" $((p + f))
  printf '%s\n' "$out" | grep '^FAIL' | sed 's/^FAIL  /       - /'
done
[ "$n" -gt 0 ] || { echo "no trials found in $runs"; exit 1; }
awk -v ok="$ok" -v n="$n" -v p="$P" -v t="$T" -v f="$nfail" -v i="$ninfra" -v u="$nunv" 'BEGIN {
  rate = (t > 0) ? 100*p/t : 0
  printf "\nTRIAL SCORE %.1f%% (%d/%d scenarios pass); check rate %.1f%% (%d/%d)\n", 100*ok/n, ok, n, rate, p, t
  printf "PASS %d FAIL %d INFRA_ERROR %d UNVERIFIED %d\n", ok, f, i, u }'
