#!/usr/bin/env bash
# Shared pieces of the trial harness (FEAT-138.6). Sourced by the runners, score.sh and selftest.sh:
#   trial_limit                   prints the agent's time limit in seconds: TRIAL_TIMEOUT, 1500 when it is unset or empty.
#                                 A value that is no whole number above 0 gives a message and status 2.
#   trial_inside <path>           succeeds when <path> stays below the folder it is relative to: not empty, not absolute
#                                 (/x, \x, C:/x, C:\x) and without "..". For project.txt, which names a project below <runs>.
#   trial_project <runs> <scenario>  prints the path below <runs> of the scratch project for a new invocation.
#   trial_names <dir> <scenario>  prints what in a scratch project tells an agent which scenario it is in, one finding per
#                                 line, and fails when there is one. See the function for what is read.
# As a command: bash tests/trials/trial-lib.sh names <dir> <scenario>
# Needs bash, git, find and grep. Read-only.

trial_limit() {
  local l="${TRIAL_TIMEOUT:-1500}"
  case "$l" in *[!0-9]*|0*) echo "TRIAL_TIMEOUT must be a whole number of seconds above 0 (unset or empty: 1500), got: $l" >&2; return 2 ;; esac
  printf '%s\n' "$l"
}

# shellcheck disable=SC1003
trial_inside() { case "$1" in ''|/*|'\'*|?:*|*..*) return 1 ;; esac; }

# trial_project <runs> <scenario>: prints where the scratch project of a new invocation is, as a path below <runs>. It is a
# new folder w-<random>/repo: the name must not tell the agent the scenario, so it is random, and w-<random> is made here
# with mkdir, so that two invocations never get the same one. With TRIAL_REUSE=1 it is the project of the scenario's newest
# invocation instead (its project.txt, else <scenario>/repo of the old layout); a project.txt that leaves <runs> gives a
# message and status 2. Call it before the invocation's own evidence folder exists.
trial_project() {
  local runs="$1" s="$2" last p="" rnd i=0
  if [ "${TRIAL_REUSE:-0}" = 1 ]; then
    last="$(ls -1 "$runs/$s/evidence" 2>/dev/null | sort | tail -1)"
    if [ -n "$last" ] && [ -f "$runs/$s/evidence/$last/project.txt" ]; then
      p="$(tr -d '\r\n' < "$runs/$s/evidence/$last/project.txt")"
      trial_inside "$p" || { echo "TRIAL_REUSE=1: project.txt of $last does not name a folder below the runs folder: $p" >&2; return 2; }
    elif [ -d "$runs/$s/repo" ]; then p="$s/repo"; fi
  fi
  while [ -z "$p" ]; do
    rnd="$(od -An -N6 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')"; [ -n "$rnd" ] || rnd="$(printf '%04x%04x%04x' "$RANDOM" "$RANDOM" "$RANDOM")"
    if mkdir "$runs/w-$rnd" 2>/dev/null; then p="w-$rnd/repo"; fi
    i=$((i + 1)); [ -n "$p" ] || [ "$i" -lt 20 ] || { echo "cannot make a project folder in $runs" >&2; return 2; }
  done
  printf '%s\n' "$p"
}

# What is read: the subjects of all commits (also those of a second clone's remote in .team/origin.git), the branch names,
# the names and the text of the files outside .git, .claude (the skills), .todo (copies of this repository's tools) and
# .team (a second clone), and inside .git the hooks that are not samples and the names of the files directly in it.
# What must hold: the root commit is "init" and no other commit is; every other commit is one of the history the scenario
# simulates (a conventional subject); and none of the above holds the scenario's name or a word of the table below. The
# table is honest rather than complete. A name of one word (lanes, release, report) is an ordinary word of the project and
# is not looked for. The marker files trial-* in .git may stay: an agent that is told it is a trial agent learns nothing
# about the scenario from them, so the general words are not applied inside .git.
trial_names() {
  local d="$1" s="$2" w h general='scenario|trial|harness|give-?away|on purpose|by design' subj odd roots out=""
  h=same
  case "$s" in
    stuck-loop) w='stuck|loop|cannot|impossible|contradict|unsatisf' ;;
    loop-limit) w='loop|attempt|stuck|guard|unreachable|impossible|out of reach|cannot' ;;
    time-limit) w='limit|attempt|stuck|guard|unreachable|impossible|out of reach|cannot|time ?out|(^|[^a-z])hang|slow|loop' ;;
    regress-block) w='regress|block|weaken|cannot' ;;
    resume-stopped|resumed-twice) w='resum|worker|twice|stopped|session'; h='' ;;   # its history holds resume commits
    stale-claim) w='stale|budget|days ago' ;;
    baseline-red|ts-baseline-red|java-baseline-red) w='baseline|broken' ;;
    dirty-tree) w='dirty|unexplained|nobody' ;;
    leftover-work) w='leftover|interrupted|unfinished|previous session' ;;
    interrupted-merge|ts-interrupted|java-interrupted) w='interrupt|died|crash' ;;
    refresh-from-base) w='refresh' ;;
    claimed-elsewhere) w='elsewhere' ;;
    race-claim-conflict|race-claim-benign) w='race|rival' ;;
    team-claim) w='peer-work|teammate' ;;
    drained-unmerged) w='unmerged' ;;
    blocked-sibling) w='sibling'; h='' ;;   # its history holds a block commit
    no-backlog) w='no backlog|without a backlog' ;;
    status-readonly) w='read-?only' ;;
    decompose) w='break down|too big' ;;
    *) w='' ;;
  esac
  case "$s" in *-*) w="${w:+$w|}$s" ;; esac
  if [ "$h" = same ]; then h="${w:+$w|}$general"; else h="$general|$s"; fi
  if [ -d "$d/.git" ]; then
    subj="$(git -C "$d" log --all --format=%s; [ ! -d "$d/.team/origin.git" ] || git -C "$d/.team/origin.git" log --all --format=%s)"
    roots="$(git -C "$d" log --all --max-parents=0 --format=%s | sort -u | tr '\n' ';')"
    [ "$roots" = "init;" ] || out="$out
the root commit is not \"init\": $roots"
    [ "$(git -C "$d" log --all --format=%s | grep -cx 'init')" = "$(git -C "$d" rev-list --all --max-parents=0 | wc -l | tr -d ' ')" ] || out="$out
a commit after the first is named \"init\" too"
    odd="$(printf '%s\n' "$subj" | grep -vx 'init' | grep -Ev '^(chore|feat|fix|docs|test|refactor)(\([a-z0-9._/-]+\))?: ' | sort -u | tr '\n' ';')"
    [ -z "$odd" ] || out="$out
a commit is neither \"init\" nor one of the simulated history: $odd"
    odd="$( { printf '%s\n' "$subj"; git -C "$d" for-each-ref --format='%(refname:short)'; } | grep -iE -- "$h" | sort -u | tr '\n' ';')"
    [ -z "$odd" ] || out="$out
a commit subject or a branch name: $odd"
    if [ -n "$w" ]; then
      odd="$(cd "$d" && { find .git/hooks -type f ! -name '*.sample' -exec grep -iEH -m1 -- "$w" {} + 2>/dev/null
                          find .git/hooks -type f ! -name '*.sample' 2>/dev/null | sed 's|.*/||' | grep -iE -- "$w"
                          find .git -maxdepth 1 -type f | sed 's|.*/||' | grep -iE -- "$w"; } | cut -c1-160 | tr '\n' ';')"
      [ -z "$odd" ] || out="$out
a hook or a file in .git: $odd"
    fi
  fi
  odd="$(cd "$d" && { find . -path ./.git -prune -o -path ./.claude -prune -o -path ./.todo -prune -o -path ./.team -prune -o -type f -print | grep -iE -- "${w:+$w|}$general" | sed 's/$/ (its name)/'
                      find . -path ./.git -prune -o -path ./.claude -prune -o -path ./.todo -prune -o -path ./.team -prune -o -type f -exec grep -iEH -m1 -- "${w:+$w|}$general" {} +; } | cut -c1-160 | tr '\n' ';')"
  [ -z "$odd" ] || out="$out
a scratch file: $odd"
  [ -z "$out" ] && return 0
  printf '%s\n' "$out" | grep .
  return 1
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  case "${1:-}" in
    names) shift; trial_names "${1:?usage: trial-lib.sh names <dir> <scenario>}" "${2:?scenario}" ;;
    *) echo "usage: bash tests/trials/trial-lib.sh names <dir> <scenario>" >&2; exit 2 ;;
  esac
fi
