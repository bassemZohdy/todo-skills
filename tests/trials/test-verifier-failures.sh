#!/usr/bin/env bash
# FIX-041: a verifier that fails or is killed is an infrastructure error, never a pass or a skill failure, and every runner
# checks through assert-exec.sh (the dispatcher that picks the isolated verifier). No agent, no network, no sandbox:
# the harness is copied to a temporary folder and assert-exec.sh, claude and codex-exec.sh are replaced by stubs.
# Usage: bash tests/trials/test-verifier-failures.sh
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

# setup.sh copies the skills from ../../plugin, so the copy keeps the repository layout.
ctl="$tmp/controller/tests/trials"; mkdir -p "$ctl" "$tmp/bin"
cp "$here"/*.sh "$ctl/"; cp -r "$here/../../plugin" "$tmp/controller/"
# The fake verifier prints a passing check, then exits as told: partial output from a killed verifier must not count.
cat > "$ctl/assert-exec.sh" <<'FAKE'
#!/usr/bin/env bash
echo 'PASS  fake check before the verifier stopped'
exit "${FAKE_ASSERT_EXIT:-0}"
FAKE
cat > "$ctl/codex-exec.sh" <<'FAKE'
#!/usr/bin/env bash
printf 'session id: fake-%s\n' "$RANDOM$RANDOM"; printf 'stub report\n' > "$3"; exit 0
FAKE
cat > "$tmp/bin/claude" <<'FAKE'
#!/usr/bin/env bash
echo 'stub report: nothing changed'
FAKE
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"

score_case() { # score_case <assert exit> <expected verdict>
  local runs="$tmp/score-$1"; mkdir -p "$runs/release-ask/evidence/20260101T000000Z-1"
  bash "$ctl/setup.sh" "$runs/release-ask/repo" release-ask >/dev/null 2>&1 || { bad "setup release-ask"; return; }
  printf '0\n' > "$runs/release-ask/evidence/20260101T000000Z-1/agent-exit.txt"
  printf 'stub report\n' > "$runs/release-ask/evidence/20260101T000000Z-1/report.txt"
  local line; line="$(FAKE_ASSERT_EXIT="$1" bash "$ctl/score.sh" "$runs" 2>&1 | grep -E '^[A-Z_]+ +release-ask( |$)')"
  case "$line" in "$2"*) ok "score.sh: verifier exit $1 -> $2" ;; *) bad "score.sh: verifier exit $1 expected $2, got: $line" ;; esac
}
score_case 0 PASS
score_case 1 FAIL
score_case 2 INFRA_ERROR
score_case 124 INFRA_ERROR

run_case() { # run_case <runner> <assert exit> <expected outcome>
  local runs="$tmp/$1-$2"
  FAKE_ASSERT_EXIT="$2" bash "$ctl/$1" "$runs" status-readonly >/dev/null 2>&1
  local got; got="$(cat "$runs"/status-readonly/evidence/*/outcome.txt 2>/dev/null)"
  [ "$got" = "$3" ] && ok "$1: verifier exit $2 -> $3" || bad "$1: verifier exit $2 expected $3, got '${got:-none}'"
}
run_case run-claude.sh 0 PASS
run_case run-claude.sh 124 INFRA_ERROR
run_case run-codex.sh 0 PASS
run_case run-codex.sh 2 INFRA_ERROR

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
