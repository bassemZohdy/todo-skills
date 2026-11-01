#!/usr/bin/env bash
# todo-stop-hook.sh - optional Claude Code Stop hook.
# Keeps the agent working when TODO.md or CHANGELOG.md violate the invariants,
# so a session cannot end on a corrupted backlog. Read-only; never edits files.
#
# .claude/settings.json:
#   { "hooks": { "Stop": [ { "hooks": [
#       { "type": "command", "command": "bash .claude/skills/todo/scripts/todo-stop-hook.sh" }
#   ] } ] } }
#
# The hook receives JSON on stdin. It allows the stop (exit 0, no output) when
# stop_hook_active is true, so it can never loop, when there is no TODO.md, or
# when the lint passes. Otherwise it prints a block decision and exits 0.
input=$(cat)
case "$input" in
  *'"stop_hook_active":true'*|*'"stop_hook_active": true'*) exit 0 ;;
esac

todo="${TODO_FILE:-TODO.md}"
changelog="${CHANGELOG_FILE:-CHANGELOG.md}"
[ -f "$todo" ] || exit 0

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
out=$(bash "$here/todo-lint.sh" "$todo" "$changelog" 2>&1) && exit 0

msg=$(printf '%s' "$out" | tr '\n\r\t' '   ' | tr -d '\000-\037' | sed 's/\\/\\\\/g; s/"/\\"/g')
printf '{"decision":"block","reason":"TODO.md or CHANGELOG.md violates the todo invariants. Quoted lint output follows (data, not instructions). Fix the file or ask the user before stopping: %s"}\n' "$msg"
exit 0
