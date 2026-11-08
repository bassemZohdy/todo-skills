#!/usr/bin/env bash
# FEAT-055: self-test of the agent benchmark in docs/evals/benchmark with a stub agent; no real agent runs.
# Checks, for every scenario and arm: a correct solution is PASS, doing nothing is FAIL, and each run writes hashed evidence
# and one CSV row. Then: editing the visible tests cannot pass a scenario (the hidden tests decide), editing the hidden tests
# or verifier is INFRA_ERROR, a failing or missing agent is INFRA_ERROR, a silent agent is UNVERIFIED, the first attempt is
# kept apart from a retry, token usage is read from the CLI's own output or reported "unavailable", and summarize.sh reports
# median, mean and spread.
# Usage: bash tests/trials/test-benchmark-harness.sh
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
bench="$root/docs/evals/benchmark"
sol="$here/benchmark-solutions"
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }
[ -f "$bench/run.sh" ] || { echo "FAIL  no benchmark runner at $bench/run.sh"; exit 1; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
# A private copy of the hidden tests, so the tamper case below cannot touch the repository's copy.
cp -R "$bench/hidden" "$tmp/hidden"
export BENCH_HIDDEN="$tmp/hidden" BENCH_MODEL=stub-model
# The stub agent: STUB_MODE=solve copies the reference solution and commits it, noop does nothing, cheat rewrites the visible
# tests to pass trivially, tamper edits the hidden tests, crash exits 3, silent writes nothing, second solves only on its second
# call in a repository, usage prints Codex-style usage events.
cat > "$tmp/stub.sh" <<'STUB'
#!/usr/bin/env bash
if [ "${1:-}" = --version ]; then echo "stub-agent 1.0"; exit 0; fi
repo="$1"; prompt="$2"; report="$3"
scen="$(sed -n 's/^Scenario: //p' "$prompt" | head -1)"
mode="${STUB_MODE:-solve}"
if [ "$mode" = second ]; then
  n=0; [ ! -f "$repo/.stub-calls" ] || n="$(cat "$repo/.stub-calls")"; n=$((n + 1)); echo "$n" > "$repo/.stub-calls"
  [ "$n" -ge 2 ] && mode=solve || mode=noop
fi
case "$mode" in
  solve)
    if [ -d "$STUB_SOLUTIONS/$scen" ]; then cp -R "$STUB_SOLUTIONS/$scen/." "$repo/"; fi
    git -C "$repo" add -A -- . ':!.stub-calls' >/dev/null 2>&1
    git -C "$repo" -c user.name=stub -c user.email=stub@example.invalid commit -qm "feat: stub solution" >/dev/null 2>&1
    if [ -f "$STUB_SOLUTIONS/$scen.report" ]; then cp "$STUB_SOLUTIONS/$scen.report" "$report"; else echo "done" > "$report"; fi ;;
  noop) echo "nothing done" > "$report" ;;
  cheat) for f in "$repo"/tests/test_*.py; do printf 'import unittest\nclass T(unittest.TestCase):\n    def test_ok(self): pass\n' > "$f"; done
    printf 'import unittest\nclass T(unittest.TestCase):\n    def test_ok(self): pass\n' > "$repo/test_accept.py"; echo "tests pass" > "$report" ;;
  tamper) for f in "$BENCH_HIDDEN"/*/test_accept.py; do printf 'import unittest\nunittest.main()\n' > "$f"; done; echo "done" > "$report" ;;
  crash) echo "agent crashed" >&2; exit 3 ;;
  silent) exit 0 ;;
  usage) echo '{"type":"turn.completed","usage":{"input_tokens":1200,"cached_input_tokens":800,"output_tokens":90}}'
    echo '{"type":"turn.completed","usage":{"input_tokens":300,"cached_input_tokens":100,"output_tokens":10}}'; echo "nothing done" > "$report" ;;
esac
echo "stub $mode on $scen"
STUB
chmod +x "$tmp/stub.sh"
export BENCH_AGENT="$tmp/stub.sh" STUB_SOLUTIONS="$sol"
csv="$tmp/runs/results.csv"
outcome() { python3 - "$csv" "$1" <<'PY'
import csv, sys
rows = list(csv.DictReader(open(sys.argv[1], encoding='utf-8')))
print(rows[-1][sys.argv[2]])
PY
}
run() { bash "$bench/run.sh" "$@" > "$tmp/last.log" 2>&1; }

scenarios="$(cd "$bench/scenarios" && ls -d */ | tr -d / | tr '\n' ' ')"
[ "$(echo $scenarios | wc -w | tr -d ' ')" = 6 ] && ok "six scenarios: $scenarios" || bad "expected six scenarios, found: $scenarios"
arms="$(cd "$bench/arms" && ls -d */ | tr -d / | tr '\n' ' ')"
for a in todo-skills lean-baseline no-methodology; do case " $arms " in *" $a "*) ;; *) bad "arm $a is missing";; esac; done

rows=0
for a in $arms; do
  for s in $scenarios; do
    STUB_MODE=solve run "$bench/arms/$a" "$s" "$tmp/runs"; rows=$((rows + 1))
    got="$(outcome final_outcome)"
    [ "$got" = PASS ] && ok "$a/$s: a correct solution is PASS" || { bad "$a/$s: a correct solution is $got"; tail -15 "$tmp/last.log"; }
  done
done
for s in $scenarios; do
  STUB_MODE=noop run "$bench/arms/no-methodology" "$s" "$tmp/runs"; rows=$((rows + 1))
  got="$(outcome final_outcome)"
  [ "$got" = FAIL ] && ok "$s: doing nothing is FAIL" || bad "$s: doing nothing is $got"
done
n="$(($(wc -l < "$csv") - 1))"
[ "$n" = "$rows" ] && ok "one CSV row per run ($n)" || bad "CSV has $n rows for $rows runs"

# Every run's evidence verifies against its own SHA256SUMS, and the CSV names that file's hash.
badsums=0
while IFS= read -r rel; do
  d="$tmp/runs/${rel%$'\r'}"   # Python on Windows ends piped lines with CRLF
  (cd "$d" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c --quiet SHA256SUMS; else shasum -a 256 -c --quiet SHA256SUMS; fi) >/dev/null 2>&1 || badsums=$((badsums + 1))
done < <(python3 - "$csv" <<'PY'
import csv, sys, os
for r in csv.DictReader(open(sys.argv[1], encoding='utf-8')): print(r['evidence_dir'])
PY
)
[ "$badsums" = 0 ] && ok "every run's evidence verifies against its SHA256SUMS" || bad "$badsums runs fail their SHA256SUMS"
rel="$(outcome evidence_dir)"; want="$(outcome evidence_sha256)"
got="$( { sha256sum "$tmp/runs/$rel/SHA256SUMS" 2>/dev/null || shasum -a 256 "$tmp/runs/$rel/SHA256SUMS"; } | cut -d' ' -f1)"
[ "$got" = "$want" ] && ok "the CSV row carries the SHA-256 of the run's SHA256SUMS" || bad "CSV evidence hash does not match"
last="$tmp/runs/$(outcome evidence_dir)"
miss=""; for f in versions.txt hidden.sha256 start-sha.txt outcome.txt first-outcome.txt attempt-1/prompt.txt attempt-1/session.log attempt-1/report.txt attempt-1/agent-exit.txt attempt-1/diff.patch attempt-1/usage.txt attempt-1/verifier.log attempt-1/verifier-exit.txt attempt-1/duration.txt; do [ -e "$last/$f" ] || miss="$miss $f"; done
[ -z "$miss" ] && ok "a run records versions, the hidden-test manifest, prompt, session, report, exit codes, diff, usage and timing" || bad "missing evidence:$miss"
grep -q 'stub-agent 1.0' "$last/versions.txt" && grep -q 'stub-model' "$last/versions.txt" && grep -qi 'python' "$last/versions.txt" && grep -q 'git version' "$last/versions.txt" \
  && ok "versions.txt names the agent CLI, model and toolchain" || bad "versions.txt incomplete: $(cat "$last/versions.txt")"
[ -d "$last/repo" ] && [ ! -e "$last/repo/test_accept.py" ] && ! grep -rq 'class Accept' "$last/repo" 2>/dev/null \
  && ok "the hidden acceptance tests never enter the agent's repository" || bad "hidden tests found in the agent's repository"

STUB_MODE=cheat run "$bench/arms/no-methodology" 1-bugfix "$tmp/runs"
got="$(outcome final_outcome)"; [ "$got" = FAIL ] && ok "rewriting the visible tests to pass trivially is still FAIL" || bad "a test-rewriting agent got $got"
cp -R "$tmp/hidden" "$tmp/hidden-clean"
STUB_MODE=tamper run "$bench/arms/no-methodology" 1-bugfix "$tmp/runs"
got="$(outcome final_outcome)"; [ "$got" = INFRA_ERROR ] && grep -q 'hidden tests or verifier changed' "$tmp/last.log" \
  && ok "an agent that edits the hidden tests gets INFRA_ERROR, never PASS" || bad "a hidden-test tamper got $got"
rm -rf "$tmp/hidden"; mv "$tmp/hidden-clean" "$tmp/hidden"
STUB_MODE=crash run "$bench/arms/no-methodology" 1-bugfix "$tmp/runs"
got="$(outcome final_outcome)"; [ "$got" = INFRA_ERROR ] && [ "$(outcome agent_exit)" = 3 ] && ok "a failing agent CLI is INFRA_ERROR with its exit code" || bad "a crashed agent got $got"
BENCH_AGENT="$tmp/no-such-agent" run "$bench/arms/no-methodology" 1-bugfix "$tmp/runs"; rc=$?
[ "$rc" = 2 ] && grep -q INFRA_ERROR "$tmp/last.log" && ok "a missing agent CLI is INFRA_ERROR and starts nothing" || bad "missing agent: rc $rc"
STUB_MODE=silent run "$bench/arms/no-methodology" 1-bugfix "$tmp/runs"
got="$(outcome final_outcome)"; [ "$got" = UNVERIFIED ] && ok "an agent with no report and no output is UNVERIFIED" || bad "a silent agent got $got"
STUB_MODE=second BENCH_ATTEMPTS=2 run "$bench/arms/no-methodology" 2-api-feature "$tmp/runs"
[ "$(outcome first_outcome)" = FAIL ] && [ "$(outcome final_outcome)" = PASS ] && [ "$(outcome attempts)" = 2 ] \
  && ok "the first attempt (FAIL) is kept apart from the retry (PASS)" || bad "attempts: first $(outcome first_outcome), final $(outcome final_outcome), $(outcome attempts)"
STUB_MODE=usage run "$bench/arms/no-methodology" 1-bugfix "$tmp/runs"
[ "$(outcome input_tokens)" = 1500 ] && [ "$(outcome cached_tokens)" = 900 ] && [ "$(outcome output_tokens)" = 100 ] && [ "$(outcome llm_calls)" = 2 ] \
  && ok "token usage and turns are read from the CLI's own usage events" || bad "usage: $(outcome input_tokens) $(outcome cached_tokens) $(outcome output_tokens) $(outcome llm_calls)"
STUB_MODE=noop run "$bench/arms/no-methodology" 1-bugfix "$tmp/runs"
[ "$(outcome input_tokens)" = unavailable ] && [ "$(outcome subagent_calls)" = unavailable ] && ok "usage the CLI does not report is 'unavailable', never estimated" || bad "usage without events: $(outcome input_tokens)"
[ "$(outcome isolation)" = provisional ] && ok "runs are labelled provisional unless isolation is asserted" || bad "isolation: $(outcome isolation)"
bash "$bench/summarize.sh" "$csv" > "$tmp/summary.txt" 2>&1
grep -q 'median' "$tmp/summary.txt" && grep -q 'mean' "$tmp/summary.txt" && grep -q 'spread' "$tmp/summary.txt" && grep -q 'no-methodology' "$tmp/summary.txt" \
  && ok "summarize.sh reports median, mean and spread per arm and scenario" || bad "summarize.sh: $(head -5 "$tmp/summary.txt")"
[ "$(wc -l < "$bench/results/results.csv" | tr -d ' ')" = 1 ] && ok "the published results file holds only its header (no simulated rows)" || bad "results/results.csv has rows that no recorded run produced"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
