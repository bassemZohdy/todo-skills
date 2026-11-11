#!/usr/bin/env bash
# Checks the repository left behind by a trial scenario. Read-only.
# Usage: bash tests/trials/assert.sh <dir> <scenario>
set -u
dir="${1:?usage: assert.sh <dir> <scenario>}"; scenario="${2:?scenario}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
lint="$root/tools/todo-lint.sh"
cd "$dir" || exit 1
# the git directory: .git is a file pointing elsewhere when run-codex.sh moved it out of the sandboxed workspace
gd="$(git rev-parse --git-common-dir 2>/dev/null || true)"
case "$gd" in ""|/*|?:*) ;; *) gd="$dir/$gd" ;; esac
pass=0; fail=0
chk() { if eval "$2" >/dev/null 2>&1; then pass=$((pass+1)); printf 'PASS  %s\n' "$1"; else fail=$((fail+1)); printf 'FAIL  %s\n' "$1"; fi; }
branch_exists() { git rev-parse --verify -q "refs/heads/$1" >/dev/null; }
at() { git show "$1:$2"; }   # file at a ref

start="$(cat "$gd/trial-start" 2>/dev/null || true)"
unchanged() { [ "$(git rev-parse HEAD)" = "$start" ] && [ "$(git for-each-ref --format='%(refname) %(objectname)')" = "$(cat "$gd/trial-refs")" ]; }
clean() { [ -z "$(git status --porcelain)" ]; }
old="$start $(cut -d' ' -f2 "$gd/trial-refs" 2>/dev/null)"   # everything reachable at the start is not the agent's
new_commits() { git log --format=%H --all --not $old; }
lane_ev() { bash "$root/tests/trials/lane-evidence.sh" "$dir"; }                       # hook log written by setup.sh, see lane-evidence.sh
lane_worktrees() { [ "$(lane_ev | sed -n 's/^worktrees: //p')" -ge 2 ]; }               # at least two lane worktrees really saw work
lane_info() { printf 'INFO  lane execution: %s\n' "$(lane_ev | sed -n 's/^execution: //p')"; }
entry() { grep -Eq "^- \*\*$1\*\* \((feat|fix|[a-z]+)\): [^ ].*\. Validated: \`[^\`]+\`\.( .*)?$"; }  # core CHANGELOG entry format

if [ -e .git ]; then
  chk "no .pyc tracked" '[ "$(git ls-files | grep -c "\.pyc$")" = 0 ]'
  chk "no tag created" '[ "$(git tag | grep -vc "^v0\.1\.0$")" = 0 ]'
  chk "new commit subjects are conventional or merges" '[ -z "$(git log --format=%s --all --not $old | grep -Ev "^((feat|fix|chore|docs|refactor|test|perf|build|ci|style)(\([a-z0-9._/-]+\))?!?: [^A-Z]|Merge )")" ]'
  chk "node commits carry Refs: and Reviewed: trailers" '(for c in $(git log --format=%H --all --not $old --grep="^\(feat\|fix\|refactor\|test\|perf\)"); do git log -1 --format=%B $c | grep -q "^Refs: " && git log -1 --format=%B $c | grep -q "^Reviewed: " || exit 1; done)'
  chk "merge commits use the skill message" '[ -z "$(git log --merges --format=%s --all --not $old | grep -Ev "^Merge [A-Z]+-[0-9.]+ into ([A-Z]+-[0-9.]+|main)$|^Merge main into [A-Z]+-[0-9]+$|^Merge branch .main. of ")" ]'
fi
if [ "$scenario" != baseline-red ]; then
  if [ -f Makefile ]; then chk "tests pass on the checked-out branch" 'make test'
  elif [ -f package.json ]; then chk "tests pass on the checked-out branch" 'npm test'
  elif [ -f pom.xml ]; then chk "tests pass on the checked-out branch" 'mvn -q -B test'
  else chk "tests pass on the checked-out branch" 'python3 -m unittest discover -s tests'; fi
fi
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
  chk "merge commit is --no-ff with the skill message" '[ "$(git log --merges --format=%s $r -1)" = "Merge FEAT-001.1 into FEAT-001" ]'
  chk "still on the root branch, tree clean" '[ "$(git branch --show-current)" = $r ] && clean'
  chk "exactly one new commit (the merge)" '[ "$(new_commits | wc -l)" = 1 ]'
  ;;
refresh-from-base)
  r=todo/FEAT-001-subtract
  chk "base branch merged into the root branch" 'git merge-base --is-ancestor main $r'
  chk "CHANGELOG has FEAT-001 entry" 'at $r CHANGELOG.md | grep -q "FEAT-001"'
  chk "CHANGELOG keeps FEAT-009 from main" 'at $r CHANGELOG.md | grep -q "FEAT-009"'
  chk "FEAT-001 removed from TODO.md" '! at $r TODO.md | grep -q "FEAT-001"'
  chk "root committed on its branch" '[ -z "$(git status --porcelain | grep -v "^??")" ]'
  chk "main did not receive FEAT-001 (no --merge)" '! at main calc.py | grep -q "def subtract"'
  chk "refresh merge message is Merge main into FEAT-001" 'git log --merges --format=%s $r | grep -qx "Merge main into FEAT-001"'
  chk "CHANGELOG entry has the core format" 'at $r CHANGELOG.md | entry FEAT-001'
  chk "FEAT-001 entry is under Added, above FEAT-009" 'at $r CHANGELOG.md | sed -n "/^### Added/,/^### /p" | grep -o "FEAT-00[19]" | head -2 | tr "\n" " " | grep -qx "FEAT-001 FEAT-009 "'
  chk "drain commit is the branch tip" '[ "$(git log -1 --format=%s $r)" = "chore(backlog): drain FEAT-001" ]'
  chk "full suite ran on merged tree: extra tests present and passing" 'git checkout -q $r && python3 -m unittest tests.test_extra tests.test_calc'
  ;;
claimed-elsewhere)
  chk "FEAT-001's branch untouched" '[ "$(git rev-parse todo/FEAT-001-subtract)" = "$start" ]'
  chk "a branch for FEAT-002 exists" 'git branch --list "todo/FEAT-002-*" | grep -q .'
  chk "main shows FEAT-002 claimed with its branch" 'at main TODO.md | grep -A3 "FEAT-002\*\*" | grep -q "State: branch todo/FEAT-002-"'
  chk "main still shows FEAT-001 claimed" 'at main TODO.md | grep -A3 "FEAT-001\*\*" | grep -q "State: branch todo/FEAT-001-subtract"'
  chk "no [/] on main" '! at main TODO.md | grep -q "^ *- \[/\]"'
  chk "main gained exactly the claim commit, TODO.md only" '[ "$(git log --format=%s $start..main)" = "chore(backlog): claim FEAT-002 on $(git branch --list "todo/FEAT-002-*" | tr -d "* ")" ] && [ "$(git diff --name-only $start main)" = TODO.md ]'
  chk "FEAT-002 is [/] on its branch with attempts and baseline" 'at "$(git branch --list "todo/FEAT-002-*" | tr -d "* ")" TODO.md | grep -A3 "\[/\] \*\*FEAT-002" | grep -q "State: attempts 0/3; baseline 1 passing; branch todo/FEAT-002-"'
  chk "no code written (stopped after the claim)" '! git grep -q "def multiply" $(git for-each-ref --format="%(refname)" refs/heads)'
  ;;
team-claim)
  chk "the pull was merged: the peer's claim of FEAT-001 is on main" 'at main TODO.md | grep -A3 "FEAT-001\*\*" | grep -q "State: branch todo/FEAT-001-peer-work"'
  chk "no conflict markers are left in TODO.md" '! at main TODO.md | grep -Eq "^(<<<<<<<|=======|>>>>>>>)"'
  chk "FEAT-003 stays the peer's divide root, once" '[ "$(at main TODO.md | grep -c "\*\*FEAT-003\*\*")" = 1 ] && at main TODO.md | grep "\*\*FEAT-003\*\*" | grep -q divide'
  chk "the local power root was renumbered to FEAT-004 and keeps its Depends" 'at main TODO.md | grep -A3 "\*\*FEAT-004\*\*" | grep -q power && at main TODO.md | grep -A3 "\*\*FEAT-004\*\*" | grep -q "Depends: FEAT-002"'
  chk "FEAT-001 was skipped: no branch of ours for it" '! git branch --list "todo/FEAT-001-*" | grep -q .'
  chk "FEAT-002 is claimed on main with its branch" 'at main TODO.md | grep -A3 "FEAT-002\*\*" | grep -q "State: branch todo/FEAT-002-"'
  chk "a branch for FEAT-002 exists with FEAT-002 [/]" 'at "$(git branch --list "todo/FEAT-002-*" | head -1 | tr -d "* ")" TODO.md | grep -q "\[/\] \*\*FEAT-002"'
  chk "nothing was pushed: origin is as the setup left it" '[ "$(git -C .team/origin.git for-each-ref --format="%(refname) %(objectname)")" = "$(cat "$gd/team-origin-refs")" ]'
  chk "no code written (stopped after the start commit)" '! git grep -q "def multiply" $(git for-each-ref --format="%(refname)" refs/heads)'
  ;;
race-claim-conflict)
  chk "the rival's claim is on main" 'at main TODO.md | grep -q "State: branch todo/FEAT-001-rival"'
  chk "main's tip is still the rival's claim (not overwritten)" '[ "$(git log -1 --format=%s main)" = "chore(backlog): claim FEAT-001 on todo/FEAT-001-rival" ]'
  chk "the agent deleted its own root branch" '! git branch --list "todo/FEAT-001-*" | grep -v rival | grep -q .'
  chk "no subtract anywhere" '! git grep -q "def subtract" $(git for-each-ref --format="%(refname)" refs/heads)'
  chk "rival branch untouched" '[ "$(git log --oneline main..todo/FEAT-001-rival | wc -l)" = 0 ]'
  chk "ends on the base with a clean tree" '[ "$(git branch --show-current)" = main ] && clean'
  ;;
race-claim-benign)
  chk "the rival docs commit is kept on main" 'git log --format=%s main | grep -q "docs: touch readme (race)"'
  chk "main shows FEAT-001 claimed with the agent's branch" 'at main TODO.md | grep -A3 "FEAT-001\*\*" | grep -q "State: branch todo/FEAT-001-"'
  chk "agent's branch exists" 'git branch --list "todo/FEAT-001-*" | grep -q .'
  chk "main is an ancestor of the agent's branch" 'git merge-base --is-ancestor main $(git branch --list "todo/FEAT-001-*" | head -1 | tr -d "* ")'
  chk "claim is the only extra commit on main" '[ "$(git log --oneline $(git log --format=%H --grep="docs: touch readme" -1)..main | wc -l)" = 1 ]'
  chk "FEAT-001 is [/] on the agent's branch" 'at "$(git branch --list "todo/FEAT-001-*" | head -1 | tr -d "* ")" TODO.md | grep -q "\[/\] \*\*FEAT-001"'
  ;;
release-ask)
  chk "nothing changed before the user answered" 'unchanged && clean'
  ;;
release)
  chk "[Unreleased] is now empty (no entries)" '! at HEAD CHANGELOG.md | sed -n "/^## \[Unreleased\]/,/^## \[/p" | grep -q "^- "'
  chk "new version section exists with a date" 'at HEAD CHANGELOG.md | grep -Eq "^## \[0\.2\.0\] - [0-9]{4}-[0-9]{2}-[0-9]{2}$"'
  chk "released entries moved under 0.2.0" 'at HEAD CHANGELOG.md | sed -n "/^## \[0\.2\.0\]/,/^## \[0\.1\.0\]/p" | grep -q "FEAT-002" && at HEAD CHANGELOG.md | sed -n "/^## \[0\.2\.0\]/,/^## \[0\.1\.0\]/p" | grep -q "FIX-001"'
  chk "0.1.0 section untouched" 'at HEAD CHANGELOG.md | sed -n "/^## \[0\.1\.0\]/,/^\[Unreleased\]/p" | grep -q "Initial calculator with add"'
  chk "compare links updated" 'at HEAD CHANGELOG.md | grep -q "^\[Unreleased\]: .*compare/v0.2.0...HEAD" && at HEAD CHANGELOG.md | grep -q "^\[0.2.0\]:"'
  chk "release commit touches only CHANGELOG.md" '[ "$(git diff --name-only HEAD~1 HEAD)" = "CHANGELOG.md" ] && [ "$(git log -1 --format=%s)" = "chore(release): 0.2.0" ]'
  chk "exactly one new commit" '[ "$(new_commits | wc -l)" = 1 ] && clean'
  ;;
monorepo)
  chk "TODO.md exists with the task tree heading" '[ -f TODO.md ] && grep -q "^## .*Task Tree" TODO.md'
  chk "the human-written CHANGELOG entries survive" 'grep -q "Greeting helper in the web package" CHANGELOG.md && grep -q "## \[1.2.0\] - 2026-09-15" CHANGELOG.md'
  chk "a task mentions the api package power work" 'grep -qi "power" TODO.md || git log --all --format=%s | grep -qi power'
  chk "Done when / regression use a real command (make test or the api suite)" 'grep -E "make test|unittest" TODO.md || git log --all -p | grep -E "make test|unittest"'
  chk "FEAT-001 drained on main with the core format" 'at main CHANGELOG.md | entry FEAT-001'
  chk "a power test exists on main" 'git grep -q "def test_power" main -- packages/api'
  chk "main checked out, tree clean (README Tests line committed)" '[ "$(git branch --show-current)" = main ] && clean'
  chk "no todo branches left" '[ -z "$(git branch --list "todo/*")" ]'
  chk "nothing outside packages/api, backlog files and the README Tests line changed on main" '[ -z "$(git diff --name-only $(git rev-list --max-parents=0 HEAD) main -- . | grep -v -e TODO.md -e CHANGELOG.md -e .claude -e packages/api/ -e "^README.md$")" ]'
  ;;
lanes)
  chk "both roots drained into the changelog on main" 'at main CHANGELOG.md | grep -q "FEAT-001" && at main CHANGELOG.md | grep -q "FEAT-002"'
  chk "main TODO.md has no roots left" '! at main TODO.md | grep -q "^- \["'
  chk "subtract and shout both on main" 'at main calc.py | grep -q subtract && at main text.py | grep -q shout'
  chk "tests for both exist on main" 'at main tests/test_calc.py | grep -q test_subtract && at main tests/test_text.py | grep -q test_shout'
  chk "no todo branches left" '[ -z "$(git branch --list "todo/*")" ]'
  chk "no extra worktrees left" '[ "$(git worktree list | wc -l)" = 1 ]'
  chk "both entries have the core format" 'at main CHANGELOG.md | entry FEAT-001 && at main CHANGELOG.md | entry FEAT-002'
  chk "main checked out and tests pass" '[ "$(git branch --show-current)" = main ] && python3 -m unittest discover -s tests'
  chk "lane work ran in separate worktrees" 'lane_worktrees'
  lane_info
  ;;
replan)
  chk "FEAT-003 is gone from the tree" '! grep -q "FEAT-003" TODO.md'
  chk "FEAT-003 id is not reused" '[ "$(grep -o "FEAT-003" TODO.md | wc -l)" = 0 ]'
  chk "FEAT-001 untouched" 'grep -q "\*\*FEAT-001\*\* · P1 · low · Add subtract to calc.py" TODO.md'
  chk "plan doc has a dated revision line naming FEAT-003" 'sed -n "/^## Revisions/,\$p" docs/plans/PROJECT.md | grep -E "^- [0-9]{4}-[0-9]{2}-[0-9]{2} · " | grep -q FEAT-003'
  chk "FEAT-002 untouched" 'grep -q "\*\*FEAT-002\*\* · P1 · low · Add a command line interface to the calculator" TODO.md'
  chk "nothing committed" 'unchanged'
  chk "no code or tests changed" '[ -z "$(git diff --name-only HEAD -- calc.py tests)" ]'
  chk "no node started" '! grep -q "^ *- \[/\]" TODO.md'
  ;;
ci-github|ci-local)
  chk "check.sh exists and runs green" '[ -f .todo/check.sh ] && bash .todo/check.sh'
  chk "check.sh runs the tests (and the lint only if .todo/todo-lint.sh exists)" 'grep -q "unittest" .todo/check.sh && { [ -f .todo/todo-lint.sh ] || ! grep -q "todo-lint.sh" .todo/check.sh; }'
  chk "a vendored lint, if present, equals tools/todo-lint.sh" '[ ! -f .todo/todo-lint.sh ] || cmp -s .todo/todo-lint.sh "$root/tools/todo-lint.sh"'
  chk "nothing committed (the user commits CI files)" 'unchanged'
  if [ "$scenario" = ci-github ]; then
    chk "GitHub workflow runs check.sh with python set up" 'grep -q "check.sh" .github/workflows/todo-check.yml && grep -q "setup-python" .github/workflows/todo-check.yml'
    chk "workflow runs on pull_request and push to main" 'grep -q "pull_request" .github/workflows/todo-check.yml && grep -Eq "branches: *\[ *main *\]|- main" .github/workflows/todo-check.yml'
  else
    chk "no workflow written without a remote" '[ ! -e .github/workflows/todo-check.yml ]'
    chk "pre-push hook runs check.sh" 'grep -q "check.sh" "$gd/hooks/pre-push" && [ -x "$gd/hooks/pre-push" ]'
  fi
  ;;
happy-path)
  chk "subtract and its test on main" 'at main calc.py | grep -q "def subtract" && at main tests/test_calc.py | grep -q "def test_subtract"'
  chk "FEAT-001 drained on main with the core format" 'at main CHANGELOG.md | entry FEAT-001 && ! at main TODO.md | grep -q FEAT-001'
  chk "main history: claim, then the root merge" 'git log --first-parent --format=%s $start..main | tr "\n" "|" | grep -Eq "^Merge FEAT-001 into main\|chore\(backlog\): claim FEAT-001 on todo/FEAT-001-[a-z0-9-]+\|$"'
  chk "root branch has start, node commit and drain" 'git log --format=%s main^2 | head -3 | tr "\n" "|" | grep -Eq "^chore\(backlog\): drain FEAT-001\|feat\([a-z0-9._-]+\): .*\|chore\(backlog\): start FEAT-001\|$"'
  chk "no todo branches left, on main, clean" '[ -z "$(git branch --list "todo/*")" ] && [ "$(git branch --show-current)" = main ] && clean'
  ;;
baseline-red)
  chk "nothing changed: no branch, no commit, no edit" 'unchanged && clean'
  # The repository alone proves nothing here (an agent that never ran leaves it unchanged): the report must say what happened.
  rep="${TRIAL_REPORT:-}"
  chk "an agent report was provided and is not empty" '[ -n "$rep" ] && [ -s "$rep" ] && [ -n "$(tr -d "[:space:]" < "$rep")" ]'
  chk "report says the baseline is red and names the failing test" '[ -s "$rep" ] && grep -Eiq "baseline.{0,40}(red|fail)|(red|fail).{0,40}baseline" "$rep" && grep -Eq "test_add|unittest" "$rep"'
  chk "report suggests a fix (a FIX node or /todo-add --type fix)" '[ -s "$rep" ] && grep -Eq "/todo-add.*fix|FIX" "$rep"'
  ;;
no-git)
  chk "still not a git repository" '[ ! -e .git ]'
  chk "subtract and its test written" 'grep -q "def subtract" calc.py && python3 -m unittest tests.test_calc.CalcTest.test_subtract'
  chk "FEAT-001 drained with the core format" 'entry FEAT-001 < CHANGELOG.md && ! grep -q FEAT-001 TODO.md'
  ;;
add-fix)
  chk "a P0 FIX-002 root with a complexity (one global ID sequence)" 'grep -Eq "^- \[ \] \*\*FIX-002\*\* · P0 · (low|mid|high) · " TODO.md'
  chk "FIX-002 placed before the P1 root" '[ "$(grep -o "^- \[ \] \*\*[A-Z]*-[0-9]*" TODO.md | head -1)" = "- [ ] **FIX-002" ]'
  chk "its Done when targets a test id" 'grep -A1 "FIX-002\*\*" TODO.md | grep -Eq "Done when: .*\`python3 -m unittest tests\.test_calc\.[A-Za-z]+\.test_[a-z_]+\`"'
  chk "FEAT-001 untouched" '[ -z "$(git diff $start -- TODO.md | grep "^-" | grep -v "^---")" ]'
  chk "no code changed, nothing committed" 'unchanged && git diff --quiet -- calc.py tests'
  ;;
update-block)
  chk "FEAT-002 is [!] with a manual Blocked line" 'grep -A3 "\[!\] \*\*FEAT-002" TODO.md | grep -q "Blocked: .*rounding.* → n/a (manual) → "'
  chk "FEAT-001 untouched, only FEAT-002 lines changed" '[ "$(git diff -U0 $start -- TODO.md | grep -c "^[-+][^-+]")" -le 3 ] && grep -q "^- \[ \] \*\*FEAT-001" TODO.md'
  chk "nothing committed" 'unchanged'
  ;;
update-drop)
  chk "FEAT-002 is gone from TODO.md and not in CHANGELOG" '! grep -q FEAT-002 TODO.md && ! grep -q FEAT-002 CHANGELOG.md'
  chk "FEAT-001 untouched" 'grep -q "^- \[ \] \*\*FEAT-001\*\* · P1 · low · Add subtract to calc.py" TODO.md'
  chk "nothing committed on the base" 'unchanged'
  chk "the dropped ID is recorded in the plan's Revisions" 'sed -n "/^## Revisions/,\$p" docs/plans/PROJECT.md | grep -q FEAT-002'
  ;;
status-readonly)
  chk "nothing changed" 'unchanged && clean'
  ;;
report)
  chk "docs/status.html written, no placeholder left" '[ -s docs/status.html ] && ! grep -q "__TODO__\|__CHANGELOG__\|__META__" docs/status.html'
  chk "hostile title is encoded" 'grep -q "FEAT-002" docs/status.html && ! grep -q "& </script> in the title" docs/status.html'
  chk "only docs/status.html changed" 'unchanged && [ "$(git status --porcelain)" = "?? docs/status.html" ]'
  ;;
blocked-sibling)
  chk "the blocked node's branch is untouched" '[ "$(git rev-parse todo/FEAT-001.1-subtract-test)" = "$(grep FEAT-001.1 "$gd/trial-refs" | cut -d" " -f2)" ]'
  chk "FEAT-001.1 was not restarted anywhere" '! git grep -q "\[/\] \*\*FEAT-001.1" $(git for-each-ref --format="%(refname)" refs/heads)'
  chk "FEAT-001.2 started on its own branch" 'b=$(git branch --list "todo/FEAT-001.2-*" | tr -d "* "); [ -n "$b" ] && at $b TODO.md | grep -q "\[/\] \*\*FEAT-001.2"'
  chk "main untouched" '[ "$(git rev-parse main)" = "$(grep "refs/heads/main " "$gd/trial-refs" | cut -d" " -f2)" ]'
  ;;
ts-lifecycle)
  chk "FEAT-001 drained into the changelog on main with the core format" 'at main CHANGELOG.md | entry FEAT-001'
  chk "main TODO.md has no roots left" '! at main TODO.md | grep -q "^- \["'
  chk "subtract and multiply exist on main" 'at main src/calc.ts | grep -q subtract && at main src/calc.ts | grep -q multiply'
  chk "a test file per child exists on main" 'git cat-file -e main:tests/subtract.test.ts && git cat-file -e main:tests/multiply.test.ts'
  chk "no todo branches or extra worktrees left" '[ -z "$(git branch --list "todo/*")" ] && [ "$(git worktree list | wc -l)" = 1 ]'
  chk "main checked out, tree clean, node_modules not tracked" '[ "$(git branch --show-current)" = main ] && clean && [ "$(git ls-files | grep -c "^node_modules/")" = 0 ]'
  ;;
java-lifecycle)
  chk "FEAT-001 drained into the changelog on main with the core format" 'at main CHANGELOG.md | entry FEAT-001'
  chk "main TODO.md has no roots left" '! at main TODO.md | grep -q "^- \["'
  chk "subtract and multiply exist on main" 'at main src/main/java/mini/Calc.java | grep -q subtract && at main src/main/java/mini/Calc.java | grep -q multiply'
  chk "SubtractTest and MultiplyTest exist on main" 'git cat-file -e main:src/test/java/mini/SubtractTest.java && git cat-file -e main:src/test/java/mini/MultiplyTest.java'
  chk "no todo branches or extra worktrees left" '[ -z "$(git branch --list "todo/*")" ] && [ "$(git worktree list | wc -l)" = 1 ]'
  chk "main checked out, tree clean, target/ not tracked" '[ "$(git branch --show-current)" = main ] && clean && [ "$(git ls-files | grep -c "/target/\\|^target/")" = 0 ]'
  ;;
multi-module)
  chk "both roots drained into the changelog on main" 'at main CHANGELOG.md | entry FEAT-001 && at main CHANGELOG.md | entry FEAT-002'
  chk "main TODO.md has no roots left" '! at main TODO.md | grep -q "^- \["'
  chk "subtract is in core and shout in text, each only in its own module" 'at main core/src/main/java/mini/core/Calc.java | grep -q subtract && at main text/src/main/java/mini/text/Text.java | grep -q shout && ! at main text/src/main/java/mini/text/Text.java | grep -q subtract'
  chk "SubtractTest and ShoutTest exist on main" 'git cat-file -e main:core/src/test/java/mini/core/SubtractTest.java && git cat-file -e main:text/src/test/java/mini/text/ShoutTest.java'
  chk "each lane ran in its own worktree and none is left" '[ "$(git worktree list | wc -l)" = 1 ] && [ -z "$(git branch --list "todo/*")" ]'
  chk "main checked out, tree clean, no build output tracked" '[ "$(git branch --show-current)" = main ] && clean && [ "$(git ls-files | grep -c "target/")" = 0 ]'
  chk "the whole reactor build passes on main" 'mvn -q -B test'
  chk "lane work ran in separate worktrees" 'lane_worktrees'
  lane_info
  ;;
*) echo "unknown scenario"; exit 1 ;;
esac
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
