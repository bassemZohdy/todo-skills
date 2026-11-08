#!/usr/bin/env bash
# Runs `lanes` or `multi-module` with one fresh Codex process per lane, all started at the same time (TASK-044).
# Usage: [TRIAL_LABEL=<word>] [TRIAL_LANE_WRITE="<abs path> ..."] bash tests/trials/run-codex-lanes.sh <runs-dir> <lanes|multi-module>
# Codex has no subagent tool, so the controller is the coordinator's subagent tool (reference/lanes.md, step 3):
#   coordinate  a fresh `codex exec` runs /todo-continue --all-lanes --merge in the main checkout (steps 0-2: claims and
#               worktrees) and, at step 3, writes each lane's subagent instructions to <repo>.todo/<ROOT-ID>.brief.md
#   lanes       the controller accepts a brief only when <repo>.todo/<ROOT-ID> is a worktree of this repository on a
#               todo/<ROOT-ID>-* branch whose TODO.md holds that root, one brief per lane, and starts one fresh `codex exec`
#               per accepted brief at the same time; each may write only its own worktree, the shared .git and that
#               worktree's own metadata folder .git/worktrees/<name> (Codex protects a writable root's Git metadata
#               read-only unless it is granted explicitly, and Git cannot lock the worktree's index without it)
#   finish      a fresh `codex exec` runs /todo-continue --all-lanes --merge again; its step 0 takes the roots at next: drain
#               to step 4 (refresh, verify, drain, merge) and step 5 (report). Skipped (finish-skipped.txt) when a worker
#               exited non-zero (INFRA_ERROR) or left its root branch without next: drain (FAIL): the finishing
#               coordinator would then do that lane's work itself, one lane after another
# Activity (lane-evidence.sh's second argument): the controller stamps every line of each worker's `codex exec --json`
# stream with its own clock as the line arrives. A worker is active from its first tool event (item.started of a command
# or file change) to its last tool event (item.completed). These events are written by the Codex process, not by the
# agent's commands (their output is quoted inside an event, never a line of its own), and activity.txt is written outside
# every root the agents may write. Process lifetimes and worktree events are not used.
# Permission profile (the Linux trial profile of codex-exec.sh, with the roots of each phase): read everything, deny the
# Codex login, the controller checkout and everything in the runs folder except this scenario's repo and its worktree
# folder (the evidence included), write only the listed roots, no network. Denying the whole runs folder stopped Codex
# from starting a session in a worktree (its sandbox could not mount the worktree's Git metadata). Run it where
# that profile is enforced (the Linux container of docs/evals/codex-linux-2026-11-08); TRIAL_LANE_WRITE adds writable roots
# such as a dependency cache to every phase.
# Evidence: <runs>/<scenario>/evidence/<UTC time>-<pid>[-label]/ with setup.log, coordinate/, briefs/, dispatch.txt,
# launches.txt, lanes/<ROOT-ID>/, activity.txt, after-lanes-git-state.txt, finish/, git-state.txt, lane-evidence.txt,
# execution.txt, assert.log, assert-exit.txt, outcome.txt and SHA256SUMS. Each agent folder holds prompt.txt, command.txt,
# events.log (<controller time> <event>), stderr.log, report.txt, session-id.txt and agent-exit.txt.
# outcome.txt as in run-codex.sh: PASS, FAIL, INFRA_ERROR (an agent exit not 0, a failed verifier, or a sandbox block
# found by infra-signature.sh) or UNVERIFIED (no report from the finishing session). Concurrency is execution.txt.
set -u
runs="${1:?usage: run-codex-lanes.sh <runs-dir> <lanes|multi-module>}"; scenario="${2:?scenario}"
case "$scenario" in lanes|multi-module) ;; *) echo 'run-codex-lanes.sh runs only lanes or multi-module' >&2; exit 2 ;; esac
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ctl="$(cd "$here/../.." && pwd)"
mkdir -p "$runs/$scenario/evidence" || exit 2
runs="$(cd "$runs" && pwd)"; sd="$runs/$scenario"; repo="$sd/repo"; todo="$repo.todo"
codex_home="${CODEX_HOME:-$HOME/.codex}"
for p in "$runs" "$ctl" "$codex_home" ${TRIAL_LANE_WRITE:-}; do
  case "$p" in *'"'*|*'\'*) echo "unsupported character in $p" >&2; exit 2 ;; /*) ;; *) echo "not an absolute path: $p" >&2; exit 2 ;; esac
done
id="$(date -u +%Y%m%dT%H%M%SZ)-$$${TRIAL_LABEL:+-$TRIAL_LABEL}"
ev="$sd/evidence/$id"
mkdir "$ev" 2>/dev/null || { echo "evidence folder $ev already exists; refusing to overwrite"; exit 2; }
sums() { (cd "$ev" && find . -type f ! -name SHA256SUMS | sed 's|^\./||' | LC_ALL=C sort | while IFS= read -r f; do
  if command -v sha256sum >/dev/null 2>&1; then sha256sum -- "$f"; else shasum -a 256 -- "$f"; fi; done > SHA256SUMS); }
infra() { printf 'INFRA_ERROR\n' > "$ev/outcome.txt"; echo "$1"; sums; exit 2; }
if [ -e "$repo" ] && [ -n "$(ls -A "$repo" 2>/dev/null)" ]; then
  echo "reused the existing repo $repo (setup not run)" > "$ev/setup.log"
else
  bash "$here/setup.sh" "$repo" "$scenario" > "$ev/setup.log" 2>&1 || infra "setup failed (see $ev/setup.log)"
fi
mkdir -p "$todo"
tmo=(); command -v timeout >/dev/null 2>&1 && tmo=(timeout 1500)
now() { local t="${EPOCHREALTIME:-}"; [ -n "$t" ] || t="$(date +%s)"; printf '%s' "${t/,/.}"; }
stamp() { local l; while IFS= read -r l || [ -n "$l" ]; do printf '%s %s\n' "$(now)" "$l"; done; }
agent() { # agent <dir> <cwd> <tmp> <writable root>...: one fresh `codex exec --json` on <dir>/prompt.txt
  # <tmp> (inside a writable root's Git metadata) becomes TMPDIR and java.io.tmpdir, as assert-exec.sh does for the
  # verifier: with /tmp read-only, Maven's Jansi lock file under /tmp made a coordinator stop its verification.
  local d="$1" cwd="$2" tmpd="$3" w code; shift 3
  mkdir -p "$tmpd"
  local fs="\":root\"=\"read\", \"$codex_home\"=\"deny\", \"$ctl\"=\"deny\"" p
  for p in "$runs"/* "$sd"/*; do
    case "$p" in "$sd"|"$repo"|"$todo") ;; *) [ ! -e "$p" ] || fs="$fs, \"$p\"=\"deny\"" ;; esac
  done
  for w in "$@" ${TRIAL_LANE_WRITE:-}; do fs="$fs, \"$w\"=\"write\""; done
  local args=(exec --json --ephemeral --ignore-user-config -m "${TRIAL_CODEX_MODEL:-gpt-6.1-terra}"
    -c 'default_permissions="trial"' -c "permissions.trial.filesystem={$fs}" -c 'permissions.trial.network.enabled=false'
    -C "$cwd" -o "$d/report.txt" -)
  { printf 'TMPDIR=%q JAVA_TOOL_OPTIONS=%q ' "$tmpd" "-Djava.io.tmpdir=$tmpd"; printf '%q ' codex "${args[@]}"
    printf '< prompt.txt\nfilesystem: {%s}\n' "$fs"; } > "$d/command.txt"
  TMPDIR="$tmpd" JAVA_TOOL_OPTIONS="${JAVA_TOOL_OPTIONS:+$JAVA_TOOL_OPTIONS }-Djava.io.tmpdir=$tmpd" \
    ${tmo[@]+"${tmo[@]}"} codex "${args[@]}" < "$d/prompt.txt" 2> "$d/stderr.log" | stamp > "$d/events.log"
  code="${PIPESTATUS[0]}"
  printf '%s\n' "$code" > "$d/agent-exit.txt"
  [ -f "$d/report.txt" ] || : > "$d/report.txt"
  sed -n 's/^[^ ]* {"type":"thread\.started","thread_id":"\([^"]*\)".*/\1/p' "$d/events.log" | head -1 > "$d/session-id.txt"
}
real() { (cd "$1" 2>/dev/null && { pwd -W 2>/dev/null || pwd -P; }); }   # pwd -W: Git Bash, where /tmp and /c/... name one folder

# 1. coordinate: claims, worktrees and one brief per lane
mkdir "$ev/coordinate" "$ev/briefs" "$ev/lanes"
TRIAL_LANE_PHASE=coordinate bash "$here/prompt.sh" "$repo" "$scenario" > "$ev/coordinate/prompt.txt" || infra "no prompt"
agent "$ev/coordinate" "$repo" "$repo/.git/trial-tmp/coordinate" "$repo" "$repo/.git" "$todo"

# 2. lanes: check every brief against git, then start all accepted workers at once
: > "$ev/dispatch.txt"; : > "$ev/launches.txt"; : > "$ev/activity.txt"
common="$(real "$repo/.git")"; ids=(); lanes=(); wts=(); metas=()
for b in "$todo"/*.brief.md; do
  [ -f "$b" ] || continue
  rid="$(basename "$b" .brief.md)"; wt="$todo/$rid"
  if ! printf '%s\n' "$rid" | grep -Eqx '[A-Z]+-[0-9]+'; then printf 'rejected %s: not a root ID\n' "$rid" >> "$ev/dispatch.txt"; continue; fi
  cp -- "$b" "$ev/briefs/$rid.brief.md"
  top="$(git -C "$wt" rev-parse --show-toplevel 2>/dev/null)"; gcd="$(git -C "$wt" rev-parse --git-common-dir 2>/dev/null)"
  case "$gcd" in /*|?:*) ;; ?*) gcd="$wt/$gcd" ;; esac
  if [ -z "$top" ] || [ "$(real "$top")" != "$(real "$wt")" ] || [ -z "$gcd" ] || [ "$(real "$gcd")" != "$common" ] || [ "$(real "$wt")" = "$(real "$repo")" ]; then
    printf 'rejected %s: %s is not a worktree of this repository\n' "$rid" "$wt" >> "$ev/dispatch.txt"; continue
  fi
  branch="$(git -C "$wt" branch --show-current)"
  case "$branch" in "todo/$rid-"*) ;; *) printf 'rejected %s: worktree is on %s, not todo/%s-*\n' "$rid" "${branch:-a detached HEAD}" "$rid" >> "$ev/dispatch.txt"; continue ;; esac
  lane="$(git -C "$wt" show HEAD:TODO.md 2>/dev/null | tr -d '\r' | awk -v id="$rid" '
    /^- \[/ { r = index($0, "**" id "**") > 0; if (r) found = 1; next }
    r && /Lane: / && lane == "" { s = $0; sub(/.*Lane: */, "", s); sub(/[ ,;].*$/, "", s); lane = s }
    END { if (found) print (lane == "" ? "main" : lane) }')"
  if [ -z "$lane" ]; then printf 'rejected %s: not a root in the TODO.md of %s\n' "$rid" "$branch" >> "$ev/dispatch.txt"; continue; fi
  dup=0; for l in ${lanes[@]+"${lanes[@]}"}; do [ "$l" != "$lane" ] || dup=1; done
  if [ "$dup" = 1 ]; then printf 'rejected %s: lane %s already has a worker\n' "$rid" "$lane" >> "$ev/dispatch.txt"; continue; fi
  gd="$(git -C "$wt" rev-parse --git-dir 2>/dev/null)"; case "$gd" in /*|?:*) ;; ?*) gd="$wt/$gd" ;; esac
  meta="$repo/.git/worktrees/$(basename "$gd")"
  if [ -z "$gd" ] || [ "$(real "$gd")" != "$(real "$meta")" ]; then
    printf 'rejected %s: its Git metadata is not under %s/.git/worktrees\n' "$rid" "$repo" >> "$ev/dispatch.txt"; continue
  fi
  printf 'accepted %s lane %s branch %s worktree %s\n' "$rid" "$lane" "$branch" "$wt" >> "$ev/dispatch.txt"
  ids+=("$rid"); lanes+=("$lane"); wts+=("$wt"); metas+=("$meta")
done
pids=()
for i in ${ids[@]+"${!ids[@]}"}; do
  d="$ev/lanes/${ids[$i]}"; mkdir "$d"
  { TRIAL_LANE_PHASE=worker bash "$here/prompt.sh" "${wts[$i]}" "$scenario"
    printf '\nThe coordinator'"'"'s instructions for %s:\n\n' "${ids[$i]}"; cat "$ev/briefs/${ids[$i]}.brief.md"; } > "$d/prompt.txt"
done
for i in ${ids[@]+"${!ids[@]}"}; do
  printf '%s %s launched\n' "$(now)" "${ids[$i]}" >> "$ev/launches.txt"
  agent "$ev/lanes/${ids[$i]}" "${wts[$i]}" "${metas[$i]}/trial-tmp" "${wts[$i]}" "$repo/.git" "${metas[$i]}" &
  pids+=("$!")
done
for p in ${pids[@]+"${pids[@]}"}; do wait "$p"; done
for i in ${ids[@]+"${!ids[@]}"}; do
  awk -v lane="${lanes[$i]}" -v sid="$(cat "$ev/lanes/${ids[$i]}/session-id.txt")" '
    { t = $1; e = substr($0, length($1) + 2) }
    e ~ /^[{]"type":"item[.](started|completed)","item":[{]"id":"[^"]*","type":"(command_execution|file_change)"/ {
      if (e ~ /^[{]"type":"item[.]started"/ && first == "") first = t
      if (e ~ /^[{]"type":"item[.]completed"/) last = t }
    END { if (sid != "" && first != "" && last != "" && last + 0 > first + 0) print sid, lane, first, last }' \
    "$ev/lanes/${ids[$i]}/events.log" >> "$ev/activity.txt"
done
bash "$here/snapshot-git.sh" "$repo" > "$ev/after-lanes-git-state.txt" 2>&1

# 3. finish: a fresh coordinator drains and merges what the lanes left at next: drain
workers_ok=1; unfinished=""
for f in "$ev"/lanes/*/agent-exit.txt; do [ ! -f "$f" ] || [ "$(cat "$f")" = 0 ] || workers_ok=0; done
for i in ${ids[@]+"${!ids[@]}"}; do   # each lane must leave its root at next: drain (lanes.md step 3), committed
  git -C "${wts[$i]}" show HEAD:TODO.md 2>/dev/null | tr -d '\r' | awk -v id="${ids[$i]}" '
    /^- \[/ { r = index($0, "**" id "**") > 0; next } r && /next: drain/ { found = 1 } END { exit !found }' \
    || unfinished="$unfinished ${ids[$i]}"
done
if [ "$workers_ok" = 0 ]; then
  echo 'a lane worker exited non-zero: the finishing session was not started' > "$ev/finish-skipped.txt"
elif [ -n "$unfinished" ]; then
  printf 'not at next: drain on its root branch:%s; the finishing session was not started\n' "$unfinished" > "$ev/finish-skipped.txt"
else
  mkdir "$ev/finish"
  bash "$here/prompt.sh" "$repo" "$scenario" > "$ev/finish/prompt.txt" || infra "no prompt"
  agent "$ev/finish" "$repo" "$repo/.git/trial-tmp/finish" "$repo" "$repo/.git" "$todo"
fi

bash "$here/snapshot-git.sh" "$repo" > "$ev/git-state.txt" 2>&1   # before assert.sh, which may check out branches
bash "$here/lane-evidence.sh" "$repo" "$ev/activity.txt" > "$ev/lane-evidence.txt" 2>&1
sed -n 's/^execution: //p' "$ev/lane-evidence.txt" > "$ev/execution.txt"
TRIAL_REPORT="$ev/finish/report.txt" bash "$here/assert-exec.sh" "$repo" "$scenario" > "$ev/assert.log" 2>&1
arc=$?
printf '%s\n' "$arc" > "$ev/assert-exit.txt"
outcome=""
for f in "$ev/coordinate/agent-exit.txt" "$ev"/lanes/*/agent-exit.txt "$ev/finish/agent-exit.txt"; do
  [ ! -f "$f" ] || [ "$(cat "$f")" = 0 ] || outcome=INFRA_ERROR
done
if [ -z "$outcome" ]; then
  if [ -n "$unfinished" ]; then outcome=FAIL   # a lane stopped short of its drain; see the worker's report
  elif [ ! -s "$ev/finish/report.txt" ]; then outcome=UNVERIFIED
  elif [ "$arc" = 0 ]; then outcome=PASS
  elif [ "$arc" = 1 ]; then outcome=FAIL
  else outcome=INFRA_ERROR; fi
fi
if [ "$outcome" != PASS ] && sig="$(bash "$here/infra-signature.sh" "$ev"/*/report.txt "$ev"/lanes/*/report.txt "$ev"/*/events.log "$ev"/lanes/*/events.log)"; then
  outcome=INFRA_ERROR; printf '%s\n' "$sig" > "$ev/infra-signature.txt"
fi
printf '%s\n' "$outcome" > "$ev/outcome.txt"
sums
tail -3 "$ev/assert.log"; echo "execution: $(cat "$ev/execution.txt")"; echo "outcome: $outcome ($ev)"
[ "$outcome" = PASS ]
