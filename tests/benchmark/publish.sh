#!/usr/bin/env bash
# Publishes real benchmark runs into docs/evals/benchmark/results/results.csv and checks what was published (TASK-075, TASK-121.2).
# Usage: bash publish.sh add <runs results.csv>     append every run of a table that run.sh wrote
#        bash publish.sh check [--coverage]          check the published table
# Only the results are published; the evidence of a run (prompts, session logs, Git state) stays on the machine that ran it.
# A published row is the run's own row without its last field, evidence_dir (a folder on that machine). Its evidence_sha256 is the
# hash run.sh recorded over the complete evidence of the run, so whoever holds that evidence can show that it is the one behind
# the row. Rows are copied by this script, never typed by hand.
# add refuses the whole table, and writes nothing, when a run has no recorded evidence hash (a 64-character SHA-256), when a run
# id is already published, or when the table's header is not the published header followed by evidence_dir.
# check fails when a row does not have the published columns, has no valid evidence hash or repeats a run id. With --coverage it
# also fails when an arm in arms/ and a scenario in scenarios/ have no scored row (PASS or FAIL) between them.
# Environment: BENCH_RESULTS, the published table (default: docs/evals/benchmark/results/results.csv).
# Needs bash and awk. Runs no agent and no command from the tables.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pub="${BENCH_RESULTS:-$here/../../docs/evals/benchmark/results/results.csv}"
usage() { echo "usage: bash publish.sh add <runs results.csv> | check [--coverage]" >&2; exit 2; }
[ -f "$pub" ] || { echo "no published table at $pub" >&2; exit 2; }
rows() { tr -d '\r' < "$1" | sed 1d | grep -v '^$'; }
valid_sha() { case "$1" in *[!0-9a-f]*|'') return 1 ;; esac; [ "${#1}" -eq 64 ]; }
pubhead="$(tr -d '\r' < "$pub" | sed -n 1p)"
ncols="$(printf '%s\n' "$pubhead" | awk -F, '{ print NF }')"
tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' EXIT

case "${1:-}" in
add)
  src="${2:-}"; [ -f "$src" ] || usage
  [ "$(tr -d '\r' < "$src" | sed -n 1p)" = "$pubhead,evidence_dir" ] || { echo "refused: the header of $src is not the published header followed by evidence_dir" >&2; exit 1; }
  : > "$tmpd/new"; n=0; bad=0
  while IFS= read -r row; do
    id="${row%%,*}"; rest="${row%,*}"; sha="${rest##*,}"
    if rows "$pub" | grep -q "^$id,"; then echo "refused: run $id is already published" >&2; bad=1; continue; fi
    if ! valid_sha "$sha"; then echo "refused: run $id has no recorded evidence hash" >&2; bad=1; continue; fi
    printf '%s\n' "$rest" >> "$tmpd/new"
    n=$((n + 1))
  done < <(rows "$src")
  [ "$bad" -eq 0 ] || { echo "nothing was published" >&2; exit 1; }
  [ "$n" -gt 0 ] || { echo "refused: $src has no run" >&2; exit 1; }
  cat "$tmpd/new" >> "$pub"
  echo "published $n run(s) into $pub"
  ;;
check)
  coverage=0; [ "${2:-}" = --coverage ] && coverage=1
  n=0; fail=0
  while IFS= read -r row; do
    id="${row%%,*}"; sha="${row##*,}"
    n=$((n + 1))
    if [ "$(printf '%s\n' "$row" | awk -F, '{ print NF }')" -ne "$ncols" ]; then echo "FAIL  run $id: the row does not have the $ncols published columns"; fail=1; continue; fi
    valid_sha "$sha" || { echo "FAIL  run $id: no valid evidence hash (a 64-character SHA-256 is required)"; fail=1; }
  done < <(rows "$pub")
  dups="$(rows "$pub" | cut -d, -f1 | sort | uniq -d | tr '\n' ' ')"
  [ -z "$dups" ] || { echo "FAIL  run id published twice: $dups"; fail=1; }
  if [ "$coverage" -eq 1 ]; then
    for a in "$here"/arms/*/; do for s in "$here"/scenarios/*/; do
      a1="$(basename "$a")"; s1="$(basename "$s")"
      rows "$pub" | awk -F, -v a="$a1" -v s="$s1" '$3 == a && $4 == s && ($10 == "PASS" || $10 == "FAIL") { f = 1 } END { exit !f }' \
        || { echo "FAIL  no scored row for arm $a1 on scenario $s1"; fail=1; }
    done; done
  fi
  [ "$fail" -eq 0 ] || exit 1
  echo "OK: $n published row(s), each with the published columns and an evidence hash"
  ;;
*) usage ;;
esac
