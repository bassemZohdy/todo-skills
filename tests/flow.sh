#!/usr/bin/env bash
# Tests tools/todo-flow.sh (FEAT-129), the optional lifecycle helper, in scratch git repositories: every command must
# leave the branches, commits and backlog lines the skills prescribe, and refuse an unusual case before it changes a file.
# Usage: bash tests/flow.sh      Prints PASS/FAIL lines and a count; tests/run.sh runs it and adds its counts to its own.
# Needs bash, git, awk, sed and grep. Works in a temporary directory that it removes at the end.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
flow="$root/tools/todo-flow.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  flow: %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  flow: %s\n' "$1"; }
g() { git -c user.email=t@example.invalid -c user.name=t "$@"; }

# mk <dir>: a project whose committed backlog holds the tree FEAT-002, with the root FEAT-001 added but not committed.
mk() {
  mkdir -p "$1/.todo" "$1/tests" && cd "$1" || exit 1
  git init -q -b main && git config core.autocrlf false && git config user.email t@example.invalid && git config user.name t
  cp "$flow" .todo/todo-flow.sh 2>/dev/null; cp "$root/tools/todo-lint.sh" .todo/todo-lint.sh
  printf '# calc\n\nTests: `python3 -m unittest discover -s tests`\n' > README.md
  printf 'def add(a, b):\n    return a + b\n' > calc.py
  printf '# Changelog\n\n## [Unreleased]\n' > CHANGELOG.md
  cat > TODO.md <<'MD'
# Active Backlog

## 🛤️ Lanes

- main: the default track

## 🌳 Task Tree

- [ ] **FEAT-002** · P1 · mid · XL · Add the Power, Root and Log functions for the calculator
  - Done when: all three are covered; `python3 -m unittest discover -s tests`
  - Links: Ref: docs/math.md
  - [ ] **FEAT-002.1** · low · L · Power function
    - Done when: power is covered; `python3 -m unittest tests.test_pow`
    - [ ] **FEAT-002.1.1** · low · The exponent parser
      - Done when: the parser is covered; `python3 -m unittest tests.test_exp`
  - [ ] **FEAT-002.2** · low · Root function
    - Done when: root is covered; `python3 -m unittest tests.test_root`
MD
  git add -A && git commit -qm "chore: project" || exit 1
  # shellcheck disable=SC2016  # the backticks are Markdown, not a command substitution
  awk '/^- \[ \] \*\*FEAT-002\*\*/ { print "- [ ] **FEAT-001** · P0 · low · Add a subtract function to `calc.py`"; print "  - Done when: subtract is covered; `python3 -m unittest discover -s tests`" } { print }' TODO.md > TODO.md.new && mv TODO.md.new TODO.md   # awk, not sed: BSD sed writes no newline for \n
}
crlf() { awk '{ printf "%s\r\n", $0 }' "$1" > "$1.new" && mv "$1.new" "$1"; }   # the file with CRLF line endings, on every sed
fl() { bash .todo/todo-flow.sh "$@" 2>&1; }
snap() { printf '%s|%s|%s|%s' "$(git rev-parse HEAD)" "$(git symbolic-ref --short HEAD)" "$(git for-each-ref --format='%(refname)%(objectname)' refs/heads | tr '\n' ' ')" "$(git status --porcelain | tr '\n' ' ')"; }
subjects() { git log --reverse --format=%s "$1" | tr '\n' '|'; }
lintok() { bash .todo/todo-lint.sh >/dev/null 2>&1; }

if [ ! -f "$flow" ]; then bad "tools/todo-flow.sh is missing"; printf '\n%d passed, %d failed\n' "$pass" "$fail"; exit 1; fi
# One read: an agent that reads a script 200 lines at a time needs a single call for it (a pilot run needed two for 258 lines).
[ "$(wc -l < "$flow")" -le 200 ] && ok "the helper is at most 200 lines, one read for an agent" || bad "the helper has $(wc -l < "$flow") lines, more than one 200-line read"

# start, leaf root: a pending root on the base is claimed, published by a fast-forward and started, in the prescribed commits.
mk "$tmp/a"; out="$(fl start FEAT-001 1)"; rc=$?
rb=todo/FEAT-001-add-subtract-function-calc
[ "$rc" -eq 0 ] && [ "$(git symbolic-ref --short HEAD)" = "$rb" ] && [ "$(subjects main~1..HEAD)" = "chore(backlog): claim FEAT-001 on $rb|chore(backlog): start FEAT-001|" ] \
  && ok "start of a leaf root makes the claim and the start commit on todo/<ID>-<slug>" || bad "start leaf root: rc=$rc $out $(subjects main~1..HEAD)"
[ "$(git log -1 --format=%s main)" = "chore(backlog): claim FEAT-001 on $rb" ] && [ "$(git diff --name-only main~1 main)" = "TODO.md" ] \
  && git show main:TODO.md | grep -A2 '^- \[ \] \*\*FEAT-001\*\*' | grep -qx "  - State: branch $rb from main; next: start FEAT-001" \
  && ok "the base gained exactly the claim commit, with the root still [ ] and its claim State" || bad "start leaf root: the base is $(git log -1 --format=%s main)"
grep -A2 '^- \[/\] \*\*FEAT-001\*\*' TODO.md | grep -qx "  - State: attempts 0/3; baseline 1 passing; branch $rb from main; next: read docs" && [ -z "$(git status --porcelain)" ] && lintok \
  && ok "the node is [/] with the start State, the tree is clean and the lint passes" || bad "start leaf root: $(grep -A2 'FEAT-001\*\*' TODO.md) / $(git status --porcelain)"
printf '%s\n' "$out" | grep -q "chore(backlog): start FEAT-001" && printf '%s\n' "$out" | grep -qx "now on $rb, tree clean; todo branches: $rb" && ok "start reports its commits, the checked-out branch, a clean tree and the todo branches" || bad "start report: $out"

# start, a grandchild of an unclaimed tree: claim with "build children", the branch chain, one start commit holding the ancestor State.
mk "$tmp/b"; git checkout -q -- TODO.md; out="$(fl start FEAT-002.1.1 none)"; rc=$?
r2=todo/FEAT-002-add-power-root-log; c1=todo/FEAT-002.1-power-function; c11=todo/FEAT-002.1.1-exponent-parser
[ "$rc" -eq 0 ] && [ "$(git symbolic-ref --short HEAD)" = "$c11" ] && git show-ref -q --verify "refs/heads/$r2" && git show-ref -q --verify "refs/heads/$c1" \
  && [ "$(subjects main~1..HEAD)" = "chore(backlog): claim FEAT-002 on $r2|chore(backlog): start FEAT-002.1.1|" ] && [ "$(git rev-parse "$r2")" = "$(git rev-parse main)" ] && [ "$(git rev-parse "$c1")" = "$(git rev-parse main)" ] \
  && ok "start of a grandchild claims the root and creates the branch chain root, child, grandchild" || bad "start grandchild: rc=$rc $out"
git show main:TODO.md | grep -qx "  - State: branch $r2 from main; next: build children" \
  && grep -qx "    - State: branch $c1 from $r2; next: build children" TODO.md \
  && grep -qx "      - State: attempts 0/3; baseline none; branch $c11 from $c1; next: read docs" TODO.md && grep -q '^    - \[/\] \*\*FEAT-002.1.1\*\*' TODO.md \
  && [ "$(grep -c '\[/\]' TODO.md)" -eq 1 ] && lintok && ok "the root and the new ancestor carry branch States and only the node is [/]" || bad "start grandchild States: $(grep State TODO.md)"

# start, a sibling in a claimed tree, from the root branch: only its branch and the start commit; the base does not move.
mk "$tmp/c"; git checkout -q -- TODO.md; fl start FEAT-002.2 3 >/dev/null
sed -i.bak -e 's/^  - \[\/\] \*\*FEAT-002.2\*\*/  - [x] **FEAT-002.2**/' -e '/^    - State: attempts/d' TODO.md && rm -f TODO.md.bak && g commit -qam "feat(calc): root function" && git switch -q "$r2" && g merge -q --no-ff -m "Merge FEAT-002.2 into FEAT-002" todo/FEAT-002.2-root-function && git branch -q -d todo/FEAT-002.2-root-function
mainsha="$(git rev-parse main)"; out="$(fl start FEAT-002.1.1 red: tests.test_exp.ExpTest.test_parse)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(git symbolic-ref --short HEAD)" = "$c11" ] && [ "$(git rev-parse main)" = "$mainsha" ] && [ "$(git log -1 --format=%s)" = "chore(backlog): start FEAT-002.1.1" ] && [ "$(git rev-parse "$c1")" = "$(git rev-parse "$r2")" ] \
  && grep -qx "      - State: attempts 0/3; baseline red: tests.test_exp.ExpTest.test_parse; branch $c11 from $c1; next: read docs" TODO.md && grep -qx "    - State: branch $c1 from $r2; next: build children" TODO.md \
  && ok "start in a claimed tree branches from the root branch and leaves the base alone" || bad "start in a claimed tree: rc=$rc $out"

# Refusals: exit 2 and nothing changed (HEAD, branches and the working tree are as before).
refused() {   # <label> <expected text> <args...>
  local label="$1" want="$2" before out rc; shift 2
  before="$(snap)"; out="$(fl "$@")"; rc=$?
  if [ "$rc" -eq 2 ] && [ "$(snap)" = "$before" ] && printf '%s' "$out" | grep -q "$want"; then ok "refused, nothing changed: $label"; else bad "refusal ($label): rc=$rc $out"; fi
}
mk "$tmp/d"
refused "an unknown task" "no task FEAT-009" start FEAT-009 1
refused "a baseline that is no count, none or red list" "baseline must be" start FEAT-001 green
refused "an unknown command" "unknown command" finish FEAT-001
refused "a parent whose children are still open" "has open children" start FEAT-002.1 1
git switch -q -c side; refused "an unclaimed tree started away from the base" "starts from main" start FEAT-001 1; git switch -q main
git branch todo/FEAT-001-old-name; refused "a root branch that already exists" "Existing root branch" start FEAT-001 1; git branch -q -D todo/FEAT-001-old-name
mkdir sub && (cd sub && bash ../.todo/todo-flow.sh start FEAT-001 1 >/dev/null 2>&1); [ $? -eq 2 ] && [ "$(git symbolic-ref --short HEAD)" = main ] && ok "refused outside the root of the main checkout" || bad "a run from a subfolder was not refused"
rmdir sub
fl start FEAT-001 1 >/dev/null
refused "a second start while a task is active" "another task is active" start FEAT-002.2 1
refused "a task that is not open" "is not an open" start FEAT-001 1
git switch -q main 2>/dev/null || git stash -q
refused "a tree claimed by another branch, from the base" "is claimed by" start FEAT-001 1

# A fast-forward that fails (the base moved after the claim commit) stops on the base with the claim branch kept, as git-flow-edge expects.
mk "$tmp/e"
printf '#!/bin/sh\ncase "$(git symbolic-ref --short HEAD)" in todo/*) git update-ref refs/heads/main "$(git -c user.email=r@example.invalid -c user.name=r commit-tree -p main -m "docs: rival" "main^{tree}")" ;; esac\n' > .git/hooks/post-commit; chmod +x .git/hooks/post-commit
out="$(fl start FEAT-001 1)"; rc=$?
[ "$rc" -eq 1 ] && [ "$(git symbolic-ref --short HEAD)" = main ] && [ "$(git log -1 --format=%s main)" = "docs: rival" ] && [ "$(git log --format=%s main..todo/FEAT-001-add-subtract-function-calc)" = "chore(backlog): claim FEAT-001 on todo/FEAT-001-add-subtract-function-calc" ] \
  && printf '%s' "$out" | grep -q "Failed fast-forward" && ok "a failed fast-forward stops on the base, keeps the claim branch and names the recovery rule" || bad "failed fast-forward: rc=$rc $out on $(git symbolic-ref --short HEAD)"

# A CRLF backlog keeps its line endings, and TODO_BASE and the README Base: line choose the base.
mk "$tmp/f"; crlf TODO.md; git switch -q -c develop; fl start FEAT-001 2 >/dev/null; rc=$?
[ "$rc" -eq 2 ] && ok "without a Base: line the base is main, so a start on develop is refused" || bad "base detection: rc=$rc"
out="$(TODO_BASE=develop bash .todo/todo-flow.sh start FEAT-001 2 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(git log -1 --format=%s develop)" = "chore(backlog): claim FEAT-001 on todo/FEAT-001-add-subtract-function-calc" ] && [ "$(tr -cd '\r' < TODO.md | wc -c)" -eq "$(tr -cd '\n' < TODO.md | wc -c)" ] \
  && grep -q "State: attempts 0/3; baseline 2 passing; branch todo/FEAT-001-add-subtract-function-calc from develop; next: read docs" TODO.md \
  && ok "TODO_BASE names the base, and a CRLF TODO.md keeps CRLF on every line" || bad "TODO_BASE or CRLF: rc=$rc $out"
mk "$tmp/g"; printf '\nBase: `trunk`\n' >> README.md; g commit -qam "docs: base"; git branch -m main trunk; out="$(fl start FEAT-001 4 passing)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(git log -1 --format=%s trunk)" = "chore(backlog): claim FEAT-001 on todo/FEAT-001-add-subtract-function-calc" ] && grep -q "baseline 4 passing; branch todo/FEAT-001-add-subtract-function-calc from trunk" TODO.md \
  && ok "the README Base: line names the base, and '<n> passing' is accepted as the baseline" || bad "README Base: rc=$rc $out"

# complete and drain (FEAT-129.2). A whole tree: a child, a grandchild, both integration steps, the root's drain with Includes.
body() { git log -1 --format=%b "$1" | grep . | tr '\n' '|'; }
parents() { git log -1 --format=%P "$1" | wc -w | tr -d ' '; }
mk "$tmp/h"; git checkout -q -- TODO.md; mkdir docs; printf '# Math\n' > docs/math.md; printf '# Changelog\n\n## [Unreleased]\n\n### Changed\n\n- **TASK-000** (chore): Old. Validated: `true`.\n\n## [0.1.0] - 2026-01-01\n\n### Added\n\n- first\n' > CHANGELOG.md; g add -A; g commit -qm "docs: math"
c2=todo/FEAT-002.2-root-function
fl start FEAT-002.2 2 >/dev/null; printf 'def root(a):\n    return a ** 0.5\n' >> calc.py; printf 'import unittest\n' > tests/test_root.py
out="$(fl complete FEAT-002.2 -m 'feat(calc): root function' -b 'Red: AttributeError: module calc has no attribute root' -b 'Reviewed: self, 0 findings fixed' -- calc.py tests/test_root.py)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(git symbolic-ref --short HEAD)" = "$r2" ] && [ "$(git log -1 --format=%s)" = "Merge FEAT-002.2 into FEAT-002" ] && [ "$(parents HEAD)" = 2 ] && ! git show-ref -q --verify "refs/heads/$c2" \
  && ok "complete of a child commits it, merges it --no-ff into its parent's branch and deletes its branch" || bad "complete child: rc=$rc $out"
[ "$(git log -1 --format=%s HEAD^2)" = "feat(calc): root function" ] && [ "$(body HEAD^2)" = "Refs: FEAT-002.2|Red: AttributeError: module calc has no attribute root|Reviewed: self, 0 findings fixed|" ] \
  && [ "$(git diff --name-only HEAD^2~1 HEAD^2 | tr '\n' ' ')" = "TODO.md calc.py tests/test_root.py " ] \
  && ok "the node commit has the given subject, the body Refs, Red, Reviewed, and the node's files plus TODO.md" || bad "complete child commit: $(body HEAD^2) / $(git diff --name-only HEAD^2~1 HEAD^2 | tr '\n' ' ')"
grep -q '^  - \[x\] \*\*FEAT-002.2\*\*' TODO.md && ! grep -A2 'FEAT-002.2\*\*' TODO.md | grep -q 'State:' && [ -z "$(git status --porcelain)" ] && lintok \
  && ok "the child is [x] without a State line, the tree is clean and the lint passes" || bad "complete child TODO: $(grep -A2 'FEAT-002.2\*\*' TODO.md)"
fl start FEAT-002.1.1 none >/dev/null; printf 'import unittest\n' > tests/test_exp.py; fl complete FEAT-002.1.1 -m 'feat(calc): exponent parser' -- tests/test_exp.py >/dev/null
[ "$(git symbolic-ref --short HEAD)" = "$c1" ] && [ "$(git log -1 --format=%s)" = "Merge FEAT-002.1.1 into FEAT-002.1" ] && ok "a grandchild merges into the child's branch" || bad "complete grandchild: on $(git symbolic-ref --short HEAD), $(git log -1 --format=%s)"
fl start FEAT-002.1 3 >/dev/null; out="$(fl complete FEAT-002.1 -m 'test(calc): power integration')"; rc=$?
[ "$rc" -eq 0 ] && [ "$(git symbolic-ref --short HEAD)" = "$r2" ] && [ "$(git log -1 --format=%s)" = "Merge FEAT-002.1 into FEAT-002" ] && [ "$(git diff --name-only HEAD^2~1 HEAD^2)" = "TODO.md" ] \
  && ok "an integration step without files commits TODO.md alone and merges into the root branch" || bad "complete integration step: rc=$rc $out"
fl start FEAT-002 3 >/dev/null; printf 'Power, root and log.\n' >> docs/math.md; mainsha="$(git rev-parse main)"
out="$(fl complete FEAT-002 -m 'docs(calc): describe the math functions' -- docs/math.md)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(git symbolic-ref --short HEAD)" = "$r2" ] && [ "$(git log -1 --format=%s)" = "docs(calc): describe the math functions" ] && grep -q '^- \[/\] \*\*FEAT-002\*\*' TODO.md && printf '%s' "$out" | grep -q "refresh: main brought nothing" \
  && ok "complete of a root commits it, keeps it [/] and reports a refresh that brought nothing" || bad "complete root: rc=$rc $out"
out="$(fl drain FEAT-002)"; rc=$?
# shellcheck disable=SC2016  # the backticks are Markdown
want='- **FEAT-002** (feat): Add the Power, Root and Log functions for the calculator. Ref: docs/math.md. Validated: `python3 -m unittest discover -s tests`. Docs: updated docs/math.md. Includes: FEAT-002.1, FEAT-002.1.1, FEAT-002.2.'
[ "$rc" -eq 0 ] && [ "$(sed -n 5,9p CHANGELOG.md | tr '\n' '|')" = "### Added||$want||### Changed|" ] && ok "drain writes the core's entry under a new Added heading placed before Changed, with Ref, Validated, Docs and Includes" || bad "drain entry: rc=$rc $(sed -n 3,9p CHANGELOG.md)"
! grep -q 'FEAT-002' TODO.md && [ "$(tail -1 TODO.md)" = "## 🌳 Task Tree" ] && lintok && [ "$(git log -1 --format=%s)" = "chore(backlog): drain FEAT-002" ] && [ "$(body HEAD)" = "Refs: FEAT-002|Includes: FEAT-002.1, FEAT-002.1.1, FEAT-002.2|" ] \
  && [ "$(git diff --name-only HEAD~1 HEAD | tr '\n' ' ')" = "CHANGELOG.md TODO.md " ] && ok "the drain removes the subtree and commits both backlog files with Refs and Includes" || bad "drain commit: $(body HEAD) / $(tail -3 TODO.md)"
[ "$(git symbolic-ref --short HEAD)" = "$r2" ] && [ "$(git rev-parse main)" = "$mainsha" ] && printf '%s' "$out" | grep -qF "git switch main && git merge --no-ff -m \"Merge FEAT-002 into main\" $r2 && git branch -d $r2" \
  && ok "without --merge the drain stays on the root branch and prints the merge commands" || bad "drain without --merge: $out"
printf '%s
' "$out" | grep -qxF "entry: $want" && ok "drain prints the CHANGELOG entry it wrote" || bad "drain does not print its entry: $out"

# A leaf FIX root: the base moves before the refresh, the entry goes under a new Fixed heading, and --merge lands it on the base.
mk "$tmp/i"; git checkout -q -- TODO.md
# shellcheck disable=SC2016
printf '%s\n' '- [ ] **FIX-003** · P0 · low · Reject a division by zero in `divide`.' '  - Done when: a zero divisor raises ValueError; `python3 -m unittest tests.test_div`; regression: `python3 -m unittest discover -s tests`' '  - Links: From: FEAT-002' >> TODO.md
printf '# Changelog\n\n## [Unreleased]\n\n### Changed\n\n- **TASK-000** (chore): Old. Validated: `true`.\n\n## [0.1.0] - 2026-01-01\n' > CHANGELOG.md; g add CHANGELOG.md; g commit -qm "docs: changelog" -- CHANGELOG.md
f3=todo/FIX-003-reject-division-by-zero
fl start FIX-003 1 >/dev/null; printf 'def divide(a, b):\n    return a / b\n' >> calc.py
git switch -q main 2>/dev/null; g stash -q; printf 'notes\n' > NOTES.md; g add NOTES.md; g commit -qm "docs: notes" -- NOTES.md; git switch -q "$f3"; g stash pop -q
out="$(fl complete FIX-003 -m 'fix(calc): reject a division by zero' -b 'Red: ZeroDivisionError' -- calc.py)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(git log -1 --format=%s)" = "Merge main into FIX-003" ] && [ -f NOTES.md ] && printf '%s' "$out" | grep -q "refresh: main brought changes" \
  && ok "complete of a root refreshes from a base that moved and says the checks must be rerun" || bad "complete root refresh: rc=$rc $out"
out="$(fl drain FIX-003 --merge)"; rc=$?
# shellcheck disable=SC2016
want='- **FIX-003** (fix): Reject a division by zero in `divide`. Validated: `python3 -m unittest tests.test_div`. From: FEAT-002.'
[ "$rc" -eq 0 ] && [ "$(sed -n 7,12p CHANGELOG.md | tr '\n' '|')" = "- **TASK-000** (chore): Old. Validated: \`true\`.||### Fixed||$want||" ] && [ "$(sed -n 13p CHANGELOG.md)" = "## [0.1.0] - 2026-01-01" ] \
  && ok "a FIX entry opens a Fixed heading after Changed, keeps one final period, leaves the regression command out and names From" || bad "drain FIX entry: rc=$rc $(sed -n 5,13p CHANGELOG.md)"
[ "$(git symbolic-ref --short HEAD)" = main ] && [ "$(git log -1 --format=%s)" = "Merge FIX-003 into main" ] && [ "$(parents HEAD)" = 2 ] && ! git show-ref -q --verify "refs/heads/$f3" && [ "$(git log -1 --format=%s HEAD^2)" = "chore(backlog): drain FIX-003" ] && [ "$(body HEAD^2)" = "Refs: FIX-003|" ] && ! grep -q FIX-003 TODO.md && grep -q 'FEAT-002' TODO.md && lintok \
  && ok "drain --merge merges the root --no-ff into the base, deletes its branch and leaves the other roots" || bad "drain --merge: on $(git symbolic-ref --short HEAD), $(git log -1 --format=%s)"
printf '%s
' "$out" | grep -qx "now on main, tree clean; todo branches: none" && ok "after --merge the report says the base is checked out, the tree is clean and no todo branch is left" || bad "drain --merge report: $out"

# A TASK root takes its type from -t, and its entry is the first item of an existing heading; a CRLF CHANGELOG keeps CRLF.
mk "$tmp/j"; git checkout -q -- TODO.md
# shellcheck disable=SC2016
printf '%s\n' '- [ ] **TASK-004** · P0 · low · Describe the calculator in the README' '  - Done when: the README names add; `python3 -m unittest discover -s tests`' >> TODO.md
printf '# Changelog\r\n\r\n## [Unreleased]\r\n\r\n### Changed\r\n\r\n- **TASK-000** (chore): Old. Validated: `true`.\r\n' > CHANGELOG.md; g add CHANGELOG.md; g commit -qm "docs: changelog" -- CHANGELOG.md
fl start TASK-004 1 >/dev/null; printf 'It adds.\n' >> README.md; fl complete TASK-004 -m 'docs(readme): describe the calculator' -- README.md >/dev/null; out="$(fl drain TASK-004 -t docs --merge)"; rc=$?
# shellcheck disable=SC2016
want='- **TASK-004** (docs): Describe the calculator in the README. Validated: `python3 -m unittest discover -s tests`. Docs: updated README.md.'
[ "$rc" -eq 0 ] && [ "$(tr -d '\r' < CHANGELOG.md | sed -n 5,8p | tr '\n' '|')" = "### Changed||$want|- **TASK-000** (chore): Old. Validated: \`true\`.|" ] && [ "$(tr -cd '\r' < CHANGELOG.md | wc -c)" -eq "$(tr -cd '\n' < CHANGELOG.md | wc -c)" ] \
  && ok "a TASK entry takes -t as its type, comes first under the existing Changed heading and keeps a CRLF CHANGELOG" || bad "drain TASK entry: rc=$rc $out $(tr -d '\r' < CHANGELOG.md | sed -n 5,8p)"

# A merge conflict in complete stops with the merge open, the state "Interrupted work" and git-flow-edge recover.
mk "$tmp/k"; git checkout -q -- TODO.md; fl start FEAT-002.2 2 >/dev/null
git switch -q "$r2"; printf 'def add(a, b):\n    return b + a\n' > calc.py; g commit -qm "refactor(calc): swap operands" -- calc.py; git switch -q "$c2"; printf 'def add(a, b):\n    return a + b + 0\n' > calc.py
out="$(fl complete FEAT-002.2 -m 'feat(calc): root function' -- calc.py)"; rc=$?
[ "$rc" -eq 1 ] && [ "$(git symbolic-ref --short HEAD)" = "$r2" ] && git rev-parse -q --verify MERGE_HEAD >/dev/null && git show-ref -q --verify "refs/heads/$c2" && git show "$c2:TODO.md" | grep -q '^  - \[x\] \*\*FEAT-002.2\*\*' && printf '%s' "$out" | grep -q "Git conflicts" \
  && ok "a conflicting child merge stops with the merge open, the child [x] on its branch and the recovery rule named" || bad "complete conflict: rc=$rc $out"

# Refusals of complete and drain.
mk "$tmp/l"; git checkout -q -- TODO.md
refused "complete of a task that is not active" "is not the active" complete FEAT-002.2 -m 'feat(calc): x'
fl start FEAT-002.2 2 >/dev/null
refused "complete without a subject" "needs -m" complete FEAT-002.2
refused "complete with a path that does not exist" "no such path" complete FEAT-002.2 -m 'feat(calc): x' -- nothing.py
refused "drain of a task that is not a root" "only a root" drain FEAT-002.2
git switch -q "$r2"; refused "complete away from the task's branch" "is not the active" complete FEAT-002.2 -m 'feat(calc): x'; git switch -q "$c2"
fl complete FEAT-002.2 -m 'feat(calc): root' >/dev/null
refused "drain of a root that is not active" "is not the active" drain FEAT-002
mk "$tmp/m"; fl start FEAT-001 1 >/dev/null
printf 'x = 1\n' >> calc.py; refused "drain with uncommitted work" "uncommitted" drain FEAT-001; git checkout -q -- calc.py
printf '# Changelog\n' > CHANGELOG.md; refused "drain without an Unreleased section" "Unreleased" drain FEAT-001; git checkout -q -- CHANGELOG.md
printf 'def sub(a, b):\n    return a - b\n' >> calc.py; fl complete FEAT-001 -m 'feat(calc): subtract' -- calc.py >/dev/null
git switch -q main; printf 'n\n' > N.md; g add N.md; g commit -qm "docs: n" -- N.md; git switch -q todo/FEAT-001-add-subtract-function-calc
out="$(fl drain FEAT-001 --merge)"; rc=$?
[ "$rc" -eq 1 ] && [ "$(git log -1 --format=%s)" = "chore(backlog): drain FEAT-001" ] && [ "$(git log -1 --format=%s main)" = "docs: n" ] && printf '%s' "$out" | grep -q "moved since the refresh" \
  && ok "drain --merge does not merge when the base moved after the refresh: it drains, stops and says to refresh and verify" || bad "drain --merge on a moved base: rc=$rc $out"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
