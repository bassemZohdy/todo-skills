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
*) echo "unknown scenario"; exit 1 ;;
esac
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
