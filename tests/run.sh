#!/usr/bin/env bash
# Runs todo-lint.sh and todo-stop-hook.sh against the static fixtures in tests/fixtures.
# A fixture named ok-*.md must pass. A fixture named I<n>-*.md must fail with "FAIL I<n>:". W<n>-*.md (W1-W4) must pass with "WARN W<n>:".
# ok-*.md fixtures must also print no WARN line.
# Usage: bash tests/run.sh      Needs bash, awk, grep and sed. Creates no files.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lint="$root/skills/todo/scripts/todo-lint.sh"
hook="$root/skills/todo/scripts/todo-stop-hook.sh"
fx="$root/tests/fixtures"
changelog="$fx/changelog/CHANGELOG.md"
pass=0
fail=0

ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

for f in "$fx"/*.md; do
  name="$(basename "$f" .md)"
  expect="${name%%-*}"
  out="$(bash "$lint" "$f" "$changelog" 2>&1)"
  rc=$?
  if [ "$expect" = "W1" ] || [ "$expect" = "W2" ] || [ "$expect" = "W3" ] || [ "$expect" = "W4" ]; then
    if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q "WARN $expect:"; then ok "$name"; else bad "$name: expected WARN $expect with rc=0, got rc=$rc: $out"; fi
  elif [ "$expect" = "ok" ]; then
    if [ "$rc" -eq 0 ]; then if printf '%s\n' "$out" | grep -q "^WARN"; then bad "$name: unexpected warning: $out"; else ok "$name"; fi; else bad "$name: expected OK, got: $out"; fi
  else
    if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q "FAIL $expect:"; then ok "$name"; else bad "$name: expected FAIL $expect, got rc=$rc: $out"; fi
  fi
done

# The plugin version equals the newest released CHANGELOG version.
pv="$(sed -nE 's/.*"version" *: *"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' "$root/.claude-plugin/plugin.json" | head -1)"
cv="$(sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' "$root/CHANGELOG.md" | head -1)"
if [ -n "$pv" ] && { [ -z "$cv" ] || [ "$pv" = "$cv" ]; }; then ok "plugin version $pv matches the changelog (${cv:-no release yet})"; else bad "plugin.json version '$pv' does not match newest CHANGELOG version '$cv'"; fi

# Every SKILL.md frontmatter is valid YAML (strict loaders such as the skills CLI skip a skill that is not).
if python3 -c 'import yaml' 2>/dev/null; then
  yamlbad="$(python3 - "$root" <<'PY'
import sys, glob, yaml
for f in sorted(glob.glob(sys.argv[1] + "/skills/*/SKILL.md")):
    try: yaml.safe_load(open(f, encoding="utf-8").read().split("---")[1])
    except Exception: print(f)
PY
)"
  if [ -z "$yamlbad" ]; then ok "SKILL.md frontmatter is valid YAML"; else bad "invalid YAML frontmatter: $yamlbad"; fi
fi

# The Codex manifest parses and carries the same version as the Claude plugin manifest.
cxv="$(sed -nE 's/.*"version" *: *"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' "$root/.codex-plugin/plugin.json" | head -1)"
if [ -n "$cxv" ] && [ "$cxv" = "$pv" ] && python3 -m json.tool "$root/.codex-plugin/plugin.json" >/dev/null 2>&1 && python3 -m json.tool "$root/.agents/plugins/marketplace.json" >/dev/null 2>&1; then ok "codex manifests parse and match version $pv"; else bad "codex manifests missing, invalid, or version '$cxv' differs from '$pv'"; fi

# The report template keeps its four placeholders.
tpl="$root/skills/todo-report/template.html"
if grep -q '>__META__<' "$tpl" && grep -q '>__TODO__<' "$tpl" && grep -q '>__CHANGELOG__<' "$tpl" && grep -q '>__PLAN__<' "$tpl"; then ok "report template placeholders"; else bad "report template placeholders missing"; fi

# Every skill folder has a SKILL.md whose name matches the folder, and the core lists every command skill.
for d in "$root"/skills/*/; do
  n="$(basename "$d")"
  if grep -q "^name: $n\$" "$d/SKILL.md" 2>/dev/null; then ok "skill $n: name matches folder"; else bad "skill $n: SKILL.md missing or name mismatch"; fi
  if [ "$n" != todo ]; then grep -q "/$n\b" "$root/skills/todo/SKILL.md" && grep -q "/$n\b" "$root/README.md" || bad "skill $n is not listed in the core commands table and README"; fi
done

# The report generator encodes hostile text (no raw < from the data reaches the page).
tmp_out="$(cd "$fx/report" && printf 'project: x\n' | bash "$root/skills/todo-report/todo-report.sh")"
if printf '%s' "$tmp_out" | grep -q '<img' || ! printf '%s' "$tmp_out" | grep -q '&lt;/Script>'; then bad "report generator does not encode the data"; else ok "report generator encodes hostile text"; fi

# The report generator refuses to run without a TODO.md in the current directory (FIX-003).
err="$(cd "$fx/changelog" && printf '' | bash "$root/skills/todo-report/todo-report.sh" 2>&1 >/dev/null)"
rc=$?
if [ "$rc" -eq 1 ] && [ "${err#todo-report:}" != "$err" ]; then ok "report generator exits 1 without TODO.md"; else bad "report generator without TODO.md: expected rc=1 and stderr starting 'todo-report:', got rc=$rc: $err"; fi

# This repository's vendored lint (.todo/, from /todo-init --ci) stays identical to the core lint.
if [ ! -f "$root/.todo/todo-lint.sh" ] || cmp -s "$root/.todo/todo-lint.sh" "$lint"; then ok "vendored .todo/todo-lint.sh matches the core lint"; else bad ".todo/todo-lint.sh differs from skills/todo/scripts/todo-lint.sh: copy it again"; fi

# The repository's own backlog must follow its own rules.
out="$(cd "$root" && bash "$lint" TODO.md CHANGELOG.md 2>&1)"
if [ $? -eq 0 ]; then ok "this repository's TODO.md and CHANGELOG.md lint clean"; else bad "repo backlog: $out"; fi

# Optional RTM (FEAT-008): docs/RTM.md wins, else README "## RTM", else none; neither is required.
rtm="$root/skills/todo/scripts/todo-rtm.sh"
rx="$root/tests/fixtures-rtm"
rtm_is() { out="$(bash "$rtm" "$rx/$1" 2>&1)"; rc=$?; if [ "$rc" -eq "$2" ] && [ "$(printf '%s\n' "$out" | head -1)" = "RTM: $3" ]; then ok "rtm $1: $3 (rc $2)"; else bad "rtm $1: expected 'RTM: $3' rc=$2, got rc=$rc: $out"; fi; }
rtm_is docs-only 0 docs/RTM.md
rtm_is readme-only 0 README.md
rtm_is both 0 docs/RTM.md
rtm_is neither 0 none
rtm_is stale 1 docs/RTM.md
out="$(bash "$rtm" "$rx/stale" 2>&1)"
if printf '%s\n' "$out" | grep -q "FAIL R1:.*GHOST-999" && printf '%s\n' "$out" | grep -q "FAIL R2:.*R-002"; then ok "rtm flags a stale task link (R1) and an archived row without verification (R2)"; else bad "rtm stale checks: $out"; fi
out="$(bash "$rtm" "$rx/readme-only" 2>&1)"
if printf '%s\n' "$out" | grep -q FAIL; then bad "rtm: a table outside the README RTM section was checked: $out"; else ok "rtm: README tables outside ## RTM are ignored; a completed task with verification passes"; fi
out="$(bash "$rtm" "$fx/changelog" 2>&1)"
if [ "$out" = "RTM: none" ]; then ok "rtm: a folder with no README or docs has no RTM"; else bad "rtm without files: $out"; fi
if grep -q 'reference/rtm.md' "$root/skills/todo/SKILL.md" && grep -q 'rtm.md' "$root/skills/todo-plan/SKILL.md" && grep -q 'rtm.md' "$root/skills/todo-add/SKILL.md" && grep -q 'rtm.md' "$root/skills/todo-continue/SKILL.md" && [ -f "$root/skills/todo/reference/rtm.md" ]; then ok "plan, add and continue point at the RTM rules"; else bad "an RTM reference is missing from the core, plan, add or continue skill"; fi

# Verification classifier (TASK-009): zero-test runs, missing targets, masked failures; valid runners stay accepted.
vf="$root/skills/todo/scripts/todo-verify.sh"
vcase() { want="$1"; rc_in="$2"; cmd="$3"; text="$4"; out="$(cd "$root" && printf '%s\n' "$text" | bash "$vf" "$rc_in" "$cmd" 2>&1)"; if [ "${out%% *}" = "$want" ]; then ok "verify $want: $cmd [$text]"; else bad "verify expected $want for '$cmd' [$text], got: $out"; fi; }
vcase ACCEPT 0 'bash tests/run.sh' '65 passed, 0 failed'
vcase ACCEPT 0 'python3 -m unittest tests.test_calc' 'Ran 3 tests in 0.01s'
vcase ACCEPT 0 'npx jest' 'Tests:       4 passed, 4 total'
vcase ACCEPT 0 'go test ./...' 'ok  	example.com/pkg	0.01s'
vcase ACCEPT 0 'cargo test' 'test result: ok. 3 passed; 0 failed
test result: ok. 0 passed; 0 failed'
vcase ACCEPT 0 'make check' 'done'
vcase REJECT 0 'pytest' 'collected 0 items'
vcase REJECT 0 'python3 -m unittest' 'Ran 0 tests in 0.00s'
vcase REJECT 0 'npx jest' 'No tests found, exiting with code 0'
vcase REJECT 0 'npm test' 'Tests: 0 total'
vcase REJECT 0 'rspec' '0 examples, 0 failures'
vcase REJECT 0 'bash tests/missing-test.sh' '3 passed'
vcase REJECT 0 'pytest tests/nope.py::test_x' '1 passed'
vcase REJECT 0 'bash tests/run.sh || true' '65 passed'
vcase REJECT 0 'bash tests/run.sh; exit 0' '65 passed'
vcase REJECT 1 'bash tests/run.sh' '1 failed'
vcase REJECT x 'bash tests/run.sh' '1 passed'

# Resume, blocked verification and missing optional CI files, all without services (TASK-010).
out="$(bash "$lint" "$fx/ok-resume.md" "$fx/changelog/no-such-CHANGELOG.md" 2>&1)"
if [ $? -eq 0 ]; then ok "lint works without a CHANGELOG.md"; else bad "lint failed without CHANGELOG.md: $out"; fi
out="$(bash "$lint" "$fx/no-such-TODO.md" 2>&1)"
if [ $? -eq 2 ] && printf '%s' "$out" | grep -q '^FAIL: .*not found'; then ok "lint exits 2 without a TODO.md"; else bad "lint without TODO.md: $out"; fi
out="$(printf '{}' | TODO_FILE="$fx/ok-resume.md" CHANGELOG_FILE="$fx/no-such-CHANGELOG.md" bash "$hook")"
if [ -z "$out" ]; then ok "hook allows the stop on an interrupted [/] node with no CHANGELOG.md"; else bad "hook blocked a resumable backlog: $out"; fi
out="$(printf '{}' | TODO_FILE="$fx/ok-blocked-verification.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook allows the stop when verification is blocked"; else bad "hook blocked a blocked-verification backlog: $out"; fi
if [ ! -d "$root/tests/fixtures-rtm/neither/.todo" ]; then ok "a project without .todo/ or CI files is a valid fixture (checks are optional)"; else bad "fixture unexpectedly has .todo/"; fi

# Documentation drift (TASK-011): file:line references, interface changes only, never a new tool.
dd="$root/skills/todo-continue/SKILL.md"
if grep -q '<file>:<line>: <name>' "$dd" && grep -q 'grep -rnF' "$dd" && grep -q 'changed no interface skips this' "$dd" && grep -q 'never blocks it' "$dd"; then ok "documentation drift reports file:line references and does not block unrelated nodes"; else bad "todo-continue documentation drift rules are incomplete"; fi
drift="$(grep -rnF -- 'todo-lint.sh' "$root/README.md" "$root/docs" 2>/dev/null | head -1)"
if printf '%s' "$drift" | grep -Eq '^[^:]+:[0-9]+:'; then ok "the documented grep -rnF form yields file:line hits"; else bad "grep -rnF drift form gave no file:line: $drift"; fi

# Stop hook: valid backlog allows the stop (no output).
out="$(printf '{"stop_hook_active": false}' | TODO_FILE="$fx/ok-valid.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook allows stop on a valid backlog"; else bad "hook printed output on a valid backlog: $out"; fi

# Stop hook: invalid backlog blocks.
out="$(printf '{"stop_hook_active": false}' | TODO_FILE="$fx/I1-two-active.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if printf '%s' "$out" | grep -q '"decision":"block"'; then ok "hook blocks on an invalid backlog"; else bad "hook did not block: $out"; fi

# Stop hook: never blocks twice in a row (loop guard).
out="$(printf '{"stop_hook_active": true}' | TODO_FILE="$fx/I1-two-active.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook honours stop_hook_active"; else bad "hook ignored stop_hook_active: $out"; fi

# Stop hook: no TODO.md means nothing to enforce.
out="$(printf '{}' | TODO_FILE="$fx/does-not-exist.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook is silent without a TODO.md"; else bad "hook printed output without TODO.md: $out"; fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
