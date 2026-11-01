#!/usr/bin/env bash
# Builds a scratch project in a NEW, empty directory and puts it into the starting state of a trial scenario.
# Usage: bash tests/trials/setup.sh <new-dir> <scenario>
# Scenarios: interrupted-merge | refresh-from-base | claimed-elsewhere | race-claim-conflict | race-claim-benign | release | monorepo | lanes | replan
# Needs bash and git. Creates files only inside <new-dir>; deletes nothing.
set -eu
dir="${1:?usage: setup.sh <new-dir> <scenario>}"
scenario="${2:?scenario}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
[ ! -e "$dir" ] || [ -z "$(ls -A "$dir" 2>/dev/null)" ] || { echo "$dir must be new or empty"; exit 1; }
mkdir -p "$dir/.claude/skills" "$dir/tests"
dir="$(cd "$dir" && pwd)"
cp -r "$root"/skills/* "$dir/.claude/skills/"
cd "$dir"
g() { git -c user.email=t@t -c user.name=t "$@"; }
printf '__pycache__/\n' > .gitignore
printf '# minical\nA tiny calculator library. Tests: `python3 -m unittest discover -s tests`.\n' > README.md
printf 'def add(a, b):\n    return a + b\n' > calc.py
cat > tests/test_calc.py <<'PY'
import unittest, sys, os
sys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))
import calc
class CalcTest(unittest.TestCase):
    def test_add(self):
        self.assertEqual(calc.add(1, 2), 3)
if __name__ == "__main__":
    unittest.main()
PY
printf '# Changelog\n\nAll notable changes to this project will be documented in this file.\n\n## [Unreleased]\n' > CHANGELOG.md
head='# Active Backlog

## 🌳 Task Tree
'
git init -q -b main

case "$scenario" in
interrupted-merge)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · L · Add subtract and multiply to calc.py
  - Done when: both functions work; `python3 -m unittest discover -s tests`
  - State: branch todo/FEAT-001-subtract-multiply from main; next: build children
  - [ ] **FEAT-001.1** · S · Add subtract with a test
    - Done when: subtract works; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - [ ] **FEAT-001.2** · S · Add multiply with a test
    - Done when: multiply works; `python3 -m unittest tests.test_calc.CalcTest.test_multiply`' > TODO.md
  g add -A && g commit -q -m "init with claimed tree"
  g switch -q -c todo/FEAT-001-subtract-multiply
  g switch -q -c todo/FEAT-001.1-subtract-test
  printf '\ndef subtract(a, b):\n    return a - b\n' >> calc.py
  python3 - <<'PY'
p='tests/test_calc.py'
s=open(p).read().replace('if __name__','    def test_subtract(self):\n        self.assertEqual(calc.subtract(5, 3), 2)\nif __name__')
open(p,'w').write(s)
p='TODO.md'
s=open(p).read().replace('- [ ] **FEAT-001.1**','- [x] **FEAT-001.1**')
open(p,'w').write(s)
PY
  g add calc.py tests/test_calc.py TODO.md && g commit -q -m "feat(calc): add subtract" -m "Refs: FEAT-001.1"
  g switch -q todo/FEAT-001-subtract-multiply   # the session died here, before the merge
  ;;
refresh-from-base)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · S · Add a subtract function to calc.py with a test
  - Done when: subtract works; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - State: branch todo/FEAT-001-subtract from main; next: start FEAT-001' > TODO.md
  g add -A && g commit -q -m "init with claimed root"
  g switch -q -c todo/FEAT-001-subtract
  python3 - <<'PY'
p='TODO.md'
s=open(p).read().replace('- [ ] **FEAT-001**','- [/] **FEAT-001**').replace('branch todo/FEAT-001-subtract from main; next: start FEAT-001','attempts 0/3; branch todo/FEAT-001-subtract from main; next: build')
open(p,'w').write(s)
PY
  g add TODO.md && g commit -q -m "chore(backlog): start FEAT-001"
  # work in progress, uncommitted: implementation plus test
  printf '\ndef subtract(a, b):\n    return a - b\n' >> calc.py
  python3 - <<'PY'
p='tests/test_calc.py'
s=open(p).read().replace('if __name__','    def test_subtract(self):\n        self.assertEqual(calc.subtract(5, 3), 2)\nif __name__')
open(p,'w').write(s)
PY
  # meanwhile another tree landed on main
  g stash -q -u
  g switch -q main
  printf 'def twice(x):\n    return 2 * x\n' > extra.py
  printf 'import unittest, sys, os\nsys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))\nimport extra\nclass ExtraTest(unittest.TestCase):\n    def test_twice(self):\n        self.assertEqual(extra.twice(2), 4)\nif __name__ == "__main__":\n    unittest.main()\n' > tests/test_extra.py
  printf '\n### Added\n\n- **FEAT-009** (feat): Add twice() in extra.py. Validated: `python3 -m unittest tests.test_extra`.\n' >> CHANGELOG.md
  g add extra.py tests/test_extra.py CHANGELOG.md && g commit -q -m "feat(extra): add twice" -m "Refs: FEAT-009"
  g switch -q todo/FEAT-001-subtract
  g stash pop -q
  ;;
claimed-elsewhere)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · S · Add a subtract function to calc.py with a test
  - Done when: subtract works; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - State: branch todo/FEAT-001-subtract from main; next: start FEAT-001
- [ ] **FEAT-002** · P1 · S · Add a multiply function to calc.py with a test
  - Done when: multiply works; `python3 -m unittest tests.test_calc.CalcTest.test_multiply`' > TODO.md
  g add -A && g commit -q -m "init with one claimed root"
  g branch todo/FEAT-001-subtract
  ;;
race-claim-conflict|race-claim-benign)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · S · Add a subtract function to calc.py with a test
  - Done when: subtract works; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`' > TODO.md
  g add -A && g commit -q -m "init with one free root"
  # A hook plays the second session: the first time a todo/FEAT-001* branch is checked out, it moves main
  # underneath the agent, exactly between "branch created" and "base fast-forwarded".
  hook=.git/hooks/post-checkout
  cat > "$hook" <<HOOK
#!/bin/sh
gd=\$(git rev-parse --git-dir)
[ -e "\$gd/race-done" ] && exit 0
case "\$(git symbolic-ref -q --short HEAD)" in todo/FEAT-001*) ;; *) exit 0 ;; esac
: > "\$gd/race-done"
export GIT_INDEX_FILE="\$gd/race-index" GIT_AUTHOR_NAME=rival GIT_AUTHOR_EMAIL=r@r GIT_COMMITTER_NAME=rival GIT_COMMITTER_EMAIL=r@r
git read-tree main
if [ "$scenario" = race-claim-conflict ]; then
  blob=\$(git show main:TODO.md | awk '{print} /Done when:/ && !d {print "  - State: branch todo/FEAT-001-rival from main; next: start FEAT-001"; d=1}' | git hash-object -w --stdin)
  git update-index --cacheinfo 100644,\$blob,TODO.md
  c=\$(git commit-tree \$(git write-tree) -p main -m "chore(backlog): claim FEAT-001 on todo/FEAT-001-rival")
  git update-ref refs/heads/todo/FEAT-001-rival "\$c"
else
  blob=\$( (git show main:README.md; echo "Race note.") | git hash-object -w --stdin)
  git update-index --cacheinfo 100644,\$blob,README.md
  c=\$(git commit-tree \$(git write-tree) -p main -m "docs: touch readme (race)")
fi
git update-ref refs/heads/main "\$c"
rm -f "\$gd/race-index"
HOOK
  chmod +x "$hook"
  ;;
release)
  printf '%s\n' "$head" > TODO.md
  cat > CHANGELOG.md <<'CL'
# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added

- **FEAT-002** (feat): Add multiply to calc.py. Validated: `python3 -m unittest tests.test_calc`.

### Fixed

- **FIX-001** (fix): Handle float inputs in add. Validated: `python3 -m unittest tests.test_calc`.

## [0.1.0] - 2026-10-01

### Added

- **FEAT-001** (feat): Initial calculator with add. Validated: `python3 -m unittest tests.test_calc`.

[Unreleased]: https://github.com/example/minical/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/example/minical/releases/tag/v0.1.0
CL
  g add -A && g commit -q -m "init with a released 0.1.0 and unreleased work"
  g tag v0.1.0
  ;;
monorepo)
  # Two packages, a Makefile as the only documented test entry, a hand-written CHANGELOG without task IDs, no TODO.md.
  mkdir -p packages/api packages/web/tests
  mv calc.py packages/api/calc.py
  mv tests packages/api/tests
  printf 'def greet(name):\n    return "hello " + name\n' > packages/web/greet.py
  printf 'import unittest, sys, os\nsys.path.insert(0, os.path.dirname(os.path.dirname(__file__)))\nimport greet\nclass GreetTest(unittest.TestCase):\n    def test_greet(self):\n        self.assertEqual(greet.greet("a"), "hello a")\nif __name__ == "__main__":\n    unittest.main()\n' > packages/web/tests/test_greet.py
  printf 'test:\n\tcd packages/api && python3 -m unittest discover -s tests\n\tcd packages/web && python3 -m unittest discover -s tests\n' > Makefile
  printf '# minical monorepo\n\nPackages: `packages/api` (calculator) and `packages/web` (greeting).\n\n## Development\n\nRun `make test` to run every package test suite.\n' > README.md
  cat > CHANGELOG.md <<'CL'
# Changelog

## [Unreleased]

### Added
- Greeting helper in the web package.

## [1.2.0] - 2026-09-15

### Added
- Calculator add function.
CL
  g add -A && g commit -q -m "initial monorepo"
  ;;
lanes)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · S · Add subtract to calc.py
  - Done when: subtract(5, 3) returns 2; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - Links: Lane: math
- [ ] **FEAT-002** · P1 · S · Add shout to text.py
  - Done when: shout("hi") returns HI!; `python3 -m unittest tests.test_text.TextTest.test_shout`
  - Links: Lane: text' > TODO.md
  g add -A && g commit -q -m "init with two lanes"
  ;;
replan)
  mkdir -p docs/plans
  printf '# Plan\n\n## Goal\nA calculator with more operations.\n\n## Lanes\nmain: all work\n\n## Revisions\n' > docs/plans/PROJECT.md
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · S · Add subtract to calc.py
  - Done when: subtract(5, 3) returns 2; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - Links: Ref: docs/plans/PROJECT.md
- [ ] **FEAT-002** · P1 · S · Add a command line interface to the calculator
  - Done when: cli prints the sum; `python3 -m unittest tests.test_cli`
  - Links: Ref: docs/plans/PROJECT.md
- [ ] **FEAT-003** · P2 · S · Add a web dashboard for the calculator
  - Done when: dashboard renders; `python3 -m unittest tests.test_web`
  - Links: Ref: docs/plans/PROJECT.md' > TODO.md
  g add -A && g commit -q -m "init with a plan"
  ;;
*) echo "unknown scenario: $scenario"; exit 1 ;;
esac
echo "ready: $dir ($scenario) on branch $(git rev-parse --abbrev-ref HEAD)"
