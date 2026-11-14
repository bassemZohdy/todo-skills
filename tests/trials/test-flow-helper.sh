#!/usr/bin/env bash
# The optional lifecycle helper in the harness (FEAT-129.4, no agent needed): TRIAL_FLOW_HELPER=1 makes setup.sh install
# tools/todo-flow.sh as .todo/todo-flow.sh, the benchmark variant todo-skills-flow does the same for a benchmark
# repository, and a lifecycle driven only through the helper's commands passes the unchanged assertions of the
# happy-path and refresh-from-base scenarios: its commits are the ones the skills prescribe.
# Usage: bash tests/trials/test-flow-helper.sh    Works in a temporary directory that it removes at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; root="$(cd "$here/../.." && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }
export GIT_AUTHOR_NAME=t GIT_AUTHOR_EMAIL=t@example.invalid GIT_COMMITTER_NAME=t GIT_COMMITTER_EMAIL=t@example.invalid
export PYTHONNOUSERSITE=1   # a "tests" package in the user site must not shadow the scratch project's tests folder
fl() { bash .todo/todo-flow.sh "$@" 2>&1; }

# The switch: off by default, on with TRIAL_FLOW_HELPER=1, and the helper is part of the start commit, so the tree is clean.
bash "$here/setup.sh" "$tmp/off" happy-path >/dev/null 2>&1
[ ! -e "$tmp/off/.todo/todo-flow.sh" ] && ok "setup.sh installs no helper by default" || bad "setup.sh installed the helper without the switch"
TRIAL_FLOW_HELPER=1 bash "$here/setup.sh" "$tmp/hp" happy-path >/dev/null 2>&1
cmp -s "$root/tools/todo-flow.sh" "$tmp/hp/.todo/todo-flow.sh" && [ -z "$(git -C "$tmp/hp" status --porcelain)" ] && git -C "$tmp/hp" ls-files --error-unmatch .todo/todo-flow.sh >/dev/null 2>&1 \
  && ok "TRIAL_FLOW_HELPER=1 installs the helper in the start commit of the scratch repository" || bad "TRIAL_FLOW_HELPER=1 did not install a committed .todo/todo-flow.sh"
TRIAL_FLOW_HELPER=1 bash "$here/setup.sh" "$tmp/ng" no-git >/dev/null 2>&1
cmp -s "$root/tools/todo-flow.sh" "$tmp/ng/.todo/todo-flow.sh" && ok "the switch also works for the no-git scenario" || bad "no helper in the no-git scratch folder"

# happy-path through the helper alone: start, the red-green change, complete, drain --merge.
if cd "$tmp/hp" 2>/dev/null; then
  out="$(fl start FEAT-001 1)" || bad "happy-path start: $out"
  python3 - <<'PY'
p = 'tests/test_calc.py'
s = open(p, encoding='utf-8').read().replace('if __name__', '    def test_subtract(self):\n        self.assertEqual(calc.subtract(5, 3), 2)\nif __name__')
open(p, 'w', encoding='utf-8', newline='\n').write(s)
open('calc.py', 'a', encoding='utf-8', newline='\n').write('\ndef subtract(a, b):\n    return a - b\n')
PY
  out="$(fl complete FEAT-001 -m 'feat(calc): add subtract' -b "Red: AttributeError: module 'calc' has no attribute 'subtract'" -b 'Reviewed: self, 0 findings fixed' -- calc.py tests/test_calc.py)" || bad "happy-path complete: $out"
  out="$(fl drain FEAT-001 --merge)" || bad "happy-path drain: $out"
  res="$(bash "$here/assert.sh" "$tmp/hp" happy-path 2>&1)"
  if printf '%s\n' "$res" | grep -q '^PASS' && ! printf '%s\n' "$res" | grep -q '^FAIL'; then ok "a happy-path lifecycle made by the helper passes the unchanged happy-path assertions"; else bad "happy-path through the helper: $(printf '%s\n' "$res" | grep '^FAIL' | tr '\n' ';')"; fi
else bad "no happy-path scratch repository"; fi

# refresh-from-base through the helper: the node's work is uncommitted and the base moved; complete refreshes, drain stays on the branch.
TRIAL_FLOW_HELPER=1 bash "$here/setup.sh" "$tmp/rb" refresh-from-base >/dev/null 2>&1
if cd "$tmp/rb" 2>/dev/null; then
  out="$(fl complete FEAT-001 -m 'feat(calc): add subtract' -b 'Reviewed: self, 0 findings fixed' -- calc.py tests/test_calc.py)" || bad "refresh-from-base complete: $out"
  printf '%s' "$out" | grep -q 'brought changes' && ok "complete reports that the moved base brought changes" || bad "complete did not report the refresh: $out"
  out="$(fl drain FEAT-001)" || bad "refresh-from-base drain: $out"
  res="$(bash "$here/assert.sh" "$tmp/rb" refresh-from-base 2>&1)"
  if printf '%s\n' "$res" | grep -q '^PASS' && ! printf '%s\n' "$res" | grep -q '^FAIL'; then ok "a refresh and drain made by the helper pass the unchanged refresh-from-base assertions"; else bad "refresh-from-base through the helper: $(printf '%s\n' "$res" | grep '^FAIL' | tr '\n' ';')"; fi
else bad "no refresh-from-base scratch repository"; fi

# The benchmark variant: the todo-skills arm's own text, and a setup that adds only the helper to what that arm installs.
v="$root/tests/benchmark/variants/todo-skills-flow"; a="$root/tests/benchmark/arms/todo-skills"
cmp -s "$v/arm.md" "$a/arm.md" && ok "the todo-skills-flow variant gives the agent the same instructions as the todo-skills arm" || bad "variants/todo-skills-flow/arm.md is missing or differs from arms/todo-skills/arm.md"
mkdir -p "$tmp/b1" "$tmp/b2"
if bash "$a/setup.sh" "$tmp/b1" "$root" >/dev/null 2>&1 && bash "$v/setup.sh" "$tmp/b2" "$root" >/dev/null 2>&1 && cmp -s "$root/tools/todo-flow.sh" "$tmp/b2/.todo/todo-flow.sh" \
   && rm -rf "$tmp/b2/.todo" && diff -r "$tmp/b1" "$tmp/b2" >/dev/null; then ok "the variant's setup installs what the arm installs plus .todo/todo-flow.sh, nothing else"
else bad "variants/todo-skills-flow/setup.sh does not install the arm's files plus the helper"; fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
