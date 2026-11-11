#!/usr/bin/env bash
# todo-verify.sh - optional, read-only classifier for a finished verification run. It runs nothing.
# Usage: <run the Done when / regression command, keep its output and exit status>
#        <output> | bash todo-verify.sh <exit-status> '<the command line that was run>'      (from the repository root)
# Rejects (exit 1, one "REJECT <reason>" line) a run that cannot count as a pass:
#   - non-zero exit status;
#   - a command that masks failures (|| true, ; true, ; exit 0, || :);
#   - a test target named in the command (a tests/ test/ spec/ path or a script/test file) that does not exist;
#   - output that reports zero tests and no passing test ("0 tests", "no tests found", "collected 0 items", "NO TESTS RAN", Maven
#     "Tests run: 0", dotnet "No test is available", ...), a collect-only run (--collect-only, --co, "N tests collected"), or a
#     run that only skipped tests ("5 skipped" and no pass).
# Accepts (exit 0, "ACCEPT") anything else, including runners whose output has no recognizable count.
# Opt-in --strict (first argument) additionally rejects what default mode tolerates:
#   - output with no recognizable passing-test count at all (ambiguous);
#   - an unchecked pipe (cmd | tail/grep/head/cat/tee/sed/awk/cut/sort/uniq/wc) unless pipefail or PIPESTATUS is used;
#   - set +e, || echo ..., || printf ... and || exit 0 style masks.
# Default mode never changes: runners that print no count still pass without --strict.
# Needs bash, grep and sed.
strict=0
if [ "${1:-}" = "--strict" ]; then strict=1; shift; fi
rc="${1:-}"; cmd="${2:-}"
out="$(cat)"
reject() { echo "REJECT $1"; exit 1; }
case "$rc" in ''|*[!0-9]*) reject "exit status must be a number (got '$rc')";; esac
[ "$rc" -eq 0 ] || reject "command exited $rc"
if printf '%s' "$cmd" | grep -qE '(\|\| *(true|:|exit 0)|;[[:space:]]*(true|:|exit 0)[[:space:]]*($|;|&)|&& *(true|:)[[:space:]]*$)'; then reject "command masks failures: $cmd"; fi

# Test targets: words after any "cd <dir> &&" that look like repository paths must exist.
dir="."
body="$cmd"
case "$body" in cd\ *) dir="$(printf '%s' "$body" | sed -E 's/^cd +([^ ;&|]+).*/\1/')"; body="$(printf '%s' "$body" | sed -E 's/^cd +[^ ;&|]+ *&& *//')";; esac
set -f   # no pathname expansion here: a glob after "cd <dir> &&" belongs to <dir>, matched below, not to this folder
for w in $body; do
  case "$w" in -*|*=*|*'$'*|*://*|*...) continue;; esac
  t="${w%%::*}"; t="${t%\;}"
  case "$t" in
    tests/*|test/*|spec/*|__tests__/*|./*|*.sh|*.py|*.js|*.ts|*.tsx|*.jsx|*.rb|*.go|*.rs|*.java|*.php)
      case "$t" in *'*'*|*'?'*|*'['*) compgen -G "$dir/$t" >/dev/null || reject "test target matches no file: $t"; continue;; esac
      [ -e "$dir/$t" ] || reject "missing test target: $t";;
  esac
done
set +f

zero='(^|[^0-9.])0 (tests?|specs?|examples?|passed|passing)([^a-z]|$)|collected 0 items|Ran 0 tests?|Tests: +0 total|no tests? (found|ran|to run)|no test files|NO TESTS RAN|0 tests? (run|executed)|Tests run: 0,|No test is available|[0-9]+ tests? collected'
pos='(^|[^0-9.])[1-9][0-9]* (tests?|specs?|examples?|passed|passing)([^a-z]|$)|Ran [1-9][0-9]* tests?|Tests run: [1-9]|Passed: +[1-9]|^ok[[:space:]]|^PASS[[:space:]]'
if printf '%s\n' "$out" | grep -qiE "$zero" && ! printf '%s\n' "$out" | grep -qE "$pos"; then reject "the run executed zero tests"; fi
if printf '%s' "$cmd" | grep -qE '(^| )(--collect-only|--co)( |$)'; then reject "the command only collects tests; none executed: $cmd"; fi
if printf '%s\n' "$out" | grep -qE '(^|[^0-9.])[1-9][0-9]* skipped' && ! printf '%s\n' "$out" | grep -qE "$pos"; then reject "every test was skipped"; fi
if [ "$strict" -eq 1 ]; then
  if printf '%s' "$cmd" | grep -qE '(set \+e|\|\| *(echo|printf)\b)'; then reject "strict: command masks failures: $cmd"; fi
  if printf '%s' "$cmd" | grep -qE '[^|]\|[^|&][[:space:]]*(tail|grep|head|cat|tee|sed|awk|cut|sort|uniq|wc|less|more)\b' && ! printf '%s' "$cmd" | grep -qE 'pipefail|PIPESTATUS'; then reject "strict: unchecked pipe hides the exit status: $cmd"; fi
  printf '%s\n' "$out" | grep -qE "$pos" || reject "strict: output reports no passing test count (ambiguous)"
fi
echo ACCEPT
