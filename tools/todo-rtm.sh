#!/usr/bin/env bash
# todo-rtm.sh - optional, read-only lookup and check of the Markdown RTM (requirements traceability matrix).
# Usage: bash todo-rtm.sh [repo-root]     (default: current directory)
# Resolution: docs/RTM.md when it exists, else the "## RTM" section of README.md, else none. An RTM is never required.
# Format: a Markdown table with columns Req | Requirement | Tasks | Verification; Tasks holds task IDs only (no state).
# Prints "RTM: <location>" (or "RTM: none"), then one "FAIL R<n>: ..." line per problem:
#   R1 a task ID in the RTM is in neither TODO.md nor CHANGELOG.md (stale link)
#   R2 every task of a row is archived in CHANGELOG.md but the Verification cell is empty
#   R3 the same Req ID appears in more than one row (a duplicate mapping)
# Exit codes: 0 no RTM or no problems, 1 problems found. Needs bash, awk, grep, sed and tr.
# --version prints the release this copy comes from (FEAT-088); tests/run.sh checks it against the manifests.
todo_skills_version="0.5.0"
if [ "${1:-}" = "--version" ]; then echo "todo-rtm.sh $todo_skills_version"; exit 0; fi
root="${1:-.}"
if [ -f "$root/docs/RTM.md" ]; then src="$root/docs/RTM.md"; loc="docs/RTM.md"; sect=0
elif [ -f "$root/README.md" ] && grep -q '^## RTM[[:space:]]*$' "$root/README.md"; then src="$root/README.md"; loc="README.md"; sect=1
else echo "RTM: none"; exit 0; fi
echo "RTM: $loc"

ids() { [ -f "$1" ] && grep -oE '[A-Z]+-[0-9]+(\.[0-9]+)*' "$1" | sort -u | tr '\n' ' '; }
live=" $(ids "$root/TODO.md")"
arch=" "
if [ -f "$root/CHANGELOG.md" ]; then
  arch=" $( { grep -oE '^- \*\*[A-Z]+-[0-9]+(\.[0-9]+)*\*\*' "$root/CHANGELOG.md" | grep -oE '[A-Z]+-[0-9]+(\.[0-9]+)*'
              grep -E 'Includes:' "$root/CHANGELOG.md" | sed 's/.*Includes://' | grep -oE '[A-Z]+-[0-9]+(\.[0-9]+)*'
            } | tr '\n' ' ') "
fi

awk -v sect="$sect" -v live="$live" -v arch="$arch" '
function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
function fail(msg) { print "FAIL R" msg; bad++ }
sect && /^## RTM[ \t]*$/ { on = 1; next }
sect && /^## / { on = 0 }
sect && !on { next }
/^\|/ {
  n = split($0, c, "|")
  if (n < 5) next
  req = trim(c[2]); tasks = trim(c[4]); ver = trim(c[5])
  if (req == "Req" || req ~ /^:?-+:?$/ || req == "") next
  if (req in seen) fail("3: " req ": the requirement appears in more than one row"); seen[req] = 1
  m = split(tasks, t, /[ ,;]+/); done = (m > 0); cnt = 0
  for (k = 1; k <= m; k++) {
    if (t[k] !~ /^[A-Z]+-[0-9]+(\.[0-9]+)*$/) continue
    cnt++
    inl = index(live, " " t[k] " ") > 0; ina = index(arch, " " t[k] " ") > 0
    if (!inl && !ina) { fail("1: " req ": task " t[k] " is in neither TODO.md nor CHANGELOG.md"); done = 0 }
    else if (inl) done = 0
  }
  if (cnt > 0 && done && (ver == "" || ver == "-" || ver == "n/a")) fail("2: " req ": all tasks are archived but the Verification cell is empty")
}
END { exit (bad > 0) }' "$src"
