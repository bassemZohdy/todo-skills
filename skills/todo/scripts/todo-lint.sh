#!/usr/bin/env bash
# todo-lint.sh - read-only validator for the todo-skills invariants I1-I7.
# Usage: bash todo-lint.sh [TODO.md] [CHANGELOG.md]   (run from the repository root)
# Exit 0 when every invariant holds, 1 otherwise. Needs only bash, awk, grep, sort.
set -u

TODO="${1:-TODO.md}"
CHANGELOG="${2:-CHANGELOG.md}"
status=0

fail() { printf 'FAIL %s: %s\n' "$1" "$2"; status=1; }

if [ ! -f "$TODO" ]; then
  fail I6 "$TODO not found"
  exit 1
fi

# I4: line cap
lines=$(wc -l < "$TODO" | tr -d ' ')
if [ "$lines" -gt 120 ]; then
  fail I4 "$TODO has $lines lines (max 120)"
fi

# I1, I2, I3, I6: structure, one pass
awk_out=$(awk '
function flush(   miss) {
  if (id == "") return
  miss = ""
  if (!hasScope) miss = miss " Scope"
  if (!hasOut)   miss = miss " Out-of-Scope"
  if (!hasRef)   miss = miss " Ref"
  if (!hasVal)   miss = miss " Validation"
  if (miss != "") printf "FAIL I3: %s is missing:%s\n", id, miss
  if (hasVal && val ~ /^(`)?(true|echo|ls|:)([ `]|$)/) printf "FAIL I3: %s has a vacuous Validation\n", id
  if (hasVal && val ~ /^(manual|n\/a)/) printf "FAIL I3: %s has a non-command Validation\n", id
  if (sec == "blocked" && !(hasBR && hasCE && hasAR)) printf "FAIL I3: %s is blocked but lacks Blocker Reason, Command/Error or Action Required\n", id
  id = ""
}
/^# / { if ($0 == "# Active Backlog") h1++; next }
/^## / {
  flush()
  if ($0 ~ /In Progress \(Max 1\)$/)            { sec = "progress"; order = order "P"; np++ }
  else if ($0 ~ /Ready \(Prioritized Queue\)$/) { sec = "ready";    order = order "R"; nr++ }
  else if ($0 ~ /Blocked$/)                     { sec = "blocked";  order = order "B"; nb++ }
  else sec = "other"
  next
}
$0 ~ "^- \\[[ /!]\\] \\*\\*[A-Z]+-[0-9]+\\*\\*" {
  flush()
  marker = substr($0, 4, 1)
  match($0, /[A-Z]+-[0-9]+/)
  id = substr($0, RSTART, RLENGTH)
  hasScope = hasOut = hasRef = hasVal = hasBR = hasCE = hasAR = 0
  val = ""
  seen[id]++
  if (seen[id] == 2) printf "FAIL I2: %s appears more than once\n", id
  if (marker == "/") { act++; if (sec != "progress") printf "FAIL I1: %s is [/] outside In Progress\n", id }
  if (marker == " " && sec != "ready")   printf "FAIL I1: %s is [ ] outside Ready\n", id
  if (marker == "!" && sec != "blocked") printf "FAIL I1: %s is [!] outside Blocked\n", id
  if (sec == "progress") inprog++
  next
}
id != "" && /^  - Scope:[ ]*[^ ]/          { hasScope = 1 }
id != "" && /^  - Out of Scope:[ ]*[^ ]/   { hasOut = 1 }
id != "" && /^  - Ref:[ ]*[^ ]/            { hasRef = 1 }
id != "" && /^  - Validation:[ ]*[^ ]/     { hasVal = 1; val = $0; sub(/^  - Validation:[ ]*/, "", val) }
id != "" && /^  - Blocker Reason:[ ]*[^ ]/ { hasBR = 1 }
id != "" && /^  - Command\/Error:[ ]*[^ ]/ { hasCE = 1 }
id != "" && /^  - Action Required:[ ]*[^ ]/{ hasAR = 1 }
END {
  flush()
  if (act > 1)    printf "FAIL I1: %d tasks are [/] (max 1)\n", act
  if (inprog > 1) printf "FAIL I1: %d tasks under In Progress (max 1)\n", inprog
  if (h1 != 1)    print "FAIL I6: heading \"# Active Backlog\" missing or repeated"
  if (np != 1 || nr != 1 || nb != 1 || order != "PRB") print "FAIL I6: the three section headings must each appear once, in order: In Progress, Ready, Blocked"
}
' "$TODO")
if [ -n "$awk_out" ]; then
  printf '%s\n' "$awk_out"
  status=1
fi

# IDs of tasks in TODO.md and entries in CHANGELOG.md
todo_ids=$(grep -E '^- \[[ /!]\] \*\*[A-Z]+-[0-9]+\*\*' "$TODO" | grep -oE '[A-Z]+-[0-9]+' | sort -u)
done_ids=""
if [ -f "$CHANGELOG" ]; then
  done_ids=$(grep -E '^- \*\*[A-Z]+-[0-9]+\*\*' "$CHANGELOG" | grep -oE '^- \*\*[A-Z]+-[0-9]+' | grep -oE '[A-Z]+-[0-9]+' | sort -u)
fi

# I5: no ID in both files
for id in $todo_ids; do
  if printf '%s\n' "$done_ids" | grep -qx "$id"; then
    fail I5 "$id is in both $TODO and $CHANGELOG (interrupted drain: remove it from $TODO)"
  fi
done

# I7: every Depends/From reference exists
refs=$(grep -E '^  - (Depends|From):' "$TODO" | sed -E 's/^  - (Depends|From)://' | grep -oE '[A-Z]+-[0-9]+' | sort -u)
for r in $refs; do
  if ! printf '%s\n%s\n' "$todo_ids" "$done_ids" | grep -qx "$r"; then
    fail I7 "reference to unknown ID $r"
  fi
done

if [ "$status" -eq 0 ]; then
  n=$(printf '%s\n' "$todo_ids" | grep -c . || true)
  echo "OK: invariants I1-I7 hold ($n task(s) in $TODO, $lines lines)"
fi
exit "$status"
