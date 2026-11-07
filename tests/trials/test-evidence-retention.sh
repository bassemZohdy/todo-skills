#!/usr/bin/env bash
# Checks that repeated run-claude.sh invocations keep separate, checksummed evidence. Uses a stub `claude` (no agent, no network).
# Usage: bash tests/trials/test-evidence-retention.sh    Works in a temporary directory that it removes at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

mkdir -p "$tmp/bin"
cat > "$tmp/bin/claude" <<'STUB'
#!/usr/bin/env bash
echo "stub report for call $RANDOM$RANDOM: nothing changed"
exit "${STUB_EXIT:-0}"
STUB
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH"
runs="$tmp/runs"
sum() { (cd "$1" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c SHA256SUMS; else shasum -a 256 -c SHA256SUMS; fi) >/dev/null 2>&1; }

TRIAL_LABEL=first  bash "$here/run-claude.sh" "$runs" status-readonly >"$tmp/o1" 2>&1; rc1=$?
first="$(ls -1 "$runs/status-readonly/evidence" | head -1)"
before="$(cat "$runs/status-readonly/evidence/$first/agent.log" "$runs/status-readonly/evidence/$first/prompt.txt" | cksum)"
sleep 1
TRIAL_LABEL=second STUB_EXIT=124 bash "$here/run-claude.sh" "$runs" status-readonly >"$tmp/o2" 2>&1; rc2=$?
n="$(ls -1 "$runs/status-readonly/evidence" | wc -l | tr -d ' ')"
[ "$n" = 2 ] && ok "two invocations leave two evidence folders" || bad "expected 2 evidence folders, found $n"
after="$(cat "$runs/status-readonly/evidence/$first/agent.log" "$runs/status-readonly/evidence/$first/prompt.txt" | cksum)"
[ "$before" = "$after" ] && ok "the first invocation's prompt and log are untouched by the second" || bad "first invocation's evidence changed"
[ "$rc1" = 0 ] && grep -q PASS "$runs/status-readonly/evidence/$first/outcome.txt" && ok "first invocation: outcome PASS, exit 0" || bad "first invocation: rc=$rc1 outcome=$(cat "$runs/status-readonly/evidence/$first/outcome.txt")"
second="$(ls -1 "$runs/status-readonly/evidence" | tail -1)"
[ "$rc2" != 0 ] && grep -q INFRA_ERROR "$runs/status-readonly/evidence/$second/outcome.txt" && ok "second invocation: agent exit 124 is INFRA_ERROR" || bad "second invocation: rc=$rc2 outcome=$(cat "$runs/status-readonly/evidence/$second/outcome.txt")"
[ "$(cat "$runs/status-readonly/evidence/$second/agent-exit.txt")" = 124 ] && ok "the exit code is kept per invocation" || bad "agent-exit.txt of the second invocation"
for e in "$runs"/status-readonly/evidence/*/; do
  [ -s "$e/prompt.txt" ] && [ -s "$e/agent.log" ] && [ -s "$e/command.txt" ] && [ -s "$e/assert.log" ] && sum "$e" || { bad "evidence folder incomplete or checksums fail: $e"; continue; }
done
ok "every evidence folder has prompt, command, log, assert output and verifying SHA256SUMS"
grep -q 'reused the existing repo' "$runs/status-readonly/evidence/$second/setup.log" && ok "the second invocation reused the repo and says so" || bad "second setup.log"
[ "$(ls -1 "$runs/status-readonly/evidence" | sort -u | wc -l | tr -d ' ')" = 2 ] && ok "evidence folder names are unique" || bad "duplicate evidence folder names"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
