#!/usr/bin/env bash
# Git hooks establish worktree use, never concurrent worker execution.
# Optional second argument: controller-owned activity evidence, one line per
# distinct worker: <session-id> <lane> <active-start> <active-end>.
# Times must be comparable numeric timestamps of independently observed active
# work, not process or worktree lifetimes. The caller must establish provenance
# and protect this file from the evaluated agent; this script cannot do so.
set -u
repo="${1:?usage: lane-evidence.sh <repo> [controller-activity-file]}"
activity="${2:-}"
common="$(git -C "$repo" rev-parse --git-common-dir 2>/dev/null)" || { printf 'worktrees: 0\nevents: 0\nexecution: none\n'; exit 0; }
case "$common" in /*|?:*) ;; *) common="$repo/$common" ;; esac
main="$(git -C "$repo" rev-parse --show-toplevel)"
log="$common/trial-events"
if [ -s "$log" ]; then
  awk -v main="$main" '$3 != main { n++; seen[$3]=1 } END { for (k in seen) w++; print "worktrees: " w+0; print "events: " n+0 }' "$log"
else
  printf 'worktrees: 0\nevents: 0\n'
fi
if [ -n "$activity" ] && [ -s "$activity" ]; then
  awk '
    NF != 4 || $3 !~ /^[0-9]+([.][0-9]+)?$/ || $4 !~ /^[0-9]+([.][0-9]+)?$/ || $3+0 >= $4+0 || seen[$1]++ { bad=1 }
    { id[NR]=$1; lane[NR]=$2; start[NR]=$3+0; end[NR]=$4+0 }
    END {
      if (bad || NR < 2) { print "execution: unverified"; exit }
      for (i=1; i<=NR; i++) for (j=i+1; j<=NR; j++)
        if (lane[i] != lane[j] && start[i] < end[j] && start[j] < end[i]) concurrent=1
      for (i=1; i<=NR; i++) for (j=i+1; j<=NR; j++) if (lane[i] != lane[j]) distinct=1
      print "execution: " (concurrent ? "concurrent" : (distinct ? "sequential" : "unverified"))
    }' "$activity"
elif [ -s "$log" ] && awk -v main="$main" '$3 != main { found=1 } END { exit !found }' "$log"; then
  echo 'execution: unverified'
else
  echo 'execution: none'
fi
