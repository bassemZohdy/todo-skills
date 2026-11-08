#!/usr/bin/env bash
# Summarizes a benchmark results.csv per arm and scenario (FEAT-055): runs, PASS on the first attempt and at the end, and
# median, mean and spread (min-max) of duration and of each token count over the runs that report it. Descriptive only:
# with a handful of runs per cell no difference is significant, and this prints no test of significance.
# Usage: bash summarize.sh <results.csv>
set -u
csv="${1:?usage: summarize.sh <results.csv>}"
awk -F, '
function stats(list,   n, a, i, j, t, s, med) {
  n = split(list, a, " "); if (n == 0) return "unavailable"
  for (i = 2; i <= n; i++) { t = a[i] + 0; j = i - 1; while (j > 0 && a[j] + 0 > t) { a[j + 1] = a[j]; j-- } a[j + 1] = t }
  s = 0; for (i = 1; i <= n; i++) s += a[i]
  med = (n % 2) ? a[(n + 1) / 2] : (a[n / 2] + a[n / 2 + 1]) / 2
  return sprintf("median %g, mean %.1f, spread %g-%g (n=%d)", med, s / n, a[1], a[n], n)
}
NR == 1 { for (i = 1; i <= NF; i++) col[$i] = i; next }
{ k = $col["arm"] " / " $col["scenario"]; if (!(k in runs)) order[++nk] = k; runs[k]++
  if ($col["first_outcome"] == "PASS") first[k]++; if ($col["final_outcome"] == "PASS") final[k]++
  out[k] = out[k] " " $col["final_outcome"]; dur[k] = dur[k] " " $col["duration_s"]
  split("input_tokens output_tokens cached_tokens llm_calls", ks, " ")
  for (m = 1; m <= 4; m++) { v = $col[ks[m]]; if (v ~ /^[0-9]+$/) tok[k, m] = tok[k, m] " " v } }
END {
  if (nk == 0) { print "no runs recorded"; exit 0 }
  for (i = 1; i <= nk; i++) { k = order[i]
    printf "%s: %d runs, PASS %d first attempt, %d final; outcomes:%s\n", k, runs[k], first[k], final[k], out[k]
    printf "  duration_s: %s\n", stats(dur[k])
    for (m = 1; m <= 4; m++) printf "  %s: %s\n", ks[m], stats(tok[k, m]) }
  print "Descriptive only: no significance claims from small samples."
}' "$csv"
