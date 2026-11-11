#!/usr/bin/env bash
# Checks the recorded Codex lifecycle evidence (docs/evals/codex-2026-11-07 by default): the eight scenarios are all there, each from
# its own fresh session, with the controller's assertion output, exit codes, Git state and verifying checksums, and every verdict
# agrees with its own evidence (an infrastructure error is never counted as a skill failure or a pass; a verifier exit other than 0 or 1
# is one, FIX-041). It runs no agent.
# Usage: bash tests/trials/test-codex-evidence.sh [<evidence-dir>]
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
ev="${1:-$root/docs/evals/codex-2026-11-07}"
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }
sums() { (cd "$1" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c "$2"; else shasum -a 256 -c "$2"; fi) >/dev/null 2>&1; }

[ -d "$ev" ] || { echo "no evidence folder: $ev"; exit 1; }
scenarios="happy-path baseline-red interrupted-merge race-claim-conflict ts-lifecycle java-lifecycle multi-module ci-local"
ids=""; npass=0; nfail=0; ninfra=0; nunv=0
for s in $scenarios; do
  d="$ev/runs/$s"
  [ -d "$d" ] || { bad "$s: no evidence folder"; continue; }
  miss=""; for f in prompt.txt session-id.txt agent-exit.txt assert.log assert-exit.txt git-state.txt outcome.txt report.txt session.log SHA256SUMS; do
    if [ ! -e "$d/$f" ]; then miss="$miss $f"; elif [ ! -s "$d/$f" ] && [ "$f" != report.txt ]; then miss="$miss $f(empty)"; fi
  done
  [ -z "$miss" ] && ok "$s: prompt, session id, exit codes, assertion output, Git state, report and log are present" || { bad "$s: missing:$miss"; continue; }
  sums "$d" SHA256SUMS && ok "$s: the checksums verify" || bad "$s: checksum mismatch"
  sid="$(tr -d ' \r\n' < "$d/session-id.txt")"; ids="$ids $sid"
  out="$(tr -d ' \r\n' < "$d/outcome.txt")"; ae="$(tr -d ' \r\n' < "$d/agent-exit.txt")"; as="$(tr -d ' \r\n' < "$d/assert-exit.txt")"
  sig=no; bash "$here/infra-signature.sh" "$d/report.txt" "$d/session.log" >/dev/null 2>&1 && sig=yes
  case "$out" in
    PASS)        npass=$((npass + 1)); [ "$ae" = 0 ] && [ "$as" = 0 ] && ok "$s: PASS has agent exit 0 and assert exit 0" || bad "$s: PASS with agent exit $ae, assert exit $as" ;;
    FAIL)        nfail=$((nfail + 1)); [ "$ae" = 0 ] && [ "$as" != 0 ] && [ "$sig" = no ] && ok "$s: FAIL is an assertion failure with no environment signature" || bad "$s: FAIL with agent exit $ae, assert exit $as, environment signature: $sig" ;;
    INFRA_ERROR) ninfra=$((ninfra + 1)); { [ "$ae" != 0 ] || { [ "$as" != 0 ] && [ "$as" != 1 ]; } || { [ "$sig" = yes ] && [ -s "$d/infra-signature.txt" ]; }; } && ok "$s: INFRA_ERROR has a non-zero agent exit, a failed verifier (exit $as) or a recorded environment signature" || bad "$s: INFRA_ERROR without a reason" ;;
    UNVERIFIED)  nunv=$((nunv + 1)); ok "$s: UNVERIFIED (not counted as a pass)" ;;
    *)           bad "$s: unknown outcome '$out'" ;;
  esac
  grep -Eq '^(PASS|FAIL)  ' "$d/assert.log" && ok "$s: the controller's assert.sh output is recorded" || bad "$s: assert.log has no check lines"
done

# shellcheck disable=SC2086
n="$(printf '%s\n' $ids | grep -c .)"
# shellcheck disable=SC2086
u="$(printf '%s\n' $ids | grep . | sort -u | wc -l | tr -d ' ')"
[ "$n" = 8 ] && [ "$u" = 8 ] && ok "eight different session ids: every scenario ran in a fresh session" || bad "session ids: $n recorded, $u distinct"
[ -f "$ev/results.json" ] && python3 -I - "$ev/results.json" "$npass" "$nfail" "$ninfra" "$nunv" <<'PY' && ok "results.json agrees with the per-run outcomes" || bad "results.json disagrees with the per-run outcomes"
import json, sys
r = json.load(open(sys.argv[1]))["scenarios"]
want = dict(zip(("PASS", "FAIL", "INFRA_ERROR", "UNVERIFIED"), map(int, sys.argv[2:6])))
got = {k: sum(1 for x in r if x["outcome"] == k) for k in want}
sys.exit(0 if got == want and len(r) == 8 else 1)
PY
[ -s "$ev/summary.md" ] && ok "summary.md exists" || bad "summary.md missing"
[ -f "$ev/SHA256SUMS" ] && sums "$ev" SHA256SUMS && ok "the root checksums verify" || bad "root SHA256SUMS missing or failing"
printf 'INFO  %s PASS, %s FAIL, %s INFRA_ERROR, %s UNVERIFIED\n' "$npass" "$nfail" "$ninfra" "$nunv"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
