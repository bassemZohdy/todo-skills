#!/usr/bin/env bash
# TASK-149: run-claude.sh records Claude Code's stream-json session (every tool call and result) as session.jsonl in the evidence,
# checksummed, so that tdd-order.sh can score a Claude run; report.txt still holds the final answer. Uses a stub `claude`
# (no agent, no network): it records its arguments and prints a stream shaped like the real one.
# Usage: bash tests/trials/test-claude-session-log.sh    Works in a temporary directory that it removes at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TRIAL_WINDOWS_ISOLATION=0   # stub-only bookkeeping test: no sandbox needed on Windows hosts
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

cat > "$tmp/stream" <<'JSON'
{"type":"system","subtype":"init","cwd":"/work"}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"t1","name":"Bash","input":{"command":"python3 -m unittest tests.test_x"}}]}}
{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t1","content":"Exit code 1","is_error":true}]}}
{"type":"assistant","message":{"content":[{"type":"tool_use","id":"t2","name":"Edit","input":{"file_path":"/work/calc.py"}}]}}
{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"t2","content":"edited","is_error":false}]}}
{"type":"result","subtype":"success","result":"stub final report: red, then the edit","is_error":false}
JSON
mkdir -p "$tmp/bin"
cat > "$tmp/bin/claude" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$@" > "$STUB_ARGS"
case "${STUB_MODE:-stream}" in
  stream) cat "$STUB_STREAM" ;;
  plain)  echo "stub plain report: nothing changed" ;;
  empty)  : ;;
  unicode) sed 's/stub final report: red, then the edit/stub report with an arrow \xe2\x86\x92 and an emoji/' "$STUB_STREAM" ;;
  noresult) sed 's/"result":"stub final report: red, then the edit"/"result":""/' "$STUB_STREAM" ;;
esac
exit 0
STUB
chmod +x "$tmp/bin/claude"
export PATH="$tmp/bin:$PATH" STUB_ARGS="$tmp/args" STUB_STREAM="$tmp/stream"
runs="$tmp/runs"
sum() { (cd "$1" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c SHA256SUMS; else shasum -a 256 -c SHA256SUMS; fi) >/dev/null 2>&1; }
newest() { ls -1 "$runs/status-readonly/evidence" | tail -1; }

TRIAL_LABEL=one bash "$here/run-claude.sh" "$runs" status-readonly >"$tmp/o1" 2>&1; rc1=$?
e="$runs/status-readonly/evidence/$(newest)"
grep -qx -- '--output-format' "$tmp/args" && grep -qx -- 'stream-json' "$tmp/args" && grep -qx -- '--verbose' "$tmp/args" && ok "claude is called with --output-format stream-json --verbose" || bad "claude arguments: $(tr '\n' ' ' < "$tmp/args" | cut -c1-200)"
cmp -s "$tmp/stream" "$e/session.jsonl" && ok "the stream is kept unchanged as session.jsonl" || bad "session.jsonl missing or changed"
grep -q 'session\.jsonl' "$e/SHA256SUMS" && sum "$e" && ok "session.jsonl is in SHA256SUMS and the checksums verify" || bad "session.jsonl is not checksummed"
[ "$(cat "$e/report.txt" 2>/dev/null)" = "stub final report: red, then the edit" ] && ok "report.txt holds the final answer, not the stream" || bad "report.txt: $(head -c 120 "$e/report.txt" 2>/dev/null)"
cmp -s "$e/report.txt" "$e/agent.log" && ok "agent.log still holds the final answer" || bad "agent.log differs from report.txt"
[ "$rc1" = 0 ] && grep -q PASS "$e/outcome.txt" && ok "a run with a stream and a report is scored (PASS here), exit 0" || bad "rc=$rc1 outcome=$(cat "$e/outcome.txt" 2>/dev/null)"
bash "$here/tdd-order.sh" "$e/session.jsonl" 2>&1 | grep -q '^PASS' && ok "tdd-order.sh scores the recorded session: PASS (red run, then the edit)" || bad "tdd-order.sh on the recorded session: $(bash "$here/tdd-order.sh" "$e/session.jsonl" 2>&1 | head -1)"

sleep 1
STUB_MODE=empty TRIAL_LABEL=two bash "$here/run-claude.sh" "$runs" status-readonly >"$tmp/o2" 2>&1; rc2=$?
e2="$runs/status-readonly/evidence/$(newest)"
[ "$rc2" != 0 ] && grep -q INFRA_ERROR "$e2/outcome.txt" && grep -qi 'stream' "$e2/infra-signature.txt" && ok "an empty stream fails as INFRA_ERROR with a signature that names the stream, not as a skill failure" || bad "empty stream: rc=$rc2 outcome=$(cat "$e2/outcome.txt" 2>/dev/null) signature=$(cat "$e2/infra-signature.txt" 2>/dev/null)"

sleep 1
STUB_MODE=plain TRIAL_LABEL=three bash "$here/run-claude.sh" "$runs" status-readonly >"$tmp/o3" 2>&1
e3="$runs/status-readonly/evidence/$(newest)"
grep -q 'stub plain report' "$e3/report.txt" && ok "output that is not a stream (older claude, a stub) still becomes the report" || bad "plain output: $(head -c 100 "$e3/report.txt" 2>/dev/null)"

sleep 1
STUB_MODE=unicode TRIAL_LABEL=four bash "$here/run-claude.sh" "$runs" status-readonly >"$tmp/o4" 2>&1
e4="$runs/status-readonly/evidence/$(newest)"
grep -q 'stub report with an arrow' "$e4/report.txt" && grep -q "$(printf '\342\206\222')" "$e4/report.txt" && ok "a result with an arrow reaches report.txt whatever the console encoding" || bad "unicode report: $(head -c 120 "$e4/report.txt" 2>/dev/null)"

sleep 1
STUB_MODE=noresult TRIAL_LABEL=five bash "$here/run-claude.sh" "$runs" status-readonly >"$tmp/o5" 2>&1
e5="$runs/status-readonly/evidence/$(newest)"
[ ! -s "$e5/report.txt" ] && grep -q UNVERIFIED "$e5/outcome.txt" && ok "a stream whose final answer is empty gives an empty report.txt and UNVERIFIED" || bad "empty final answer: outcome=$(cat "$e5/outcome.txt" 2>/dev/null) report=$(head -c 40 "$e5/report.txt" 2>/dev/null)"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
