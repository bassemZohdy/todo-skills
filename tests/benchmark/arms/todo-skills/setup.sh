# Installs the todo skills of the harness repository into the scratch repository before its start commit.
# Usage: bash setup.sh <scratch-repo> <harness-repository-root>
set -eu
repo="$1"; root="$2"
for d in .claude/skills .agents/skills; do mkdir -p "$repo/$d"; cp -R "$root/plugin/skills/." "$repo/$d/"; done
para='## Backlog
Work is tracked in TODO.md and CHANGELOG.md with the todo-* skills (/todo-init, /todo-plan, /todo-add, /todo-continue, /todo-update, /todo-status, /todo-report, /todo-release). Read the `todo` skill before editing TODO.md. Do not change TODO.md outside these commands.'
printf '%s\n' "$para" > "$repo/AGENTS.md"; printf '%s\n' "$para" > "$repo/CLAUDE.md"
