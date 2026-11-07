#!/usr/bin/env bash
# Reads the lane event log that the lane scenarios' git hooks write and says how the lanes ran. Read-only.
# Usage: bash tests/trials/lane-evidence.sh <repo>
# setup.sh installs post-checkout and post-commit hooks in the `lanes` and `multi-module` scenarios. Each event is one line
# in <git-common-dir>/trial-events:  <nanoseconds> <hook> <worktree top level> <branch>
# Events whose top level is not the main checkout belong to a lane worktree. This evidence does not depend on the agent's
# report or on how many worktrees are left at the end (a clean `git worktree list` proves nothing about how the lanes ran).
# Output (key: value lines):
#   worktrees: <n>        distinct lane worktrees that saw a checkout or commit
#   events: <n>           events in lane worktrees
#   execution: overlapping | sequential | none
#     overlapping  two lane worktrees were active in intersecting time windows
#     sequential   lane worktrees were used, but one finished before the next began
#     none         no lane worktree was used (or no event log exists)
set -u
repo="${1:?usage: lane-evidence.sh <repo>}"
common="$(git -C "$repo" rev-parse --git-common-dir 2>/dev/null)" || { echo "worktrees: 0"; echo "events: 0"; echo "execution: none"; exit 0; }
case "$common" in /*|?:*) ;; *) common="$repo/$common" ;; esac
main="$(git -C "$repo" rev-parse --show-toplevel)"
log="$common/trial-events"
[ -s "$log" ] || { echo "worktrees: 0"; echo "events: 0"; echo "execution: none"; exit 0; }
awk -v main="$main" '
  $3 != main { n++; t = $1 + 0
    if (!($3 in first) || t < first[$3]) first[$3] = t
    if (!($3 in last)  || t > last[$3])  last[$3]  = t
    seen[$3] = 1 }
  END {
    w = 0; for (k in seen) { w++; key[w] = k }
    over = 0
    for (i = 1; i <= w; i++) for (j = i + 1; j <= w; j++) {
      lo = (first[key[i]] > first[key[j]]) ? first[key[i]] : first[key[j]]
      hi = (last[key[i]]  < last[key[j]])  ? last[key[i]]  : last[key[j]]
      if (lo < hi) over = 1
    }
    print "worktrees: " w
    print "events: " n + 0
    print "execution: " (w == 0 ? "none" : (over ? "overlapping" : "sequential"))
  }' "$log"
