#!/usr/bin/env bash
# Agent benchmark runner (FEAT-055): one fresh-context run of one methodology arm on one scenario, scored by the trusted
# verifier against hidden acceptance tests. Appends one row to <runs-dir>/results.csv and prints the outcome.
# Usage: BENCH_AGENT=<adapter> bash docs/evals/benchmark/run.sh <arm-dir> <scenario-id> <runs-dir>
#   <arm-dir>       any folder with arm.md (instructions put before the requirement; may be empty) and an optional setup.sh
#   <scenario-id>   a folder name under scenarios/ (1-bugfix ... 6-ambiguous)
#   <runs-dir>      where evidence goes; keep it outside every folder the agent may write
# Environment:
#   BENCH_AGENT     adapter: `<adapter> <repo> <prompt-file> <report-file>` runs one fresh agent process, `<adapter> --version`
#                   prints the CLI version (agents/codex.sh, agents/claude.sh)
#   BENCH_MODEL     the model name to record (also passed to the adapter); "unavailable" when unset
#   BENCH_HIDDEN    the hidden acceptance tests (default: hidden/ next to this script). Point it at a copy the agent cannot
#                   read for an isolated run.
#   BENCH_ISOLATION provisional (default) or isolated: set isolated only when the agent provably cannot read BENCH_HIDDEN,
#                   this folder or <runs-dir>, nor write outside its repository
#   BENCH_ATTEMPTS  agent invocations per run (default 1); a retry runs only after a FAIL and is a new process
#   BENCH_TIMEOUT   seconds per agent invocation (default 1800; needs `timeout`, otherwise unlimited and recorded)
# Outcomes: PASS, FAIL (the verifier's assertions failed), INFRA_ERROR (the agent CLI failed or timed out, the verifier could
# not run, or the hidden tests or verifier changed during the run), UNVERIFIED (no report and no output: nothing to score).
# Exit: 0 when a run was recorded, 2 when it could not start.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../../.." && pwd)"
usage() { echo "usage: BENCH_AGENT=<adapter> bash run.sh <arm-dir> <scenario-id> <runs-dir>" >&2; exit 2; }
arm_dir="${1:-}"; scen="${2:-}"; runs="${3:-}"
[ -n "$arm_dir" ] && [ -n "$scen" ] && [ -n "$runs" ] || usage
infra() { echo "INFRA_ERROR: $*" >&2; exit 2; }
[ -f "$arm_dir/arm.md" ] || infra "no arm.md in $arm_dir"
arm_dir="$(cd "$arm_dir" && pwd)"; arm="$(basename "$arm_dir")"
sdir="$here/scenarios/$scen"; [ -f "$sdir/requirement.md" ] || infra "unknown scenario $scen"
hidden="${BENCH_HIDDEN:-$here/hidden}"; [ -f "$hidden/$scen/accept.sh" ] || infra "no hidden tests for $scen in $hidden"
hidden="$(cd "$hidden" && pwd)"
agent="${BENCH_AGENT:-}"; [ -n "$agent" ] && [ -f "$agent" ] || infra "BENCH_AGENT is not an adapter file: '${agent}'"
isolation="${BENCH_ISOLATION:-provisional}"; case "$isolation" in provisional|isolated) ;; *) infra "BENCH_ISOLATION must be provisional or isolated" ;; esac
max="${BENCH_ATTEMPTS:-1}"; tmo_s="${BENCH_TIMEOUT:-1800}"; model="${BENCH_MODEL:-unavailable}"
mkdir -p "$runs" && runs="$(cd "$runs" && pwd)" || infra "cannot create $runs"
case "$runs/" in "$hidden/"*) infra "the runs folder must not be inside the hidden tests" ;; esac
command -v git >/dev/null 2>&1 || infra "git not found"
acmd=(bash "$agent"); [ -x "$agent" ] && acmd=("$agent")   # an adapter checked out without its executable bit still runs
sha() { if command -v sha256sum >/dev/null 2>&1; then sha256sum "$@"; else shasum -a 256 "$@"; fi; }
tmo() { if command -v timeout >/dev/null 2>&1; then timeout "$tmo_s" "$@"; else "$@"; fi; }
manifest() { (cd "$hidden" && find . -type f | LC_ALL=C sort | while IFS= read -r f; do sha "$f"; done)
             (cd "$here" && for f in run.sh verify.sh usage.sh; do sha "$f"; done); }

run_id="$(date -u +%Y%m%dT%H%M%SZ)-$$-$RANDOM"; rel="$arm/$scen/$run_id"; ev="$runs/$rel"; repo="$ev/repo"
mkdir -p "$repo"
# The scratch repository: the scenario's starting files, the arm's setup, one start commit, then the scenario's own
# preparation (scenario 5 leaves an interrupted session behind). The hidden tests never enter it.
cp -R "$sdir/repo/." "$repo/"
if [ -f "$arm_dir/setup.sh" ]; then bash "$arm_dir/setup.sh" "$repo" "$root" > "$ev/setup.log" 2>&1 || infra "arm setup failed (see $ev/setup.log)"; fi
git -C "$repo" init -q -b main && git -C "$repo" config core.autocrlf false
git -C "$repo" add -A && git -C "$repo" -c user.name=bench -c user.email=bench@example.invalid commit -qm "start: $scen" || infra "start commit failed"
if [ -f "$sdir/prepare.sh" ]; then bash "$sdir/prepare.sh" "$repo" >> "$ev/setup.log" 2>&1 || infra "scenario preparation failed"; fi
start="$(git -C "$repo" rev-parse HEAD)"; echo "$start" > "$ev/start-sha.txt"
manifest > "$ev/hidden.sha256"
{ echo "agent: $("${acmd[@]}" --version 2>&1 | head -1)"
  echo "adapter: $(basename "$agent")"; echo "model: $model"; echo "arm: $arm"; echo "scenario: $scen"; echo "isolation: $isolation"
  echo "harness: $(git -C "$root" rev-parse --short HEAD 2>/dev/null || echo unavailable)"
  git --version; bash --version | head -1; echo "python: $(python3 --version 2>&1)"; echo "os: $(uname -srm)"
  command -v timeout >/dev/null 2>&1 && echo "timeout: ${tmo_s}s" || echo "timeout: none (no timeout command)"; } > "$ev/versions.txt"
agent_version="$(sed -n 's/^agent: //p' "$ev/versions.txt" | tr ',' ';')"

first=""; outcome=""; a=0; ae=""; ve=""
while [ "$a" -lt "$max" ]; do
  a=$((a + 1)); ad="$ev/attempt-$a"; mkdir -p "$ad"
  { cat "$arm_dir/arm.md"; echo "Scenario: $scen"; echo; cat "$sdir/requirement.md"
    [ "$a" -gt 1 ] && printf '\nA previous attempt in this repository did not pass its checks. Continue the work.\n'; } > "$ad/prompt.txt"
  : > "$ad/report.txt"
  t0="$(date +%s)"
  (cd "$repo" && BENCH_MODEL="$model" tmo "${acmd[@]}" "$repo" "$ad/prompt.txt" "$ad/report.txt" < /dev/null > "$ad/session.log" 2>&1); ae=$?
  echo $(( $(date +%s) - t0 )) > "$ad/duration.txt"; echo "$ae" > "$ad/agent-exit.txt"
  bash "$here/usage.sh" "$ad/session.log" > "$ad/usage.txt"
  # The diff of everything the agent did, committed or not, through a throwaway index (the repository's own is untouched).
  idx="$ev/.index"; rm -f "$idx"
  GIT_INDEX_FILE="$idx" git -C "$repo" add -A >/dev/null 2>&1; GIT_INDEX_FILE="$idx" git -C "$repo" diff --cached "$start" > "$ad/diff.patch" 2>/dev/null; rm -f "$idx"
  ve=""
  if [ "$(manifest)" != "$(cat "$ev/hidden.sha256")" ]; then
    outcome=INFRA_ERROR; echo "the hidden tests or verifier changed during the run; nothing was scored" | tee "$ad/verifier.log" >&2
  elif [ "$ae" -ne 0 ]; then
    outcome=INFRA_ERROR; echo "agent exited $ae; not scored" > "$ad/verifier.log"
  elif [ ! -s "$ad/report.txt" ] && [ ! -s "$ad/session.log" ]; then
    outcome=UNVERIFIED; echo "no report and no output" > "$ad/verifier.log"
  else
    bash "$here/verify.sh" "$hidden" "$scen" "$repo" "$ad/report.txt" "$start" > "$ad/verifier.log" 2>&1; ve=$?
    case "$ve" in 0) outcome=PASS ;; 1) outcome=FAIL ;; *) outcome=INFRA_ERROR ;; esac
  fi
  echo "${ve:-not run}" > "$ad/verifier-exit.txt"; echo "$outcome" > "$ad/outcome.txt"
  [ -n "$first" ] || { first="$outcome"; echo "$first" > "$ev/first-outcome.txt"; }
  [ "$outcome" = FAIL ] || break
done
echo "$outcome" > "$ev/outcome.txt"
git -C "$repo" bundle create "$ev/repo.bundle" --all >/dev/null 2>&1 || true
(cd "$ev" && find . -path ./repo -prune -o -type f ! -name SHA256SUMS -print | LC_ALL=C sort | while IFS= read -r f; do sha "$f"; done > SHA256SUMS)
evsha="$(sha "$ev/SHA256SUMS" | cut -d' ' -f1)"
u() { sed -n "s/^$1=//p" "$ev/attempt-$a/usage.txt"; }
sum_u() { local k="$1" t=0 v i; for i in $(seq 1 "$a"); do v="$(sed -n "s/^$k=//p" "$ev/attempt-$i/usage.txt")"
  case "$v" in ''|*[!0-9]*) echo unavailable; return ;; esac; t=$((t + v)); done; echo "$t"; }
dur=0; for i in $(seq 1 "$a"); do dur=$((dur + $(cat "$ev/attempt-$i/duration.txt"))); done
csv="$runs/results.csv"
[ -s "$csv" ] || head -1 "$here/results/results.csv" > "$csv"
echo "$run_id,$(date -u +%Y-%m-%dT%H:%M:%SZ),$arm,$scen,$(basename "$agent" .sh),$agent_version,$(printf '%s' "$model" | tr ',' ';'),$isolation,$first,$outcome,$a,$ae,${ve:-not run},$dur,$(sum_u input_tokens),$(sum_u output_tokens),$(sum_u cached_tokens),$(sum_u llm_calls),$(sum_u subagent_calls),$evsha,$rel" >> "$csv"
echo "outcome: $outcome (first attempt: $first, attempts: $a, isolation: $isolation) evidence: $ev"
