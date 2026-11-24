#!/usr/bin/env bash
# FEAT-055: self-test of the agent benchmark in tests/benchmark with a stub agent; no real agent runs.
# Checks, for every scenario and arm: a correct solution is PASS, doing nothing is FAIL, and each run writes hashed evidence
# and one CSV row. Then: editing the visible tests cannot pass a scenario (the hidden tests decide), editing the hidden tests
# or verifier is INFRA_ERROR, a failing or missing agent is INFRA_ERROR, a silent agent is UNVERIFIED, the first attempt is
# kept apart from a retry, token usage is read from the CLI's own output or reported "unavailable", and summarize.sh reports
# median, mean and spread. The variant todo-skills-existing (TASK-139.1) runs through run.sh with the stub: its start commit holds
# the scenario's files, the skills and exactly what todo-init writes (TODO.md and CHANGELOG.md equal to the blocks of the todo-init
# skill, one README Tests line, nothing else), the lint passes, the coverage check asks for no rows of it outside arms/, and a variant
# that leaves extra files, a second Tests line or no Lanes section, or whose setup fails, is caught.
# Usage: bash tests/trials/test-benchmark-harness.sh
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
bench="$root/tests/benchmark"
pubdir="$root/docs/evals/benchmark"
sol="$here/benchmark-solutions"
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }
# TASK-121.1: the harness is test code and lives in tests/benchmark; docs/evals/benchmark keeps only the published results.
if [ "$(ls "$pubdir" 2>/dev/null | tr '
' ' ')" = "results " ]; then ok "docs/evals/benchmark holds only results/"; else bad "docs/evals/benchmark holds: $(ls "$pubdir" 2>/dev/null | tr '
' ' ')"; fi
old='docs/evals/benchmark/(arms|scenarios|hidden|agents|run\.sh|publish\.sh|summarize\.sh|usage\.sh|verify\.sh|README\.md)'
if git -C "$root" rev-parse --git-dir >/dev/null 2>&1; then
  stale="$(git -C "$root" grep -lE "$old" -- . ':!CHANGELOG.md' ':!TODO.md' 2>/dev/null | tr '
' ' ')"
  if [ -z "$stale" ]; then ok "no tracked file names the old harness path"; else bad "the old harness path is still named in: $stale"; fi
fi
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

# shellcheck disable=SC2035
scenarios="$(cd "$bench/scenarios" && ls -d */ | tr -d / | tr '\n' ' ')"
[ "$(echo "$scenarios" | wc -w | tr -d ' ')" = 6 ] && ok "six scenarios: $scenarios" || bad "expected six scenarios, found: $scenarios"
# shellcheck disable=SC2035
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
# TASK-075, TASK-121.2: published real runs (publish.sh). The evidence of a run stays where it ran, so the published table is
# checked on its own: every row has the published columns and a recorded evidence hash (the identity of that evidence), the
# repository's table scores every arm and scenario, and add refuses a run published before or one without a recorded hash.
pubsh="$bench/publish.sh"; pub="$tmp/pub/results.csv"
if bash "$pubsh" check --coverage > "$tmp/pub-repo.txt" 2>&1; then ok "published results: every arm and scenario has a scored row and every row is well formed"
else bad "published results (TASK-075): $(tail -3 "$tmp/pub-repo.txt" | tr '\n' ' ')"; fi
if [ "$(ls "$pubdir/results" | tr '\n' ' ')" = "results.csv " ]; then ok "the published results folder holds results.csv only"; else bad "the published results folder holds: $(ls "$pubdir/results" | tr '\n' ' ')"; fi
if head -1 "$pubdir/results/results.csv" | grep -q 'evidence_dir'; then bad "the published table still has an evidence_dir column"; else ok "the published table has no evidence_dir column"; fi
mkdir -p "$tmp/pub"; head -1 "$pubdir/results/results.csv" > "$pub"
nsrc="$(($(wc -l < "$csv") - 1))"
if BENCH_RESULTS="$pub" bash "$pubsh" add "$csv" > "$tmp/pub-add.txt" 2>&1 && [ "$(($(wc -l < "$pub") - 1))" = "$nsrc" ] \
   && BENCH_RESULTS="$pub" bash "$pubsh" check > "$tmp/pub-check.txt" 2>&1; then ok "publish.sh add copies every run of a table without an evidence folder and check passes"
else bad "publish.sh add or check: $(tail -2 "$tmp/pub-add.txt" "$tmp/pub-check.txt" 2>/dev/null | tr '\n' ' ')"; fi
oneid="$(sed -n 2p "$pub" | cut -d, -f1)"
cp "$pub" "$tmp/pub-good.csv"
sed '2s/,[^,]*$/,/' "$pub" > "$pub.new" && mv "$pub.new" "$pub"
out="$(BENCH_RESULTS="$pub" bash "$pubsh" check 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q "$oneid.*evidence hash" && ok "a row without an evidence hash fails the check" || bad "a row without a hash passed the check: rc=$rc $out"
cp "$tmp/pub-good.csv" "$pub"
sed '2s/,[^,]*$/,not-a-hash/' "$pub" > "$pub.new" && mv "$pub.new" "$pub"
out="$(BENCH_RESULTS="$pub" bash "$pubsh" check 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q "$oneid.*evidence hash" && ok "a row whose evidence hash is not a SHA-256 fails the check" || bad "a malformed hash passed the check: rc=$rc $out"
cp "$tmp/pub-good.csv" "$pub"
sed '2s/^\([^,]*\),/\1,extra,/' "$pub" > "$pub.new" && mv "$pub.new" "$pub"
out="$(BENCH_RESULTS="$pub" bash "$pubsh" check 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q "$oneid.*columns" && ok "a row with the wrong number of columns fails the check" || bad "a wrong column count passed the check: rc=$rc $out"
cp "$tmp/pub-good.csv" "$pub"
before="$(wc -l < "$pub")"
BENCH_RESULTS="$pub" bash "$pubsh" add "$csv" > "$tmp/pub-dup.txt" 2>&1; rc=$?
[ "$rc" -ne 0 ] && grep -q "refused: run .* is already published" "$tmp/pub-dup.txt" && [ "$(wc -l < "$pub")" = "$before" ] && ok "a run that is already published is refused and nothing is written" || bad "duplicate publish: rc=$rc $(cat "$tmp/pub-dup.txt")"
{ head -1 "$csv"; sed -n 2p "$csv" | sed 's/^[^,]*,/no-such-run,/; s/,[^,]*,[^,]*$/,,x/'; } > "$tmp/ghost.csv"
BENCH_RESULTS="$pub" bash "$pubsh" add "$tmp/ghost.csv" > "$tmp/pub-ghost.txt" 2>&1; rc=$?
[ "$rc" -ne 0 ] && grep -q "refused: run no-such-run has no recorded evidence hash" "$tmp/pub-ghost.txt" && [ "$(wc -l < "$pub")" = "$before" ] && ok "a run without a recorded evidence hash is refused and nothing is written" || bad "ghost publish: rc=$rc $(cat "$tmp/pub-ghost.txt")"

# TASK-139.1: the variant todo-skills-existing (outside arms/, like todo-skills-flow) is the todo-skills arm in a project whose backlog
# is set up: its start commit holds what /todo-init leaves and nothing else, so the agent starts at todo-add. existing_problems runs a
# variant with the stub agent through run.sh and prints what is wrong with the run, its row and its start commit, nothing when all is right.
ex="$bench/variants/todo-skills-existing"
pubsum() { cksum < "$pubdir/results/results.csv"; }
pub_before="$(pubsum)"
# The fenced block of the todo-init step that creates the file $1 (TODO.md, CHANGELOG.md), without its indentation.
init_block() { awk -v n="$1" '$0 ~ "^   - `" n "`:" { f = 1; next } f && /```markdown/ { g = 1; next } f && g && /```/ { exit } f && g { sub(/^     /, ""); print }' "$root/plugin/skills/todo-init/SKILL.md" | tr -d '\r'; }
existing_problems() {
  local d="$1" s="$2" ev start f w rc want got file
  STUB_MODE=solve run "$d" "$s" "$tmp/runs"; rc=$?
  [ "$rc" = 0 ] || { echo "run.sh exited $rc: $(tail -1 "$tmp/last.log")"; return; }
  [ "$(outcome scenario)" = "$s" ] || { echo "the last row is for $(outcome scenario), not $s"; return; }
  [ "$(outcome final_outcome)" = PASS ] || echo "the outcome is $(outcome final_outcome), not PASS"
  [ "$(outcome arm)" = "$(basename "$d")" ] || echo "the row names the arm $(outcome arm)"
  # start-sha.txt is written after the scenario's own preparation (5-interrupted adds a wip commit), so take the root commit.
  ev="$tmp/runs/$(outcome evidence_dir)"; start="$(git -C "$ev/repo" rev-list --max-parents=0 "$(cat "$ev/start-sha.txt" 2>/dev/null)" 2>/dev/null)"
  want="$( { (cd "$bench/scenarios/$s/repo" && find . -type f | sed 's|^\./||'); printf '%s\n' AGENTS.md CLAUDE.md TODO.md CHANGELOG.md; } | LC_ALL=C sort)"
  got="$(git -C "$ev/repo" ls-tree -r --name-only "$start" 2>/dev/null | grep -v '^\.claude/skills/' | grep -v '^\.agents/skills/' | LC_ALL=C sort)"
  [ "$got" = "$want" ] || echo "the start commit's files outside the skills are: $(printf '%s' "$got" | tr '\n' ' ')"
  for f in TODO.md CHANGELOG.md; do
    file="$(git -C "$ev/repo" show "$start:$f" 2>/dev/null | tr -d '\r')"; want="$(init_block "$f")"
    [ -n "$want" ] && [ "$file" = "$want" ] || echo "$f is not what todo-init writes"
  done
  [ "$(git -C "$ev/repo" show "$start:README.md" 2>/dev/null | tr -d '\r' | grep -c '^Tests:')" = 1 ] \
    && [ "$(git -C "$ev/repo" show "$start:README.md" 2>/dev/null | tr -d '\r' | grep -cx 'Tests: `python3 -m unittest discover -s tests -t .`')" = 1 ] || echo "README.md has not exactly one Tests line"
  w="$tmp/lint-$s"; rm -rf "$w"; mkdir -p "$w"
  git -C "$ev/repo" show "$start:TODO.md" > "$w/TODO.md" 2>/dev/null; git -C "$ev/repo" show "$start:CHANGELOG.md" > "$w/CHANGELOG.md" 2>/dev/null
  (cd "$w" && bash "$root/tools/todo-lint.sh" TODO.md CHANGELOG.md > lint.out 2>&1) || echo "todo-lint: $(head -3 "$w/lint.out" | tr '\n' ' ')"
}
exbad=""
for s in 1-bugfix 5-interrupted; do exbad="$exbad$(existing_problems "$ex" "$s" | sed "s|^|$s: |" | tr '\n' ';')"; done
[ -z "$exbad" ] && ok "todo-skills-existing on 1-bugfix and 5-interrupted: the stub's solution is PASS and the start commit holds the scenario's files, the skills, AGENTS.md and CLAUDE.md, a TODO.md and CHANGELOG.md equal to the blocks of the todo-init skill, one README Tests line, and nothing else (no .todo/check.sh, plan doc or status page), and the lint passes" || bad "todo-skills-existing: $exbad"
if [ -f "$ex/arm.md" ] && grep -q 'todo-add' "$ex/arm.md" && grep -q 'todo-continue' "$ex/arm.md" && ! grep -qi 'todo-init' "$ex/arm.md"; then ok "the arm.md of todo-skills-existing names todo-add and todo-continue and does not mention todo-init"
else bad "variants/todo-skills-existing/arm.md is missing, does not name todo-add and todo-continue, or mentions todo-init"; fi
# It is a variant, not an arm: outside arms/ the coverage check does not ask for its rows, and nothing here published a row.
# Moved under arms/ (a private copy of publish.sh and the folders it reads), the check names it on every scenario.
[ ! -e "$bench/arms/todo-skills-existing" ] && [ "$(pubsum)" = "$pub_before" ] && ok "todo-skills-existing is not under arms/ and the published table is unchanged" || bad "todo-skills-existing is under arms/ or the published table changed"
mkdir -p "$tmp/bm"; cp "$pubsh" "$tmp/bm/"; cp -R "$bench/arms" "$bench/scenarios" "$tmp/bm/"; cp -R "$ex" "$tmp/bm/arms/"
# A table with only its header: the real one may hold scored rows of the variant once a batch of it is published.
head -1 "$pubdir/results/results.csv" > "$tmp/bm/results.csv"
out="$(BENCH_RESULTS="$tmp/bm/results.csv" bash "$tmp/bm/publish.sh" check --coverage 2>&1)"; rc=$?
[ "$rc" -ne 0 ] && [ "$(printf '%s\n' "$out" | grep -c 'FAIL  no scored row for arm todo-skills-existing')" = 6 ] && ok "under arms/ the coverage check asks for rows of todo-skills-existing on all six scenarios" || bad "coverage check with the variant under arms/: rc=$rc $(printf '%s\n' "$out" | tail -2 | tr '\n' ' ')"
# Variants that break the contract are caught. One copy leaves everything at once: a second Tests line, a TODO.md without the Lanes
# section, and .todo/check.sh (plain init without --ci does not write it), .todo/todo-lint.sh and a plan doc, which init does not write.
mkdir -p "$tmp/ex-bad"; cp "$ex/arm.md" "$ex/setup.sh" "$tmp/ex-bad/" 2>/dev/null
cat >> "$tmp/ex-bad/setup.sh" <<'MUT'
printf '%s\n' 'Tests: `pytest`' >> "$repo/README.md"
printf '%s\n' '# Active Backlog' '' '## Task Tree' > "$repo/TODO.md"
mkdir -p "$repo/.todo" "$repo/docs/plans"
printf '%s\n' '#!/usr/bin/env bash' | tee "$repo/.todo/check.sh" "$repo/.todo/todo-lint.sh" > "$repo/docs/plans/PROJECT.md"
MUT
mp="$(existing_problems "$tmp/ex-bad" 1-bugfix)"; miss=""
printf '%s\n' "$mp" | grep -qF 'README.md has not exactly one Tests line' || miss="$miss [second Tests line]"
printf '%s\n' "$mp" | grep -qF 'TODO.md is not what todo-init writes' || miss="$miss [TODO.md without Lanes]"
for f in .todo/check.sh .todo/todo-lint.sh docs/plans/PROJECT.md; do printf '%s\n' "$mp" | grep -F 'the start commit'"'"'s files outside the skills' | grep -qF "$f" || miss="$miss [$f]"; done
[ -z "$miss" ] && ok "a variant that adds a second Tests line, drops the Lanes section or leaves .todo/check.sh, .todo/todo-lint.sh or a plan doc is caught" || bad "not caught:$miss"
# A variant whose setup fails on a scenario leaves no row: that is reported, not read from the previous run's row.
mkdir -p "$tmp/ex-fail"; cp "$ex/arm.md" "$ex/setup.sh" "$tmp/ex-fail/" 2>/dev/null
printf '%s\n' '[ -d "$repo/pricing" ] || exit 1' >> "$tmp/ex-fail/setup.sh"
existing_problems "$tmp/ex-fail" 5-interrupted | grep -q '^run.sh exited 2' && ok "a variant whose setup fails is reported with run.sh's exit code and not scored from an earlier row" || bad "a failing variant setup was not reported"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
