#!/usr/bin/env bash
# Builds a scratch project in a NEW, empty directory and puts it into the starting state of a trial scenario.
# Usage: bash tests/trials/setup.sh <new-dir> <scenario>
# Scenarios: interrupted-merge | refresh-from-base | claimed-elsewhere | race-claim-conflict | race-claim-benign | release-ask | release |
#   monorepo | lanes | replan | ci-github | ci-local | happy-path | baseline-red | no-git | add-fix | update-block | update-drop |
#   status-readonly | report | blocked-sibling | ts-lifecycle | java-lifecycle | multi-module
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
[ "$scenario" = no-git ] || git init -q -b main

case "$scenario" in
interrupted-merge)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · mid · Add subtract and multiply to calc.py
  - Done when: both functions work; `python3 -m unittest discover -s tests`
  - State: branch todo/FEAT-001-subtract-multiply from main; next: build children
  - [ ] **FEAT-001.1** · low · Add subtract with a test
    - Done when: subtract works; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - [ ] **FEAT-001.2** · low · Add multiply with a test
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
  g add calc.py tests/test_calc.py TODO.md && g commit -q -m "feat(calc): add subtract" -m "Refs: FEAT-001.1
Reviewed: self, 0 findings fixed"
  g switch -q todo/FEAT-001-subtract-multiply   # the session died here, before the merge
  ;;
refresh-from-base)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add a subtract function to calc.py with a test
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
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add a subtract function to calc.py with a test
  - Done when: subtract works; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - State: branch todo/FEAT-001-subtract from main; next: start FEAT-001
- [ ] **FEAT-002** · P1 · low · Add a multiply function to calc.py with a test
  - Done when: multiply works; `python3 -m unittest tests.test_calc.CalcTest.test_multiply`' > TODO.md
  g add -A && g commit -q -m "init with one claimed root"
  g branch todo/FEAT-001-subtract
  ;;
race-claim-conflict|race-claim-benign)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add a subtract function to calc.py with a test
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
release|release-ask)
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
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add subtract to calc.py
  - Done when: subtract(5, 3) returns 2; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - Links: Lane: math
- [ ] **FEAT-002** · P1 · low · Add shout to text.py
  - Done when: shout("hi") returns HI!; `python3 -m unittest tests.test_text.TextTest.test_shout`
  - Links: Lane: text' > TODO.md
  g add -A && g commit -q -m "init with two lanes"
  ;;
replan)
  mkdir -p docs/plans
  printf '# Plan\n\n## Goal\nA calculator with more operations.\n\n## Lanes\nmain: all work\n\n## Revisions\n' > docs/plans/PROJECT.md
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add subtract to calc.py
  - Done when: subtract(5, 3) returns 2; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - Links: Ref: docs/plans/PROJECT.md
- [ ] **FEAT-002** · P1 · low · Add a command line interface to the calculator
  - Done when: cli prints the sum; `python3 -m unittest tests.test_cli`
  - Links: Ref: docs/plans/PROJECT.md
- [ ] **FEAT-003** · P2 · low · Add a web dashboard for the calculator
  - Done when: dashboard renders; `python3 -m unittest tests.test_web`
  - Links: Ref: docs/plans/PROJECT.md' > TODO.md
  g add -A && g commit -q -m "init with a plan"
  ;;
ci-github|ci-local)
  printf '%s\n' "$head" > TODO.md
  g add -A && g commit -q -m "init"
  [ "$scenario" = ci-github ] && git remote add origin https://github.com/example/minical.git
  ;;
happy-path)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add subtract to calc.py
  - Done when: subtract(5, 3) returns 2; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`' > TODO.md
  g add -A && g commit -q -m "init with one free root"
  ;;
baseline-red)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add subtract to calc.py
  - Done when: subtract(5, 3) returns 2; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`' > TODO.md
  printf 'def add(a, b):\n    return a - b\n' > calc.py   # a bug already on main: the baseline is red
  g add -A && g commit -q -m "init with a red baseline"
  ;;
no-git)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add subtract to calc.py
  - Done when: subtract(5, 3) returns 2; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`' > TODO.md
  ;;
add-fix)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add subtract to calc.py
  - Done when: subtract(5, 3) returns 2; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`' > TODO.md
  g add -A && g commit -q -m "init with one root"
  ;;
update-block|update-drop|status-readonly|report)
  mkdir -p docs/plans
  printf '# Plan\n\n## Goal\nA calculator with more operations.\n\n## Lanes\nmain: all work\n\n## Revisions\n' > docs/plans/PROJECT.md
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add subtract to calc.py
  - Done when: subtract(5, 3) returns 2; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
- [ ] **FEAT-002** · P2 · low · Add round_to to calc.py <with> "quotes" & </script> in the title
  - Done when: round_to(2.345, 2) returns 2.35; `python3 -m unittest tests.test_calc.CalcTest.test_round_to`
  - Links: From: FEAT-000' > TODO.md
  printf '# Changelog\n\nAll notable changes to this project will be documented in this file.\n\n## [Unreleased]\n\n### Added\n\n- **FEAT-000** (feat): Add add() to calc.py. Validated: `python3 -m unittest tests.test_calc`.\n' > CHANGELOG.md
  g add -A && g commit -q -m "init with two roots"
  ;;
blocked-sibling)
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · mid · Add subtract and multiply to calc.py
  - Done when: both functions work; `python3 -m unittest discover -s tests`
  - State: branch todo/FEAT-001-subtract-multiply from main; next: build children
  - [ ] **FEAT-001.1** · low · Add subtract with a test
    - Done when: subtract works; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`
  - [ ] **FEAT-001.2** · low · Add multiply with a test
    - Done when: multiply works; `python3 -m unittest tests.test_calc.CalcTest.test_multiply`' > TODO.md
  g add -A && g commit -q -m "init with claimed tree"
  g switch -q -c todo/FEAT-001-subtract-multiply
  g switch -q -c todo/FEAT-001.1-subtract-test
  python3 - <<'PY2'
p='TODO.md'
s=open(p).read().replace('- [ ] **FEAT-001.1** · low · Add subtract with a test\n    - Done when: subtract works; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`',
 '- [!] **FEAT-001.1** · low · Add subtract with a test\n    - Done when: subtract works; `python3 -m unittest tests.test_calc.CalcTest.test_subtract`\n    - Blocked: the product owner must decide how subtract rounds → n/a (manual) → resolve this, then run /todo-update FEAT-001.1 --status ready')
open(p,'w').write(s)
PY2
  g add TODO.md && g commit -q -m "chore(backlog): block FEAT-001.1"
  g switch -q todo/FEAT-001-subtract-multiply   # the parent's branch still shows FEAT-001.1 as [ ]
  ;;
ts-lifecycle)
  # TypeScript (Node 22, node:test with type stripping), no dependencies. One root with two children.
  rm -rf calc.py tests
  mkdir -p src tests
  printf '__pycache__/\nnode_modules/\ntarget/\n' > .gitignore
  printf '# minits\nA tiny TypeScript calculator. Tests: `npm test`.\n' > README.md
  printf '{\n  "name": "minits",\n  "version": "1.0.0",\n  "type": "module",\n  "scripts": { "test": "node --experimental-strip-types --test \\"tests/*.test.ts\\"" }\n}\n' > package.json
  printf 'export function add(a: number, b: number): number {\n  return a + b;\n}\n' > src/calc.ts
  printf 'import { test } from "node:test";\nimport assert from "node:assert/strict";\nimport { add } from "../src/calc.ts";\n\ntest("add", () => {\n  assert.equal(add(1, 2), 3);\n});\n' > tests/add.test.ts
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · mid · Add subtract and multiply to src/calc.ts
  - Done when: both functions work; `npm test`
  - [ ] **FEAT-001.1** · low · Add subtract with a test
    - Done when: subtract works; `node --experimental-strip-types --test tests/subtract.test.ts`
  - [ ] **FEAT-001.2** · low · Add multiply with a test
    - Done when: multiply works; `node --experimental-strip-types --test tests/multiply.test.ts`' > TODO.md
  g add -A && g commit -q -m "init typescript project"
  ;;
java-lifecycle)
  # Java 17 + Maven + JUnit 5 (needs Maven Central the first time). One root with two children.
  rm -rf calc.py tests
  mkdir -p src/main/java/mini src/test/java/mini
  printf '__pycache__/\nnode_modules/\ntarget/\n' > .gitignore
  printf '# minijava\nA tiny Java calculator. Tests: `mvn -B test`.\n' > README.md
  cat > pom.xml <<'XML'
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>mini</groupId><artifactId>minijava</artifactId><version>1.0.0</version>
  <properties><maven.compiler.source>17</maven.compiler.source><maven.compiler.target>17</maven.compiler.target><project.build.sourceEncoding>UTF-8</project.build.sourceEncoding></properties>
  <dependencies><dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter</artifactId><version>5.10.2</version><scope>test</scope></dependency></dependencies>
  <build><plugins><plugin><artifactId>maven-surefire-plugin</artifactId><version>3.2.5</version></plugin></plugins></build>
</project>
XML
  printf 'package mini;\n\npublic class Calc {\n    public static int add(int a, int b) {\n        return a + b;\n    }\n}\n' > src/main/java/mini/Calc.java
  printf 'package mini;\n\nimport static org.junit.jupiter.api.Assertions.assertEquals;\nimport org.junit.jupiter.api.Test;\n\nclass AddTest {\n    @Test\n    void adds() {\n        assertEquals(3, Calc.add(1, 2));\n    }\n}\n' > src/test/java/mini/AddTest.java
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · mid · Add subtract and multiply to Calc.java
  - Done when: both methods work; `mvn -B test`
  - [ ] **FEAT-001.1** · low · Add subtract with a test class SubtractTest
    - Done when: subtract works; `mvn -B test -Dtest=SubtractTest -Dsurefire.failIfNoSpecifiedTests=true`
  - [ ] **FEAT-001.2** · low · Add multiply with a test class MultiplyTest
    - Done when: multiply works; `mvn -B test -Dtest=MultiplyTest -Dsurefire.failIfNoSpecifiedTests=true`' > TODO.md
  g add -A && g commit -q -m "init java project"
  ;;
multi-module)
  # Maven multi-module build, two independent modules = two lanes, one reactor build as the regression suite.
  rm -rf calc.py tests
  printf '__pycache__/\nnode_modules/\ntarget/\n' > .gitignore
  printf '# minimulti\nTwo Maven modules, `core` (math) and `text`. Tests: `mvn -B test` from the root runs both.\n' > README.md
  cat > pom.xml <<'XML'
<project xmlns="http://maven.apache.org/POM/4.0.0">
  <modelVersion>4.0.0</modelVersion>
  <groupId>mini</groupId><artifactId>minimulti</artifactId><version>1.0.0</version><packaging>pom</packaging>
  <modules><module>core</module><module>text</module></modules>
  <properties><maven.compiler.source>17</maven.compiler.source><maven.compiler.target>17</maven.compiler.target><project.build.sourceEncoding>UTF-8</project.build.sourceEncoding></properties>
  <dependencies><dependency><groupId>org.junit.jupiter</groupId><artifactId>junit-jupiter</artifactId><version>5.10.2</version><scope>test</scope></dependency></dependencies>
  <build><plugins><plugin><artifactId>maven-surefire-plugin</artifactId><version>3.2.5</version></plugin></plugins></build>
</project>
XML
  for m in core text; do
    mkdir -p $m/src/main/java/mini/$m $m/src/test/java/mini/$m
    printf '<project xmlns="http://maven.apache.org/POM/4.0.0">\n  <modelVersion>4.0.0</modelVersion>\n  <parent><groupId>mini</groupId><artifactId>minimulti</artifactId><version>1.0.0</version></parent>\n  <artifactId>%s</artifactId>\n</project>\n' "$m" > $m/pom.xml
  done
  printf 'package mini.core;\n\npublic class Calc {\n    public static int add(int a, int b) {\n        return a + b;\n    }\n}\n' > core/src/main/java/mini/core/Calc.java
  printf 'package mini.core;\n\nimport static org.junit.jupiter.api.Assertions.assertEquals;\nimport org.junit.jupiter.api.Test;\n\nclass AddTest {\n    @Test\n    void adds() {\n        assertEquals(3, Calc.add(1, 2));\n    }\n}\n' > core/src/test/java/mini/core/AddTest.java
  printf 'package mini.text;\n\npublic class Text {\n    public static String upper(String s) {\n        return s.toUpperCase();\n    }\n}\n' > text/src/main/java/mini/text/Text.java
  printf 'package mini.text;\n\nimport static org.junit.jupiter.api.Assertions.assertEquals;\nimport org.junit.jupiter.api.Test;\n\nclass UpperTest {\n    @Test\n    void uppers() {\n        assertEquals("A", Text.upper("a"));\n    }\n}\n' > text/src/test/java/mini/text/UpperTest.java
  printf '%s\n%s\n' "$head" '- [ ] **FEAT-001** · P1 · low · Add subtract to the core module (Calc.java)
  - Done when: subtract(5, 3) returns 2; `mvn -B test -pl core -Dtest=SubtractTest -Dsurefire.failIfNoSpecifiedTests=true`; regression: `mvn -B test`
  - Links: Lane: core
- [ ] **FEAT-002** · P1 · low · Add shout to the text module (Text.java)
  - Done when: shout("hi") returns HI!; `mvn -B test -pl text -Dtest=ShoutTest -Dsurefire.failIfNoSpecifiedTests=true`; regression: `mvn -B test`
  - Links: Lane: text' > TODO.md
  g add -A && g commit -q -m "init multi-module project"
  ;;
*) echo "unknown scenario: $scenario"; exit 1 ;;
esac
# Snapshot of the starting state for the read-only checks in assert.sh (inside .git, never tracked).
if [ -d .git ]; then git rev-parse HEAD > .git/trial-start; git for-each-ref --format='%(refname) %(objectname)' > .git/trial-refs; fi
echo "ready: $dir ($scenario) on branch $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo none)"
