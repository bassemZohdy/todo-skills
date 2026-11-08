#!/usr/bin/env bash
set -eu
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/runs/evidence/session" "$tmp/runs/notes/repo" "$tmp/runs/happy-path" "$tmp/runs/baseline-red"
out="$(bash "$here/score.sh" "$tmp/runs")"
printf '%s\n' "$out" | grep -q '0/2 scenarios pass' || { printf 'FAIL  scenario total\n%s\n' "$out"; exit 1; }
printf '%s\n' "$out" | grep -q '^UNVERIFIED *happy-path' || { echo 'FAIL  empty scenario counted'; exit 1; }
printf '%s\n' "$out" | grep -q '^UNVERIFIED *baseline-red' || { echo 'FAIL  second scenario counted'; exit 1; }
if printf '%s\n' "$out" | grep -Eq '^[A-Z_]+ +(evidence|notes) '; then echo 'FAIL  metadata counted as scenario'; exit 1; fi
echo '4 passed, 0 failed'
