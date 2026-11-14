#!/usr/bin/env bash
# Trusted verifier (FEAT-055). Scores a finished run on a COPY of the agent's repository with the scenario's hidden
# accept.sh, so nothing the agent left in its tree (edited tests, a fake test_accept.py) can change the verdict.
# Usage: bash verify.sh <hidden-dir> <scenario-id> <repo> <report-file> <start-sha>
# Exit: 0 PASS, 1 FAIL, 2 or more INFRA_ERROR (python3 missing, timeout, a broken copy).
# BENCH_VERIFY_WRAP, when set, is a command prefix that runs accept.sh inside a sandbox (for example a container), since
# accept.sh runs code the agent wrote. Without it the verifier runs that code on this host: use a disposable machine.
set -u
hidden="$1"; scen="$2"; repo="$3"; report="$4"; start="$5"
work="$(mktemp -d)" || exit 2
trap 'rm -rf "$work"' EXIT
mkdir "$work/repo" && cp -R "$repo/." "$work/repo/" || { echo "INFRA: cannot copy the repository"; exit 2; }
cp "$report" "$work/report.txt" 2>/dev/null || : > "$work/report.txt"
tmo=(); command -v timeout >/dev/null 2>&1 && tmo=(timeout 600)
# shellcheck disable=SC2086
${BENCH_VERIFY_WRAP:-} ${tmo[@]+"${tmo[@]}"} bash "$hidden/$scen/accept.sh" "$work/repo" "$work/report.txt" "$start" "$hidden/$scen"
rc=$?
case "$rc" in 0|1) exit "$rc" ;; *) echo "INFRA: accept.sh exited $rc"; exit 2 ;; esac
