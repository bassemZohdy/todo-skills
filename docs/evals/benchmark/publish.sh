#!/usr/bin/env bash
# Publishes real benchmark runs into results/results.csv and checks what was published (TASK-075).
# Usage: bash publish.sh add <runs results.csv> <evidence root>     append every run of a table that run.sh wrote
#        bash publish.sh check [--coverage]                          verify every published row against its evidence
# A published row is the run's own row with two fields replaced, never typed by hand:
#   evidence_dir     the folder that holds the run's published evidence: <evidence root>/<the run's evidence_dir>. Give the
#                    root relative to the folder of the published table (for example ../../pi-glm-2026-11-12/benchmark/cells),
#                    so the published evidence can be a redacted subset that lives with its batch and is not copied here.
#   evidence_sha256  the SHA-256 of that folder's listing: one "<sha256>  <path>" line per file, sorted by path. The hash
#                    run.sh recorded covers the complete, unredacted run; it is kept in results/sources.csv with the table
#                    the row came from.
# add refuses the whole table, and writes nothing, when a run has no evidence folder or no file in it, when a run id is
# already published, or when the table's header differs from the published one.
# check fails when a row's evidence folder is missing, empty or no longer matches its hash. With --coverage it also fails
# when an arm in arms/ and a scenario in scenarios/ have no scored row (PASS or FAIL) between them.
# Environment: BENCH_RESULTS, the published table (default: results/results.csv next to this script).
# Needs bash, awk, find, sort, and sha256sum or shasum. Runs no agent and no command from the tables.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
pub="${BENCH_RESULTS:-$here/results/results.csv}"
usage() { echo "usage: bash publish.sh add <runs results.csv> <evidence root> | check [--coverage]" >&2; exit 2; }
[ -f "$pub" ] || { echo "no published table at $pub" >&2; exit 2; }
pubdir="$(cd "$(dirname "$pub")" && pwd)"
if command -v sha256sum >/dev/null 2>&1; then shacmd=(sha256sum); else shacmd=(shasum -a 256); fi
sha() { "${shacmd[@]}" "$@"; }
rows() { tr -d '\r' < "$1" | sed 1d | grep -v '^$'; }
# listing_sha <folder>: prints the hash of the folder's listing, or nothing when the folder is missing or holds no file.
listing_sha() {
  [ -d "$1" ] || return 0
  # One hashing process per folder (a process per file is slow on Windows); the lines are normalized to
  # "<sha256>  <path>" whatever the tool prints (a "*" binary marker, a leading "./", a "\" before an escaped name).
  ( cd "$1" && find . -type f -print0 | LC_ALL=C sort -z | xargs -0 "${shacmd[@]}" 2>/dev/null \
      | sed -e 's/^\\//' -e 's/^\([0-9a-f]*\) [ *]\.\//\1  /' ) > "$tmpd/listing"
  [ -s "$tmpd/listing" ] || return 0
  h="$(sha "$tmpd/listing")"; printf '%s\n' "${h%% *}"
}
tmpd="$(mktemp -d)"; trap 'rm -rf "$tmpd"' EXIT

case "${1:-}" in
add)
  src="${2:-}"; root="${3:-}"; [ -f "$src" ] && [ -n "$root" ] || usage
  root="${root%/}"
  [ "$(tr -d '\r' < "$src" | sed -n 1p)" = "$(tr -d '\r' < "$pub" | sed -n 1p)" ] || { echo "refused: the header of $src differs from the published table" >&2; exit 1; }
  : > "$tmpd/new"; : > "$tmpd/sources"; n=0; bad=0
  while IFS= read -r row; do
    id="${row%%,*}"; evdir="${row##*,}"; rest="${row%,*}"; oldsha="${rest##*,}"; lead="${rest%,*}"
    if rows "$pub" | grep -q "^$id,"; then echo "refused: run $id is already published" >&2; bad=1; continue; fi
    h="$(listing_sha "$pubdir/$root/$evdir")"
    if [ -z "$h" ]; then echo "refused: run $id has no evidence in $root/$evdir" >&2; bad=1; continue; fi
    printf '%s,%s,%s\n' "$lead" "$h" "$root/$evdir" >> "$tmpd/new"
    printf '%s,%s,%s\n' "$id" "$oldsha" "$src" >> "$tmpd/sources"
    n=$((n + 1))
  done < <(rows "$src")
  [ "$bad" -eq 0 ] || { echo "nothing was published" >&2; exit 1; }
  [ "$n" -gt 0 ] || { echo "refused: $src has no run" >&2; exit 1; }
  cat "$tmpd/new" >> "$pub"
  [ -s "$pubdir/sources.csv" ] || printf 'run_id,source_evidence_sha256,source_table\n' > "$pubdir/sources.csv"
  cat "$tmpd/sources" >> "$pubdir/sources.csv"
  echo "published $n run(s) into $pub"
  ;;
check)
  coverage=0; [ "${2:-}" = --coverage ] && coverage=1
  n=0; fail=0
  while IFS= read -r row; do
    id="${row%%,*}"; evdir="${row##*,}"; rest="${row%,*}"; want="${rest##*,}"
    n=$((n + 1))
    if [ ! -d "$pubdir/$evdir" ]; then echo "FAIL  run $id: evidence folder $evdir is missing"; fail=1; continue; fi
    h="$(listing_sha "$pubdir/$evdir")"
    if [ -z "$h" ]; then echo "FAIL  run $id: evidence folder $evdir is missing its files"; fail=1
    elif [ "$h" != "$want" ]; then echo "FAIL  run $id: evidence in $evdir changed since it was published"; fail=1; fi
  done < <(rows "$pub")
  if [ "$coverage" -eq 1 ]; then
    for a in "$here"/arms/*/; do for s in "$here"/scenarios/*/; do
      a1="$(basename "$a")"; s1="$(basename "$s")"
      rows "$pub" | awk -F, -v a="$a1" -v s="$s1" '$3 == a && $4 == s && ($10 == "PASS" || $10 == "FAIL") { f = 1 } END { exit !f }' \
        || { echo "FAIL  no scored row for arm $a1 on scenario $s1"; fail=1; }
    done; done
  fi
  [ "$fail" -eq 0 ] || exit 1
  echo "OK: $n published row(s), the evidence of every row verifies"
  ;;
*) usage ;;
esac
