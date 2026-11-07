#!/usr/bin/env bash
# todo-verify.sh - optional, read-only classifier for a finished verification run. It runs nothing.
# Usage: <run the Done when / regression command, keep its output and exit status>
#        <output> | bash todo-verify.sh <exit-status> '<the command line that was run>'      (from the repository root)
# Rejects (exit 1, one "REJECT <reason>" line) a run that cannot count as a pass:
#   - non-zero exit status;
#   - a command that masks failures (|| true, ; true, ; exit 0, || :);
#   - a test target named in the command (a tests/ test/ spec/ path or a script/test file) that does not exist;
#   - output that reports zero tests and no passing test ("0 tests", "no tests found", "collected 0 items", "NO TESTS RAN", ...).
# Accepts (exit 0, "ACCEPT") anything else, including runners whose output has no recognizable count.
# Needs bash, grep and sed.
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
for w in $body; do
  case "$w" in -*|*=*|*'$'*|*://*|*...) continue;; esac
  t="${w%%::*}"; t="${t%\;}"
  case "$t" in
    tests/*|test/*|spec/*|__tests__/*|./*|*.sh|*.py|*.js|*.ts|*.tsx|*.jsx|*.rb|*.go|*.rs|*.java|*.php)
      case "$t" in *'*'*|*'?'*|*'['*) compgen -G "$dir/$t" >/dev/null || reject "test target matches no file: $t"; continue;; esac
      [ -e "$dir/$t" ] || reject "missing test target: $t";;
  esac
done

zero='(^|[^0-9.])0 (tests?|specs?|examples?|passed|passing)([^a-z]|$)|collected 0 items|Ran 0 tests?|Tests: +0 total|no tests? (found|ran|to run)|no test files|NO TESTS RAN|0 tests? (run|executed)'
pos='(^|[^0-9.])[1-9][0-9]* (tests?|specs?|examples?|passed|passing)([^a-z]|$)|Ran [1-9][0-9]* tests?|^ok[[:space:]]|^PASS[[:space:]]'
if printf '%s\n' "$out" | grep -qiE "$zero" && ! printf '%s\n' "$out" | grep -qE "$pos"; then reject "the run executed zero tests"; fi
echo ACCEPT
