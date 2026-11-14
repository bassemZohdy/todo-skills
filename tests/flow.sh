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
  sed -i.bak 's/^- \[ \] \*\*FEAT-002\*\*/- [ ] **FEAT-001** · P0 · low · Add a subtract function to `calc.py`\n  - Done when: subtract is covered; `python3 -m unittest discover -s tests`\n&/' TODO.md && rm -f TODO.md.bak
}
fl() { bash .todo/todo-flow.sh "$@" 2>&1; }
snap() { printf '%s|%s|%s|%s' "$(git rev-parse HEAD)" "$(git symbolic-ref --short HEAD)" "$(git for-each-ref --format='%(refname)%(objectname)' refs/heads | tr '\n' ' ')" "$(git status --porcelain | tr '\n' ' ')"; }
subjects() { git log --reverse --format=%s "$1" | tr '\n' '|'; }
lintok() { bash .todo/todo-lint.sh >/dev/null 2>&1; }

if [ ! -f "$flow" ]; then bad "tools/todo-flow.sh is missing"; printf '\n%d passed, %d failed\n' "$pass" "$fail"; exit 1; fi

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
printf '%s\n' "$out" | grep -q "chore(backlog): start FEAT-001" && printf '%s\n' "$out" | grep -qx "on $rb" && ok "start reports its commits and the checked-out branch" || bad "start report: $out"

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
mk "$tmp/f"; sed -i.bak 's/$/\r/' TODO.md && rm -f TODO.md.bak; git switch -q -c develop; fl start FEAT-001 2 >/dev/null; rc=$?
[ "$rc" -eq 2 ] && ok "without a Base: line the base is main, so a start on develop is refused" || bad "base detection: rc=$rc"
out="$(TODO_BASE=develop bash .todo/todo-flow.sh start FEAT-001 2 2>&1)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(git log -1 --format=%s develop)" = "chore(backlog): claim FEAT-001 on todo/FEAT-001-add-subtract-function-calc" ] && [ "$(tr -cd '\r' < TODO.md | wc -c)" -eq "$(tr -cd '\n' < TODO.md | wc -c)" ] \
  && grep -q "State: attempts 0/3; baseline 2 passing; branch todo/FEAT-001-add-subtract-function-calc from develop; next: read docs" TODO.md \
  && ok "TODO_BASE names the base, and a CRLF TODO.md keeps CRLF on every line" || bad "TODO_BASE or CRLF: rc=$rc $out"
mk "$tmp/g"; printf '\nBase: `trunk`\n' >> README.md; g commit -qam "docs: base"; git branch -m main trunk; out="$(fl start FEAT-001 4 passing)"; rc=$?
[ "$rc" -eq 0 ] && [ "$(git log -1 --format=%s trunk)" = "chore(backlog): claim FEAT-001 on todo/FEAT-001-add-subtract-function-calc" ] && grep -q "baseline 4 passing; branch todo/FEAT-001-add-subtract-function-calc from trunk" TODO.md \
  && ok "the README Base: line names the base, and '<n> passing' is accepted as the baseline" || bad "README Base: rc=$rc $out"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
