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
# also fails when an arm in arms/ and a scenario in scenarios/ have no scored row (PASS or FAIL) between them, except for the
# scenarios listed in coverage-pending.txt next to this script (one scenario id per line, # starts a comment): a listed scenario
# that lacks rows is printed as PENDING and does not fail. It is never a silent pass: a listed scenario that every arm already
# covers fails (remove it from the list), and so does a listed id that is not a folder under scenarios/.
# A line with a slash, <arm>/<scenario>, names one cell instead of a scenario (TASK-139.3): the arm is a folder under arms/ or
# variants/, which is how the cells of a variant, outside arms/ and so never asked for by the scenario rule, are listed. A listed
# cell with fewer than 3 scored rows is printed as PENDING with its count and does not fail; with 3 or more it fails (remove it
# from the list), and so does a cell whose arm or scenario is not a folder. The count is over the whole published table, while
# setup_cost.py --pending and the setupcheck pin in tests/run.sh count only the rows since 2026-11-24 (the batch of TASK-139). So only a
# cell without older rows can be listed: todo-skills-existing/* and the 7-text-helpers cells. A short cell of todo-skills on 1-bugfix to
# 6-ambiguous also has rows of 2026-11-12 to 14, so this check counts it complete and fails a line that lists it.
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
    pending=""; [ -f "$here/coverage-pending.txt" ] && pending="$(tr -d '\r' < "$here/coverage-pending.txt" | sed 's/[[:space:]]*$//' | grep -v '^#' | grep -v '^$')"
    pcells="$(printf '%s\n' "$pending" | grep '/')"; pending="$(printf '%s\n' "$pending" | grep -v '/')"
    for s in "$here"/scenarios/*/; do
      s1="$(basename "$s")"; miss=""
      for a in "$here"/arms/*/; do
        a1="$(basename "$a")"
        rows "$pub" | awk -F, -v a="$a1" -v s="$s1" '$3 == a && $4 == s && ($10 == "PASS" || $10 == "FAIL") { f = 1 } END { exit !f }' || miss="$miss $a1"
      done
      if printf '%s\n' "$pending" | grep -Fxq "$s1"; then
        if [ -z "$miss" ]; then echo "FAIL  scenario $s1 is complete: remove it from coverage-pending.txt"; fail=1
        else echo "PENDING  scenario $s1: no scored row yet for $(printf '%s' "${miss# }" | sed 's/ /, /g')"; fi
      else
        for a1 in $miss; do echo "FAIL  no scored row for arm $a1 on scenario $s1"; fail=1; done
      fi
    done
    while IFS= read -r id; do
      [ -n "$id" ] && [ ! -d "$here/scenarios/$id" ] && { echo "FAIL  coverage-pending.txt lists $id, which is not a folder under scenarios/"; fail=1; }
    done < <(printf '%s\n' "$pending")
    while IFS= read -r cell; do
      [ -n "$cell" ] || continue
      carm="${cell%%/*}"; cscen="${cell#*/}"; cok=1
      [ -d "$here/arms/$carm" ] || [ -d "$here/variants/$carm" ] || { echo "FAIL  coverage-pending.txt lists the cell $cell, but $carm is not a folder under arms/ or variants/"; fail=1; cok=0; }
      [ -d "$here/scenarios/$cscen" ] || { echo "FAIL  coverage-pending.txt lists the cell $cell, but $cscen is not a folder under scenarios/"; fail=1; cok=0; }
      [ "$cok" -eq 1 ] || continue
      cn="$(rows "$pub" | awk -F, -v a="$carm" -v s="$cscen" '$3 == a && $4 == s && ($10 == "PASS" || $10 == "FAIL") { n++ } END { print n + 0 }')"
      if [ "$cn" -ge 3 ]; then echo "FAIL  cell $cell is complete ($cn scored rows): remove it from coverage-pending.txt"; fail=1
      else echo "PENDING  cell $cell: $cn of 3 scored rows"; fi
    done < <(printf '%s\n' "$pcells")
  fi
  [ "$fail" -eq 0 ] || exit 1
  echo "OK: $n published row(s), each with the published columns and an evidence hash"
  ;;
*) usage ;;
esac
