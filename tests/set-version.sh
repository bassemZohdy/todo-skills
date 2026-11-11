#!/usr/bin/env bash
# set-version.sh - set the release version everywhere it is stated (FEAT-088). A developer tool, not part of the plugin.
# Usage: bash tests/set-version.sh X.Y.Z [repo-root]
# Sets: "version" in plugin/.claude-plugin/plugin.json and plugin/.codex-plugin/plugin.json, every "version X.Y.Z" statement in
# README.md, todo_skills_version in each tools/todo-*.sh, and the vendored .todo/todo-lint.sh (a copy of tools/todo-lint.sh).
# Does not touch CHANGELOG.md (/todo-release writes the heading), tag, commit or push. Run bash tests/run.sh afterwards.
set -eu
v="${1:-}"
case "$v" in
  [0-9]*.[0-9]*.[0-9]*) ;;
  *) echo "usage: set-version.sh X.Y.Z [repo-root]" >&2; exit 2 ;;
esac
if printf '%s' "$v" | grep -qvE '^[0-9]+\.[0-9]+\.[0-9]+$'; then echo "not a version: $v (expected X.Y.Z)" >&2; exit 2; fi
root="${2:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
for f in plugin/.claude-plugin/plugin.json plugin/.codex-plugin/plugin.json README.md; do
  [ -f "$root/$f" ] || { echo "missing $f in $root" >&2; exit 2; }
done
for f in plugin/.claude-plugin/plugin.json plugin/.codex-plugin/plugin.json; do
  sed -E -i "s/(\"version\" *: *\")[0-9]+\.[0-9]+\.[0-9]+(\")/\1$v\2/" "$root/$f"
done
sed -E -i "s/([Vv]ersion )[0-9]+\.[0-9]+\.[0-9]+/\1$v/g" "$root/README.md"
for f in "$root"/tools/todo-*.sh; do
  [ -f "$f" ] || continue
  sed -E -i "s/^(todo_skills_version=\")[^\"]*(\")/\1$v\2/" "$f"
done
[ ! -f "$root/.todo/todo-lint.sh" ] || cp "$root/tools/todo-lint.sh" "$root/.todo/todo-lint.sh"
echo "set $v in the manifests, README.md and the stamps under $root"
