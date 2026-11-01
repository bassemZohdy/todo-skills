#!/usr/bin/env bash
# Checks the repository left behind by a trial scenario. Read-only.
# Usage: bash tests/trials/assert.sh <dir> <scenario>
set -u
dir="${1:?usage: assert.sh <dir> <scenario>}"; scenario="${2:?scenario}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
lint="$root/skills/todo/scripts/todo-lint.sh"
cd "$dir" || exit 1
pass=0; fail=0
chk() { if eval "$2" >/dev/null 2>&1; then pass=$((pass+1)); printf 'PASS  %s\n' "$1"; else fail=$((fail+1)); printf 'FAIL  %s\n' "$1"; fi; }
branch_exists() { git rev-parse --verify -q "refs/heads/$1" >/dev/null; }
at() { git show "$1:$2"; }   # file at a ref

chk "no .pyc tracked" '[ "$(git ls-files | grep -c "\.pyc$")" = 0 ]'
chk "tests pass on the checked-out branch" 'python3 -m unittest discover -s tests'
chk "lint passes on the checked-out branch" 'bash "$lint" TODO.md CHANGELOG.md'

case "$scenario" in
interrupted-merge)
  r=todo/FEAT-001-subtract-multiply
  chk "child branch merged into the root branch" '[ "$(git branch --no-merged $r --list "todo/FEAT-001.1-*" | wc -l)" = 0 ]'
  chk "merged child branch deleted" '! git branch --list "todo/FEAT-001.1-*" | grep -q .'
  chk "root branch has subtract" 'at $r calc.py | grep -q "def subtract"'
  chk "FEAT-001.1 is [x] on the root branch" 'at $r TODO.md | grep -q "\[x\] \*\*FEAT-001.1\*\*"'
  chk "FEAT-001.2 untouched (still [ ], no branch)" 'at $r TODO.md | grep -q "\[ \] \*\*FEAT-001.2\*\*" && ! git branch --list "todo/FEAT-001.2-*" | grep -q .'
  chk "main untouched (no merge, no work)" '! at main calc.py | grep -q "def subtract"'
  chk "merge commit is --no-ff" 'git log --merges --oneline $r | grep -q .'
  ;;
refresh-from-base)
  r=todo/FEAT-001-subtract
  chk "base branch merged into the root branch" 'git merge-base --is-ancestor main $r'
  chk "CHANGELOG has FEAT-001 entry" 'at $r CHANGELOG.md | grep -q "FEAT-001"'
  chk "CHANGELOG keeps FEAT-009 from main" 'at $r CHANGELOG.md | grep -q "FEAT-009"'
  chk "FEAT-001 removed from TODO.md" '! at $r TODO.md | grep -q "FEAT-001"'
  chk "root committed on its branch" '[ -z "$(git status --porcelain | grep -v "^??")" ]'
  chk "main did not receive FEAT-001 (no --merge)" '! at main calc.py | grep -q "def subtract"'
  chk "full suite ran on merged tree: extra tests present and passing" 'git checkout -q $r && python3 -m unittest tests.test_extra tests.test_calc'
  ;;
claimed-elsewhere)
  chk "FEAT-001 untouched on its branch" '[ "$(git rev-parse todo/FEAT-001-subtract)" = "$(git rev-parse main~1 2>/dev/null || git rev-parse todo/FEAT-001-subtract)" ] || git diff --quiet main todo/FEAT-001-subtract -- calc.py'
  chk "a branch for FEAT-002 exists" 'git branch --list "todo/FEAT-002-*" | grep -q .'
  chk "main shows FEAT-002 claimed with its branch" 'at main TODO.md | grep -A3 "FEAT-002\*\*" | grep -q "State: branch todo/FEAT-002-"'
  chk "main still shows FEAT-001 claimed" 'at main TODO.md | grep -A3 "FEAT-001\*\*" | grep -q "State: branch todo/FEAT-001-subtract"'
  chk "no [/] on main" '! at main TODO.md | grep -q "^ *- \[/\]"'
  chk "claim commit touched only backlog files" '[ -z "$(git diff --name-only $(git rev-list --max-parents=0 HEAD | head -1)~0 main -- . | grep -v -e TODO.md -e CHANGELOG.md -e .claude -e README.md -e calc.py -e tests -e .gitignore)" ]'
  ;;
race-claim-conflict)
  chk "the rival's claim is on main" 'at main TODO.md | grep -q "State: branch todo/FEAT-001-rival"'
  chk "main's tip is still the rival's claim (not overwritten)" '[ "$(git log -1 --format=%s main)" = "chore(backlog): claim FEAT-001 on todo/FEAT-001-rival" ]'
  chk "the agent deleted its own root branch" '! git branch --list "todo/FEAT-001-*" | grep -v rival | grep -q .'
  chk "no subtract anywhere" '! git grep -q "def subtract" $(git for-each-ref --format="%(refname)" refs/heads)'
  chk "rival branch untouched" '[ "$(git log --oneline main..todo/FEAT-001-rival | wc -l)" = 0 ]'
  ;;
race-claim-benign)
  chk "the rival docs commit is kept on main" 'git log --format=%s main | grep -q "docs: touch readme (race)"'
  chk "main shows FEAT-001 claimed with the agent's branch" 'at main TODO.md | grep -A3 "FEAT-001\*\*" | grep -q "State: branch todo/FEAT-001-"'
  chk "agent's branch exists" 'git branch --list "todo/FEAT-001-*" | grep -q .'
  chk "main is an ancestor of the agent's branch" 'git merge-base --is-ancestor main $(git branch --list "todo/FEAT-001-*" | head -1 | tr -d "* ")'
  chk "claim is the only extra commit on main" '[ "$(git log --oneline $(git log --format=%H --grep="docs: touch readme" -1)..main | wc -l)" = 1 ]'
  ;;
release)
  chk "[Unreleased] is now empty (no entries)" '! at HEAD CHANGELOG.md | sed -n "/^## \[Unreleased\]/,/^## \[/p" | grep -q "^- "'
  chk "new version section exists with a date" 'at HEAD CHANGELOG.md | grep -Eq "^## \[0\.2\.0\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$"'
  chk "released entries moved under 0.2.0" 'at HEAD CHANGELOG.md | sed -n "/^## \[0\.2\.0\]/,/^## \[0\.1\.0\]/p" | grep -q "FEAT-002" && at HEAD CHANGELOG.md | sed -n "/^## \[0\.2\.0\]/,/^## \[0\.1\.0\]/p" | grep -q "FIX-001"'
  chk "0.1.0 section untouched" 'at HEAD CHANGELOG.md | sed -n "/^## \[0\.1\.0\]/,/^\[Unreleased\]/p" | grep -q "Initial calculator with add"'
  chk "compare links updated" 'at HEAD CHANGELOG.md | grep -q "^\[Unreleased\]: .*compare/v0.2.0...HEAD" && at HEAD CHANGELOG.md | grep -q "^\[0.2.0\]:"'
  chk "release commit touches only CHANGELOG.md" '[ "$(git diff --name-only HEAD~1 HEAD)" = "CHANGELOG.md" ] && [ "$(git log -1 --format=%s)" = "chore(release): 0.2.0" ]'
  chk "no tag created" '[ "$(git tag | tr "\n" " ")" = "v0.1.0 " ]'
  ;;
monorepo)
  chk "TODO.md exists with the task tree heading" '[ -f TODO.md ] && grep -q "^## .*Task Tree" TODO.md'
  chk "the human-written CHANGELOG entries survive" 'grep -q "Greeting helper in the web package" CHANGELOG.md && grep -q "## \[1.2.0\] - 2026-09-15" CHANGELOG.md'
  chk "a task mentions the api package power work" 'grep -qi "power" TODO.md || git log --all --format=%s | grep -qi power'
  chk "Done when / regression use a real command (make test or the api suite)" 'grep -E "make test|unittest" TODO.md || git log --all -p | grep -E "make test|unittest"'
  chk "nothing outside packages/api and backlog files changed on main" '[ -z "$(git diff --name-only $(git rev-list --max-parents=0 HEAD) main -- . | grep -v -e TODO.md -e CHANGELOG.md -e .claude)" ]'
  ;;
*) echo "unknown scenario"; exit 1 ;;
esac
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
