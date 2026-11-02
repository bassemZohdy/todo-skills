#!/usr/bin/env bash
# Scores a batch of finished trials. Read-only.
# Layout: <runs-dir>/<scenario>/<repo>/ as made by `setup.sh <runs-dir>/<scenario>/<repo> <scenario>`.
# A scenario passes only when every one of its checks passes; the trial score is the share of passing scenarios.
# The check rate (all checks over all scenarios) is printed too, but it flatters: an agent that does nothing
# still passes the generic checks, so use the scenario rate.
# TRIAL_SKIP=<regex> leaves out checks whose name matches, for steps the trial environment itself refuses
# (for example a sandbox that denies writes under .git/hooks). Skips are printed; never use it to hide a skill bug.
# Usage: [TRIAL_SKIP=regex] bash tests/trials/score.sh <runs-dir>
set -u
runs="${1:?usage: score.sh <runs-dir>}"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skip="${TRIAL_SKIP:-}"
n=0; ok=0; P=0; T=0
for d in "$runs"/*/; do
  s="$(basename "$d")"
  repo="$(find "$d" -mindepth 1 -maxdepth 1 -type d ! -name '*.todo' | head -1)"
  [ -n "$repo" ] || continue
  out="$(bash "$here/assert.sh" "$repo" "$s" 2>&1 | grep -E '^(PASS|FAIL)  ')"
  if [ -n "$skip" ]; then
    printf '%s\n' "$out" | grep -E "^(PASS|FAIL)  .*($skip)" | sed "s/^/    SKIP /"
    out="$(printf '%s\n' "$out" | grep -Ev "^(PASS|FAIL)  .*($skip)")"
  fi
  p="$(printf '%s\n' "$out" | grep -c '^PASS')"; f="$(printf '%s\n' "$out" | grep -c '^FAIL')"
  [ $((p + f)) -gt 0 ] || continue
  n=$((n + 1)); P=$((P + p)); T=$((T + p + f))
  if [ "$f" = 0 ]; then ok=$((ok + 1)); v=PASS; else v=FAIL; fi
  printf '%-4s %-22s %d/%d checks\n' "$v" "$s" "$p" $((p + f))
  printf '%s\n' "$out" | grep '^FAIL' | sed 's/^FAIL  /       - /'
done
[ "$n" -gt 0 ] || { echo "no trials found in $runs"; exit 1; }
awk -v ok="$ok" -v n="$n" -v p="$P" -v t="$T" 'BEGIN {
  printf "\nTRIAL SCORE %.1f%% (%d/%d scenarios pass); check rate %.1f%% (%d/%d)\n", 100*ok/n, ok, n, 100*p/t, p, t }'
