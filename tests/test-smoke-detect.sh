#!/usr/bin/env bash
# FEAT-148.2: /todo-init detects a smoke command the project already has (a pytest marker, a Maven profile, an npm script, a make
# target) and offers a `Smoke:` README line only for a detected command, written on the user's yes. The skill is Markdown, so
# this checks the text an agent follows; the load budget of the init row is checked by tests/run.sh.
# Usage: bash tests/test-smoke-detect.sh      Prints PASS and FAIL lines and a count; tests/run.sh runs it and adds its counts.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
init="$root/plugin/skills/todo-init/SKILL.md"
cmds="$root/docs/COMMANDS.md"
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  smoke-detect: %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  smoke-detect: %s\n' "$1"; }
has() { # has <file> <pattern> <name>
  if [ -f "$1" ] && tr -d '\r' < "$1" | grep -Eq -- "$2"; then ok "$3"; else bad "$3"; fi
}

ref="$root/plugin/skills/todo/reference/test-tiers.md"
core="$root/plugin/skills/todo/SKILL.md"
has "$init" 'Smoke:' "todo-init names the Smoke: README line"
has "$init" 'With no `Smoke:` line.*reference/test-tiers\.md' "todo-init looks only when README has no Smoke: line, and points to reference/test-tiers.md"
has "$init" 'only for a detected command' "offers the line only for a detected command"
has "$init" "Smoke:.*on the user's yes" "writes the line only on the user's yes"
has "$init" 'Smoke:.*never invent' "never invents a smoke command"
has "$init" 'Smoke:.*backlog file' "calls the Smoke: line a backlog file"
has "$init" 'Apart from the optional `Tests:` and `Smoke:` lines' "the do-not-persist rule allows the Smoke: line"
has "$ref" '^## Detecting a smoke command' "test-tiers.md has the detection section"
has "$ref" 'pytest -m smoke' "detects a pytest marker (pytest -m smoke)"
has "$ref" 'grep -rl mark\.smoke' "a pytest marker counts only when a test uses it"
has "$ref" 'mvn test -Psmoke' "detects a Maven profile (mvn test -Psmoke)"
has "$ref" 'package\.json.*run <name>' "detects an npm-style script named smoke or test:smoke"
has "$ref" 'make smoke' "detects a make target named smoke"
has "$ref" 'first match wins' "the first match wins"
has "$ref" 'Command safety' "reads the detected script first (command safety)"
has "$core" 'Tests:`, `Base:` and `Smoke:` lines written by a todo' "the core lists the Smoke: line among the backlog files"
has "$cmds" 'Smoke:' "docs/COMMANDS.md describes the Smoke: line under /todo-init"
has "$root/docs/FILES.md" 'Tests:`, `Base:` and `Smoke:` lines' "docs/FILES.md lists the Smoke: line among the backlog files"

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
