#!/usr/bin/env bash
# TASK-147: scores test-first order from an agent's own session log, not from its report.
# Usage: bash tests/trials/tdd-order.sh <session-log>
# Log formats, found by their first records: a pi session .jsonl, Claude Code `--output-format stream-json --verbose`
# output, Codex `exec --json` events. Prints one line, the verdict first, and exits:
#   PASS   0  a test run failed before the first source edit (the red run)
#   FAIL   1  the first source edit came before any failing test run: no test run, only green runs, or a red run too late
#   N/A    0  the log holds no source edit (for example a node blocked at once); there is no order to score
#   ERROR  2  no log, or a format that is not recognized
# What counts: a source edit is a file tool call (edit, write, Write, Edit, MultiEdit, a Codex file_change) or a shell command
# that writes (redirect, sed -i, tee, Set-Content, Out-File, apply_patch, git apply, cp, mv and the like) to a path that is not a
# test file (test_*, *_test.*, *.test.*, *.spec.*, a tests/ or spec/ folder), not TODO.md, CHANGELOG.md or docs/plans/, and not
# a *.log file or /dev/null. A shell write with no recognizable target counts as a source edit, so an unreadable command can
# only make the verdict stricter. A failing test run is a shell command that names a test runner (unittest, pytest, jest,
# vitest, mocha, mvn, gradle, npm/yarn/pnpm test, node --test, go/cargo/dotnet test, make test, bash tests/*.sh and the like) and
# whose result is an error: a non-zero exit code taken from the tool result, never from the agent's report or a Red: line.
# Limits, all in the stricter direction: a test run piped into another command (pytest | tail) reports the last command's exit
# code, so a red run can look green; a path is judged below the project (the log's cwd, else the folder its absolute edit paths
# share), and one outside it by its file name alone.
# The caller decides which runs the check applies to: a TASK refactor (its characterization tests pass before and after) and a
# resumed node (the red run happened in an earlier session) start without a red run by design.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log="${1:-}"
if [ -z "$log" ] || [ ! -f "$log" ]; then echo "ERROR: usage: tdd-order.sh <session-log> (no such file: ${log:-none})"; exit 2; fi
python3 -I "$here/tdd-order.py" "$log"
