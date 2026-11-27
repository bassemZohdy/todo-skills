#!/usr/bin/env bash
# TASK-147: tdd-order.sh scores whether a failing test run came before the first source edit in an agent's own session log.
# No agent needed: small synthetic logs, shaped like the real ones (pi session .jsonl, Claude Code stream-json, Codex exec --json).
# Usage: bash tests/trials/test-tdd-order.sh
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

# --- pi: an assistant message holds a toolCall, a later toolResult message answers it (isError true on a non-zero exit)
pi_head() { printf '%s\n' '{"type":"session","version":3,"id":"t"}'; }
pi_call() { printf '{"type":"message","message":{"role":"assistant","content":[{"type":"toolCall","id":"%s","name":"%s","arguments":%s}]}}\n' "$1" "$2" "$3"; }
pi_res()  { printf '{"type":"message","message":{"role":"toolResult","toolCallId":"%s","toolName":"%s","isError":%s,"content":[{"type":"text","text":"%s"}]}}\n' "$1" "$2" "$3" "$4"; }
pi_sh()   { pi_call "$1" powershell "{\"command\":\"$2\"}"; pi_res "$1" powershell "$3" "$4"; }   # id command isError text
pi_ed()   { pi_call "$1" "$2" "{\"path\":\"$3\"}"; pi_res "$1" "$2" false "ok"; }                  # id tool path
# --- Claude Code: tool_use in an assistant event, tool_result in the next user event
cc_head() { printf '%s\n' '{"type":"system","subtype":"init"}'; }
cc_use()  { printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"%s","name":"%s","input":%s}]}}\n' "$1" "$2" "$3"; }
cc_res()  { printf '{"type":"user","message":{"content":[{"type":"tool_result","tool_use_id":"%s","content":"%s","is_error":%s}]}}\n' "$1" "$3" "$2"; }
cc_sh()   { cc_use "$1" Bash "{\"command\":\"$2\"}"; cc_res "$1" "$3" "$4"; }                       # id command isError text
cc_wr()   { cc_use "$1" "$2" "{\"file_path\":\"$3\"}"; cc_res "$1" false ok; }
# --- Codex: command_execution items (exit_code on completion) and file_change items (paths)
cx_head() { printf '%s\n' '{"type":"thread.started","thread_id":"t"}'; }
cx_sh()   { printf '{"type":"item.started","item":{"id":"%s","type":"command_execution","command":"%s","exit_code":null,"status":"in_progress"}}\n{"type":"item.completed","item":{"id":"%s","type":"command_execution","command":"%s","aggregated_output":"","exit_code":%s,"status":"completed"}}\n' "$1" "$2" "$1" "$2" "$3"; }
cx_fc()   { printf '{"type":"item.started","item":{"id":"%s","type":"file_change","changes":[{"path":"%s","kind":"update"}],"status":"in_progress"}}\n{"type":"item.completed","item":{"id":"%s","type":"file_change","changes":[{"path":"%s","kind":"update"}],"status":"completed"}}\n' "$1" "$2" "$1" "$2"; }

T='python3 -m unittest tests.test_calc'
# chk <name> <word> <exit> <log file>: tdd-order.sh prints the word first and exits with the code
chk() {
  local out code
  out="$(bash "$here/tdd-order.sh" "$4" 2>&1)"; code=$?
  case "$out" in "$2"*) [ "$code" = "$3" ] && ok "$1" || bad "$1: exit $code, wanted $3: $out" ;; *) bad "$1: wanted $2, got: $out" ;; esac
}

# pi
{ pi_head; pi_ed a write tests/test_calc.py; pi_sh b "$T" true "AssertionError\\n\\nCommand exited with code 1"; pi_ed c edit calc.py; pi_sh d "$T" false ok; } > "$tmp/pi-pass"
chk "pi: test written, it fails, then the source is edited: PASS" PASS 0 "$tmp/pi-pass"
{ pi_head; pi_ed a edit calc.py; pi_sh b "$T" true "Command exited with code 1"; } > "$tmp/pi-first"
chk "pi: source edited before any test run: FAIL" FAIL 1 "$tmp/pi-first"
{ pi_head; pi_ed a edit calc.py; pi_sh b "$T" true "Command exited with code 1"; pi_ed c edit calc.py; pi_sh d "$T" false ok; } > "$tmp/pi-late"
chk "pi: the failing run comes after the first source edit: FAIL" FAIL 1 "$tmp/pi-late"
{ pi_head; pi_sh a "$T" false ok; pi_ed b edit calc.py; } > "$tmp/pi-green"
chk "pi: the test already passes before the edit (no red run): FAIL" FAIL 1 "$tmp/pi-green"
{ pi_head; pi_sh a "ls nowhere" true "Command exited with code 1"; pi_ed b edit calc.py; } > "$tmp/pi-nottest"
chk "pi: a failing command that is not a test run is not a red run: FAIL" FAIL 1 "$tmp/pi-nottest"
{ pi_head; pi_sh a "Set-Content calc.py x" false ok; pi_sh b "$T" true "Command exited with code 1"; } > "$tmp/pi-shell"
chk "pi: a shell write to a source file counts as a source edit: FAIL" FAIL 1 "$tmp/pi-shell"
{ pi_head; pi_sh a "echo x > tests/test_calc.py" false ok; pi_sh b "$T" true "Command exited with code 1"; pi_ed c edit calc.py; } > "$tmp/pi-shelltest"
chk "pi: a shell write to a test file is not a source edit: PASS" PASS 0 "$tmp/pi-shelltest"
{ pi_head; pi_ed a edit TODO.md; pi_ed b write CHANGELOG.md; pi_sh c "$T" true "Command exited with code 1"; pi_ed d edit calc.py; } > "$tmp/pi-backlog"
chk "pi: backlog edits before the red run are not source edits: PASS" PASS 0 "$tmp/pi-backlog"
{ pi_head; pi_ed a write tests/test_calc.py; pi_sh b "$T" true "Command exited with code 1"; } > "$tmp/pi-na"
chk "pi: no source edit at all (a node blocked at once): N/A" N/A 0 "$tmp/pi-na"

# Claude Code
{ cc_head; cc_wr a Write tests/test_calc.py; cc_sh b "$T" true "Exit code 1"; cc_wr c Edit calc.py; cc_sh d "$T" false ok; } > "$tmp/cc-pass"
chk "claude: test, red run, then the source edit: PASS" PASS 0 "$tmp/cc-pass"
{ cc_head; cc_wr a Edit calc.py; cc_sh b "$T" true "Exit code 1"; } > "$tmp/cc-first"
chk "claude: source edited first: FAIL" FAIL 1 "$tmp/cc-first"
{ cc_head; cc_sh a "sed -i s/a/b/ calc.py" false ok; cc_sh b "$T" true "Exit code 1"; } > "$tmp/cc-shell"
chk "claude: sed -i on a source file counts as an edit: FAIL" FAIL 1 "$tmp/cc-shell"
{ cc_head; cc_sh a "$T" true "Exit code 1"; } > "$tmp/cc-na"
chk "claude: only a red run, no edit: N/A" N/A 0 "$tmp/cc-na"

# Codex
{ cx_head; cx_fc a /work/tests/test_calc.py; cx_sh b "/bin/bash -lc '$T'" 1; cx_fc c /work/calc.py; cx_sh d "/bin/bash -lc '$T'" 0; } > "$tmp/cx-pass"
chk "codex: test, red run, then the source edit: PASS" PASS 0 "$tmp/cx-pass"
{ cx_head; cx_fc a /work/calc.py; cx_sh b "/bin/bash -lc '$T'" 1; } > "$tmp/cx-first"
chk "codex: source edited first: FAIL" FAIL 1 "$tmp/cx-first"
{ cx_head; cx_sh a "/bin/bash -lc 'cat > calc.py'" 0; cx_sh b "/bin/bash -lc '$T'" 1; } > "$tmp/cx-shell"
chk "codex: a shell redirect into a source file counts as an edit: FAIL" FAIL 1 "$tmp/cx-shell"
{ cx_head; cx_sh a "/bin/bash -lc 'git status > /dev/null'" 0; cx_sh b "/bin/bash -lc '$T'" 1; cx_fc c /work/calc.py; } > "$tmp/cx-devnull"
chk "codex: a redirect to /dev/null is not an edit: PASS" PASS 0 "$tmp/cx-devnull"

# the other FAIL paths for Claude Code and Codex: a green run only, and a red run that comes too late
{ cc_head; cc_sh a "$T" false ok; cc_wr b Edit calc.py; } > "$tmp/cc-green"
chk "claude: the test already passes before the edit (no red run): FAIL" FAIL 1 "$tmp/cc-green"
{ cc_head; cc_wr a Edit calc.py; cc_sh b "$T" true "Exit code 1"; cc_wr c Edit calc.py; } > "$tmp/cc-late"
chk "claude: the failing run comes after the first source edit: FAIL" FAIL 1 "$tmp/cc-late"
{ cc_head; cc_sh a "grep -rn pytest ." true "Exit code 1"; cc_wr b Edit calc.py; } > "$tmp/cc-grep"
chk "claude: a grep that names pytest and finds nothing is not a red run: FAIL" FAIL 1 "$tmp/cc-grep"
{ cx_head; cx_sh a "/bin/bash -lc '$T'" 0; cx_fc b /work/calc.py; } > "$tmp/cx-green"
chk "codex: the test already passes before the edit (no red run): FAIL" FAIL 1 "$tmp/cx-green"
{ cx_head; cx_fc a /work/calc.py; cx_sh b "/bin/bash -lc '$T'" 1; cx_fc c /work/calc.py; } > "$tmp/cx-late"
chk "codex: the failing run comes after the first source edit: FAIL" FAIL 1 "$tmp/cx-late"
{ cx_head; cx_sh a "/bin/bash -lc 'npm install'" 0; cx_sh b "/bin/bash -lc '$T'" 1; cx_fc c /work/calc.py; } > "$tmp/cx-install"
chk "codex: an install before the red run is not a source edit: PASS" PASS 0 "$tmp/cx-install"
# the paths of Codex and Claude Code are absolute: a workspace below a tests/ folder must not hide its source files
W=/home/u/tests/trials/ws
{ cx_head; cx_fc a "$W/tests/test_calc.py"; cx_sh b "/bin/bash -lc '$T'" 1; cx_fc c "$W/calc.py"; } > "$tmp/cx-abs-pass"
chk "codex: absolute paths below a tests/ folder, test then red then source: PASS" PASS 0 "$tmp/cx-abs-pass"
{ cx_head; cx_fc a "$W/calc.py"; cx_sh b "/bin/bash -lc '$T'" 1; } > "$tmp/cx-abs-fail"
chk "codex: an absolute source path below a tests/ folder is still a source edit: FAIL" FAIL 1 "$tmp/cx-abs-fail"
# a file_change whose paths only arrive when it completes
{ cx_head; printf '%s\n' '{"type":"item.started","item":{"id":"z","type":"file_change","changes":[],"status":"in_progress"}}' '{"type":"item.completed","item":{"id":"z","type":"file_change","changes":[{"path":"/work/calc.py","kind":"update"}],"status":"completed"}}'; cx_sh b "/bin/bash -lc '$T'" 1; } > "$tmp/cx-late-paths"
chk "codex: paths that arrive only on completion count: FAIL" FAIL 1 "$tmp/cx-late-paths"
# shell writes that an unwary pattern misses
{ cc_head; cc_sh a "sed -E -i s/a/b/ calc.py" false ok; cc_sh b "$T" true "Exit code 1"; } > "$tmp/cc-sed"
chk "claude: sed with -i after another option is a source edit: FAIL" FAIL 1 "$tmp/cc-sed"
{ cc_head; cc_sh a "python3 -c open(1).write(2)" false ok; cc_sh b "$T" true "Exit code 1"; } > "$tmp/cc-pywrite"
chk "claude: a python write is a source edit: FAIL" FAIL 1 "$tmp/cc-pywrite"
{ cc_head; cc_sh a "echo x 1> calc.py" false ok; cc_sh b "$T" true "Exit code 1"; } > "$tmp/cc-fd1"
chk "claude: a redirect with a file descriptor number is a source edit: FAIL" FAIL 1 "$tmp/cc-fd1"
{ cc_head; cc_sh a "$T 2>&1" true "Exit code 1"; cc_wr b Edit calc.py; } > "$tmp/cc-2to1"
chk "claude: 2>&1 is not a file write and the run before the edit is red: PASS" PASS 0 "$tmp/cc-2to1"

# usage errors exit 2
printf 'not json at all\n' > "$tmp/junk"
chk "an unrecognized log format: exit 2" ERROR 2 "$tmp/junk"
chk "a missing file: exit 2" ERROR 2 "$tmp/nothing-here"

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
