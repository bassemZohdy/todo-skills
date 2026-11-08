#!/usr/bin/env bash
# Controller for the multi-node Codex fixtures; each iteration starts codex exec anew.
# Usage: bash tests/trials/run-codex-multi.sh <runs-dir> <ts-lifecycle|java-lifecycle>
set -u
runs="${1:?runs directory}"; scenario="${2:?scenario}"
case "$scenario" in ts-lifecycle|java-lifecycle) ;; *) echo 'unsupported multi-node scenario' >&2; exit 2 ;; esac
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p "$runs/$scenario"
sd="$(cd "$runs/$scenario" && pwd)"; repo="$sd/repo"
token="$(date -u +%Y%m%dT%H%M%SZ)-$$"
controller="$sd/controller-$token"
mkdir "$controller" || exit 2
: > "$controller/sessions.txt"
fingerprint() {
  (git -C "$repo" status --porcelain=v1; git -C "$repo" diff; git -C "$repo" diff --cached; git -C "$repo" for-each-ref --format='%(refname) %(objectname)') | git hash-object --stdin
}
previous=""; outcome=UNVERIFIED
for i in 1 2 3 4 5 6 7 8; do
  label="multi-$token-$i"
  TRIAL_ONE_INVOCATION=1 TRIAL_LABEL="$label" bash "$here/run-codex.sh" "$runs" "$scenario" > "$controller/run-$i.log" 2>&1 || :
  ev="$(find "$sd/evidence" -mindepth 1 -maxdepth 1 -type d -name "*-$label" -print)"
  if [ -z "$ev" ] || [ ! -f "$ev/outcome.txt" ]; then outcome=INFRA_ERROR; break; fi
  printf '%s\n' "$ev" >> "$controller/evidence-paths.txt"
  result="$(tr -d '\r\n ' < "$ev/outcome.txt")"
  sid=""; [ ! -f "$ev/session-id.txt" ] || sid="$(tr -d '\r\n' < "$ev/session-id.txt")"
  if [ -z "$sid" ] || grep -Fxq "$sid" "$controller/sessions.txt"; then
    if [ "$result" = INFRA_ERROR ]; then outcome=INFRA_ERROR; else outcome=UNVERIFIED; fi
    break
  fi
  printf '%s\n' "$sid" >> "$controller/sessions.txt"
  case "$result" in
    PASS) if [ "$i" -ge 2 ]; then outcome=PASS; else outcome=UNVERIFIED; fi; break ;;
    # Keep the invocation's environment signature as the controller's recorded cause (FIX-053).
    INFRA_ERROR|UNVERIFIED) outcome="$result"; [ "$result" != INFRA_ERROR ] || [ ! -f "$ev/infra-signature.txt" ] || cp "$ev/infra-signature.txt" "$controller/infra-signature.txt"; break ;;
    FAIL) ;;
    *) outcome=UNVERIFIED; break ;;
  esac
  # Independently check required tool availability when a run cannot pass.
  # A missing executable is an infrastructure restriction, not a skill defect.
  required=node; [ "$scenario" != java-lifecycle ] || required=mvn
  if ! command -v "$required" >/dev/null 2>&1; then
    printf 'required executable unavailable: %s\n' "$required" > "$controller/infra-signature.txt"
    outcome=INFRA_ERROR; break
  fi
  if [ "$scenario" = java-lifecycle ] && sig="$(grep -m1 '^\[ERROR\] Could not create local repository at ' "$ev/session.log")"; then
    printf '%s\n' "$sig" > "$controller/infra-signature.txt"; outcome=INFRA_ERROR; break
  fi
  current="$(fingerprint)"
  if [ -n "$previous" ] && [ "$current" = "$previous" ]; then outcome=FAIL; break; fi
  previous="$current"
  outcome=FAIL
done
printf '%s\n' "$outcome" > "$controller/outcome.txt"
# Keep the per-invocation outcome intact, and attach the aggregate result to the
# final invocation so score.sh cannot turn an unverified sequence into a PASS.
if [ -n "${ev:-}" ] && [ -f "$ev/SHA256SUMS" ]; then
  printf '%s\n' "$outcome" > "$ev/multi-outcome.txt"
  (cd "$ev" && if command -v sha256sum >/dev/null 2>&1; then sha256sum multi-outcome.txt >> SHA256SUMS; else shasum -a 256 multi-outcome.txt >> SHA256SUMS; fi)
fi
(cd "$controller" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -- * > SHA256SUMS; else shasum -a 256 -- * > SHA256SUMS; fi)
echo "outcome: $outcome ($controller)"
[ "$outcome" = PASS ]
