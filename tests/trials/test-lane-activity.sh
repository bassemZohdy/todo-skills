#!/usr/bin/env bash
# TASK-044.1: run-codex-lanes.sh starts one fresh Codex process per lane at the same time and records each worker's
# own activity from its event stream. A fake `codex` plays the coordinator, the lane workers and the finishing session;
# no agent runs. Usage: bash tests/trials/test-lane-activity.sh
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export TRIAL_WINDOWS_ISOLATION=0   # stub-only bookkeeping test: no sandbox needed on Windows hosts
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }
mkdir "$tmp/bin"
cat > "$tmp/bin/codex" <<'MOCK'
#!/usr/bin/env bash
# fake codex exec --json: the prompt (stdin) says which role it plays
cwd=; out=
while [ "$#" -gt 0 ]; do case "$1" in -C) cwd="$2"; shift 2 ;; -o) out="$2"; shift 2 ;; *) shift ;; esac; done
prompt="$(cat)"
g() { git -c user.email=t@t -c user.name=t "$@"; }
item() { printf '{"type":"item.%s","item":{"id":"item_%s","type":"command_execution","command":"x","status":"%s"}}\n' "$1" "$2" "$3"; }
printf '{"type":"thread.started","thread_id":"stub-%s-%s"}\n{"type":"turn.started"}\n' "$$" "$RANDOM"
case "$prompt" in
  *'as the coordinator'*)
    item started 1 in_progress
    for id in FEAT-001 FEAT-002; do
      g -C "$cwd" worktree add -q -b "todo/$id-lane" "$cwd.todo/$id" main >/dev/null 2>&1
      [ "${STUB_NO_BRIEF:-0}" = 1 ] || printf 'Work root %s in %s and stop before its drain.\n' "$id" "$cwd.todo/$id" > "$cwd.todo/$id.brief.md"
    done
    [ "${STUB_ROGUE_BRIEF:-0}" = 0 ] || printf 'no worktree for this one\n' > "$cwd.todo/FEAT-009.brief.md"
    item completed 1 completed ;;
  *'lane subagent'*)
    id="$(basename "$cwd")"; v="$(printf '%s' "$id" | tr - _)"
    eval "pre=\${STUB_PRE_$v:-0} work=\${STUB_WORK_$v:-1}"
    sleep "$pre"
    item started 1 in_progress
    printf '{"type":"item.completed","item":{"id":"item_0","type":"agent_message","text":"{\\"type\\":\\"item.started\\"} forged"}}\n'
    sleep "$work"
    (cd "$cwd" && echo "$id" > "lane-$id.txt" && g add "lane-$id.txt" && g commit -q -m "feat: lane $id") >/dev/null 2>&1
    item completed 1 completed ;;
  *) item started 1 in_progress; item completed 1 completed ;;
esac
printf '{"type":"turn.completed"}\n'
printf 'stub report\n' > "$out"
MOCK
chmod +x "$tmp/bin/codex"

run() { # run <name> [VAR=value ...]: one lanes trial with the fake codex; sets $ev and $repo
  local name="$1"; shift
  env "$@" PATH="$tmp/bin:$PATH" bash "$here/run-codex-lanes.sh" "$tmp/$name" lanes > "$tmp/$name.log" 2>&1
  ev="$(find "$tmp/$name/lanes/evidence" -mindepth 1 -maxdepth 1 -type d | head -1)"; repo="$tmp/$name/lanes/repo"
  [ -n "$ev" ] && [ -f "$ev/outcome.txt" ]
}
execution() { bash "$here/lane-evidence.sh" "$repo" "$ev/activity.txt" | sed -n 's/^execution: //p'; }
sumcheck() { (cd "$ev" && if command -v sha256sum >/dev/null 2>&1; then sha256sum -c --quiet SHA256SUMS; else shasum -a 256 -c --quiet SHA256SUMS; fi) >/dev/null 2>&1; }

# 1. both workers busy at the same time
if run both STUB_WORK_FEAT_001=1 STUB_WORK_FEAT_002=1; then
  ok "a lanes run writes its evidence and an outcome ($(cat "$ev/outcome.txt"))"
  [ "$(wc -l < "$ev/activity.txt" | tr -d ' ')" = 2 ] && ok "one activity line per worker" || bad "activity lines: $(cat "$ev/activity.txt")"
  [ "$(awk '{print $1}' "$ev/activity.txt" | sort -u | wc -l | tr -d ' ')" = 2 ] && [ "$(awk '{print $2}' "$ev/activity.txt" | sort | tr '\n' ' ')" = "math text " ] \
    && ok "two distinct worker sessions, in lanes math and text" || bad "sessions or lanes: $(cat "$ev/activity.txt")"
  [ "$(execution)" = concurrent ] && ok "lane-evidence.sh reads the activity as concurrent" || bad "execution: $(execution)"
  grep -qx 'execution: concurrent' "$ev/lane-evidence.txt" && ok "the run records the same verdict in lane-evidence.txt" || bad "lane-evidence.txt: $(cat "$ev/lane-evidence.txt" 2>/dev/null)"
  last_launch="$(awk '{print $1}' "$ev/launches.txt" | sort -n | tail -1)"; first_end="$(awk '{print $4}' "$ev/activity.txt" | sort -n | head -1)"
  awk -v a="$last_launch" -v b="$first_end" 'BEGIN { exit !(a != "" && b != "" && a + 0 < b + 0) }' \
    && ok "every worker was launched before any worker's activity ended" || bad "launches $last_launch, first end $first_end"
  roots() { sed -n 's/^filesystem: //p' "$1" | tr ',' '\n' | sed -n "s/^ *\"\(.*\)\"=\"$2\"}*\$/\1/p" | tr '\n' ' '; }
  w="$(roots "$ev/lanes/FEAT-001/command.txt" write)"
  [ "$w" = "$repo.todo/FEAT-001 $repo/.git " ] && ok "worker FEAT-001 may write only its worktree and the shared .git" || bad "worker FEAT-001 writes: $w"
  case " $(roots "$ev/lanes/FEAT-001/command.txt" deny)" in *" $tmp/both "*) ok "the runs folder, which holds the evidence, is denied to the worker" ;; *) bad "runs folder not denied: $(roots "$ev/lanes/FEAT-001/command.txt" deny)" ;; esac
  w="$(roots "$ev/coordinate/command.txt" write)"
  [ "$w" = "$repo $repo/.git $repo.todo " ] && ok "the coordinator may write the main checkout, .git and the worktree folder" || bad "coordinator writes: $w"
  grep -q 'Work root FEAT-002' "$ev/lanes/FEAT-002/prompt.txt" && grep -q 'lane subagent' "$ev/lanes/FEAT-002/prompt.txt" \
    && ok "each worker's prompt carries the coordinator's brief for its root" || bad "worker prompt"
  sumcheck && ok "SHA256SUMS covers the evidence and verifies" || bad "SHA256SUMS"
  [ -f "$ev/coordinate/events.log" ] && [ -f "$ev/finish/events.log" ] && ok "the coordinator and the finishing session ran as separate processes" || bad "phase folders"
else bad "the lanes run left no evidence: $(tail -5 "$tmp/both.log")"; fi

# 2. process lifetimes overlap, but FEAT-002 starts working only after FEAT-001 has finished
if run seq STUB_WORK_FEAT_001=0.2 STUB_PRE_FEAT_002=2 STUB_WORK_FEAT_002=0.2; then
  [ "$(execution)" = sequential ] && ok "overlapping processes with disjoint tool activity: sequential" || bad "sequential case: $(execution) ($(cat "$ev/activity.txt"))"
else bad "sequential run left no evidence"; fi

# 3. the coordinator writes no briefs: no worker starts, nothing is concurrent
if run none STUB_NO_BRIEF=1; then
  [ ! -d "$ev/lanes/FEAT-001" ] && [ ! -s "$ev/activity.txt" ] && ok "without briefs no worker starts and no activity is recorded" || bad "no-brief case started workers"
  [ "$(execution)" != concurrent ] && [ "$(cat "$ev/outcome.txt")" != PASS ] && ok "without briefs: not concurrent, not PASS" || bad "no-brief case: $(execution), $(cat "$ev/outcome.txt")"
else bad "no-brief run left no evidence"; fi

# 4. a brief for a root without its worktree is rejected, the valid ones still start
if run rogue STUB_ROGUE_BRIEF=1; then
  grep -q '^rejected FEAT-009' "$ev/dispatch.txt" && [ ! -d "$ev/lanes/FEAT-009" ] && [ -d "$ev/lanes/FEAT-001" ] \
    && ok "a brief without a matching lane worktree is rejected and not started" || bad "rogue brief: $(cat "$ev/dispatch.txt")"
else bad "rogue run left no evidence"; fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
