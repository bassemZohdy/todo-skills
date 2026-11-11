#!/usr/bin/env bash
# todo-replay.sh - optional (FEAT-059): replay the Validated commands of the CHANGELOG entries added since a revision, so CI
# re-proves what a newly landed root claimed. Read-only apart from the commands it runs.
# Usage: bash todo-replay.sh [--run] [<rev>] [CHANGELOG.md]      (run from the repository root)
#   Without --run it only lists each command as SAFE or REFUSED. With --run it runs every SAFE command from the root.
#   No <rev>, or an empty one (an unset variable in check.sh): nothing to replay, exit 0.
#   New entries are the `- **ID**` lines of CHANGELOG.md whose ID is not in `git show <rev>:CHANGELOG.md`.
# A command is SAFE only when todo-lint.sh, given it as a Done when, reports no FAIL (I3 vacuous or masked, I10 forbidden)
# and none of W3 (not a known test, lint, typecheck or build runner), W4 (a piped runner hides its exit status) and W6 (may
# download and run remote code). Every
# other command is printed as REFUSED and never run: review it, and run it yourself if it is safe.
# Command safety: a command that runs a script or target (`bash <file>`, `make <target>`, `npm test`) runs what that file
# holds, which the lint does not read. Read the scripts your Validated commands name, as for .todo/check.sh.
# Needs bash, awk, grep, sed, tr, git, and todo-lint.sh next to this script.
# Exit: 0 nothing to replay or every command passed, 1 a replayed command failed, 2 usage or git error, 3 refused commands
# (and none failed).
run=0
if [ "${1:-}" = "--run" ]; then run=1; shift; fi
rev="${1:-}"; cl="${2:-CHANGELOG.md}"
here="$(cd "$(dirname "$0")" && pwd)"; lint="$here/todo-lint.sh"
if [ -z "$rev" ]; then echo "nothing to replay: no revision given"; exit 0; fi
[ -f "$cl" ] || { echo "FAIL: $cl not found"; exit 2; }
git rev-parse --verify -q "$rev^{commit}" >/dev/null 2>&1 || { echo "FAIL: unknown revision $rev"; exit 2; }
ids() { tr -d '\r' | sed -nE 's/^- \*\*([A-Z]+-[0-9]+(\.[0-9]+)*)\*\*.*/\1/p'; }
old=" $(git show "$rev:$cl" 2>/dev/null | ids | tr '\n' ' ') "
tmp="$(mktemp -d)" || exit 2
trap 'rm -rf "$tmp"' EXIT
: > "$tmp/none.md"
n=0; refused=0; failed=0
while IFS= read -r line; do
  id="$(printf '%s\n' "$line" | ids)"
  case "$old" in *" $id "*) continue ;; esac
  case "$line" in *"Validated:"*) ;; *) continue ;; esac
  seg="$(printf '%s\n' "$line" | sed -e 's/.*Validated://' -E -e 's/ (Docs|Includes|From): .*//')"
  # The commands are the backticked spans of the Validated part.
  while IFS= read -r c; do
    [ -n "$c" ] || continue
    n=$((n + 1))
    reason=""
    if [ ! -f "$lint" ]; then reason="todo-lint.sh not found next to todo-replay.sh"
    else
      printf '# Active Backlog\n\n## Task Tree\n- [ ] **TASK-001** · P2 · low · replay\n  - Done when: replay; `%s`\n' "$c" > "$tmp/TODO.md"
      reason="$(bash "$lint" "$tmp/TODO.md" "$tmp/none.md" 2>&1 | grep -E '^(FAIL|WARN W3|WARN W4|WARN W6)' | head -1 | sed -E 's/^(FAIL |WARN )([A-Z][0-9]+): line [0-9]+: TASK-001: /\2: /')"
    fi
    if [ -n "$reason" ]; then refused=$((refused + 1)); echo "REFUSED  $id: $c ($reason)"; continue; fi
    if [ "$run" -eq 0 ]; then echo "SAFE  $id: $c"; continue; fi
    printf '%s\n' "$c" > "$tmp/cmd.sh"
    if bash "$tmp/cmd.sh" > "$tmp/out.txt" 2>&1; then echo "PASS  $id: $c"
    else rc=$?; failed=$((failed + 1)); echo "FAIL  $id: $c (exit $rc)"; tail -5 "$tmp/out.txt" | sed 's/^/      /'; fi
  done < <(printf '%s\n' "$seg" | awk -F'`' '{ for (i = 2; i <= NF; i += 2) print $i }')
done < <(tr -d '\r' < "$cl" | grep -E '^- \*\*[A-Z]+-[0-9]+(\.[0-9]+)*\*\*')
if [ "$n" -eq 0 ]; then echo "nothing to replay: no Validated command was added since $rev"; exit 0; fi
echo "replay: $n command(s), $failed failed, $refused refused$([ "$run" -eq 0 ] && echo ' (listed only; add --run to run them)')"
[ "$failed" -gt 0 ] && exit 1
[ "$refused" -gt 0 ] && exit 3
exit 0
