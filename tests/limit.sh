#!/usr/bin/env bash
# Tests tools/todo-limit.sh (FEAT-134.3.1), the optional helper that runs a command line under a time limit: a command that
# ends in time keeps its exit status and its output, and a command over the limit is stopped with everything it started.
# Usage: bash tests/limit.sh      Prints PASS/FAIL lines and a count; tests/run.sh runs it and adds its counts to its own.
# Needs bash, sleep, ps, awk and python3. Works in a temporary directory that it removes at the end. Takes about 40 seconds.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lim="$root/tools/todo-limit.sh"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  limit: %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  limit: %s\n' "$1"; }
# run <seconds> <command line>: runs the helper in $tmp and sets out, err, rc and took (whole seconds).
run() {
  local t0="$SECONDS"
  out="$(cd "$tmp" && bash "$lim" "$1" "$2" 2> "$tmp/err")"; rc=$?
  err="$(cat "$tmp/err")"; took=$((SECONDS - t0))
}

run 30 'echo to-out; echo to-err >&2; exit 3'
[ "$rc" -eq 3 ] && [ "$out" = "to-out" ] && [ "$err" = "to-err" ] \
  && ok "a command that ends in time keeps its exit status, its output and its error output" || bad "in time, exit 3: rc=$rc out='$out' err='$err'"
[ "$rc" -eq 3 ] && [ "$took" -lt 15 ] && ok "the helper returns when the command ends, not when the limit ends (the watchdog does not hold the output open)" || bad "a finished command under a 30 second limit: rc=$rc after ${took}s"
run 30 'true'
[ "$rc" -eq 0 ] && [ -z "$out" ] && [ -z "$err" ] && ok "a passing command passes, and the helper adds no output of its own" || bad "true: rc=$rc out='$out' err='$err'"
# FIX-142: bash 3.2 (macOS) tells on its stderr that the watchdog it stopped was "Terminated", when it reaps the job, so
# the helper's reaping is a group with its stderr discarded. Linux and Windows print nothing either way: the loop can fail
# only on macOS, and the text check below fails everywhere without the group.
t_bad=""; t_i=0
while [ "$t_i" -lt 3 ]; do run 30 'true'; { [ "$rc" -eq 0 ] && [ -z "$out" ] && [ -z "$err" ]; } || t_bad="$t_bad [run $t_i: rc=$rc out='$out' err='$err']"; t_i=$((t_i + 1)); done
grep -qxF '{ if [ "$signalled" -eq 1 ] && [ "$fired" -eq 0 ]; then kill "$watch"; fi; wait "$watch"; } 2>/dev/null' "$lim" || t_bad="$t_bad [the kill and the wait of the watchdog are not one group with 2>/dev/null]"
grep -qxF 'if [ "$fired" -eq 1 ] && [ "$wrc" -ne 0 ]; then { wait "$watch"; } 2>/dev/null; wrc=$?; fi   # the first wait was cut short by USR1' "$lim" || t_bad="$t_bad [the second wait of the watchdog is not a group with 2>/dev/null]"
grep -qxF '{ wait "$pid"; } 2>/dev/null   # a command that a signal ended is reported by bash 3.2 as well: discarded' "$lim" && [ "$(grep -cxF '  { wait "$pid"; } 2>/dev/null' "$lim")" = 1 ] || t_bad="$t_bad [the waits for the command are not groups with 2>/dev/null]"
[ -z "$t_bad" ] && ok "a command that ends in time leaves nothing on stderr, three times over, and the watchdog is reaped inside a group that discards a job message (FIX-142)" || bad "stderr of a passing command:$t_bad"
mkdir "$tmp/pkg" && echo inside > "$tmp/pkg/f"
run 30 'cd pkg && cat f'
[ "$rc" -eq 0 ] && [ "$out" = "inside" ] && ok "a command line with cd and && runs as one line" || bad "cd pkg && cat f: rc=$rc out='$out' err='$err'"
run 30 'cat'
[ "$rc" -eq 0 ] && [ "$took" -lt 15 ] && ok "a command that waits for input reads end of file and ends" || bad "cat: rc=$rc after ${took}s"

run 2 'sleep 60'
[ "$rc" -eq 124 ] && [ "$took" -lt 30 ] && ok "a command over its limit is stopped and the helper fails with exit status 124" || bad "sleep 60 under a 2 second limit: rc=$rc after ${took}s"
printf '%s\n' "$err" | grep -q 'stopped after 2s: sleep 60' && ok "the helper says on stderr that it stopped the command, and after how long" || bad "no stop line on stderr: '$err'"
run 1 "trap '' TERM; sleep 60"
[ "$rc" -eq 124 ] && [ "$took" -lt 30 ] && ok "a command that ignores TERM is killed after the grace" || bad "a command that ignores TERM: rc=$rc after ${took}s"

# What the command started must stop with it: a shell child and a child of another program would each write a file later.
run 1 '(sleep 6; echo late > late-shell) & sleep 60'
r1="$rc"
run 1 "python3 -c \"import subprocess, sys, time; subprocess.Popen([sys.executable, '-c', 'import time; time.sleep(6); open(\\\"late-program\\\", \\\"w\\\").write(\\\"x\\\")']); time.sleep(60)\""
r2="$rc"
sleep 7
[ "$r1" -eq 124 ] && [ ! -e "$tmp/late-shell" ] && ok "a background child of the command line is stopped with it" || bad "a shell child outlived the limit: rc=$r1 $(ls "$tmp")"
[ "$r2" -eq 124 ] && [ ! -e "$tmp/late-program" ] && ok "a process started by another program is stopped with it" || bad "a program's child outlived the limit: rc=$r2 $(ls "$tmp") err='$err'"

# It must work where no timeout program exists: one on PATH that would leave a file is never called.
mkdir "$tmp/bin" && printf '#!/bin/sh\necho called > "%s/timeout-called"\nexit 99\n' "$tmp" > "$tmp/bin/timeout" && chmod +x "$tmp/bin/timeout"
out="$(cd "$tmp" && PATH="$tmp/bin:$PATH" bash "$lim" 1 'sleep 60' 2>/dev/null)"; rc=$?
[ "$rc" -eq 124 ] && [ ! -e "$tmp/timeout-called" ] && ok "the helper does not use a timeout program" || bad "the timeout program was called, or rc=$rc"

# Two places where the helper cannot work as usual: a caller that ignores USR1, the signal the helper's watchdog reports
# with, and a system whose ps lists no parents.
out="$(cd "$tmp" && trap '' USR1 && bash "$lim" 1 'sleep 60' 2> "$tmp/err")"; rc=$?
[ "$rc" -eq 124 ] && grep -q 'stopped after 1s' "$tmp/err" && ok "a caller that ignores USR1 still gets exit status 124 and the stop line" || bad "USR1 ignored: rc=$rc err='$(cat "$tmp/err")'"
out="$(cd "$tmp" && trap '' USR1 && bash "$lim" 30 'echo quick; exit 4' 2> "$tmp/err")"; rc=$?
[ "$rc" -eq 4 ] && [ "$out" = "quick" ] && ok "a caller that ignores USR1 still gets the exit status of a command that ended in time" || bad "USR1 ignored, in time: rc=$rc out='$out' err='$(cat "$tmp/err")'"
mkdir "$tmp/nops" && printf '#!/bin/sh\nexit 1\n' > "$tmp/nops/ps" && chmod +x "$tmp/nops/ps"
out="$(cd "$tmp" && PATH="$tmp/nops:$PATH" bash "$lim" 1 'sleep 60' 2> "$tmp/err")"; rc=$?
[ "$rc" -eq 124 ] && grep -q 'ps lists no parents here' "$tmp/err" && ok "where ps lists no parents the command itself is still stopped, and the stop line says what was not" || bad "no ps: rc=$rc err='$(cat "$tmp/err")'"

u_bad=""
bash "$lim" > /dev/null 2>&1; [ "$?" -eq 2 ] || u_bad="$u_bad [no arguments]"
bash "$lim" 5 > /dev/null 2>&1; [ "$?" -eq 2 ] || u_bad="$u_bad [no command]"
bash "$lim" 5 '' > /dev/null 2>&1; [ "$?" -eq 2 ] || u_bad="$u_bad [empty command]"
bash "$lim" abc 'true' > /dev/null 2>&1; [ "$?" -eq 2 ] || u_bad="$u_bad [seconds not a number]"
bash "$lim" 0 'true' > /dev/null 2>&1; [ "$?" -eq 2 ] || u_bad="$u_bad [zero seconds]"
bash "$lim" 5 echo hi > /dev/null 2>&1; [ "$?" -eq 2 ] || u_bad="$u_bad [command not one argument]"
bash "$lim" 5 'true' 2>&1 | grep -q usage && u_bad="$u_bad [usage printed on a good call]"
[ -z "$u_bad" ] && ok "wrong usage fails with exit status 2 and runs nothing" || bad "usage:$u_bad"
bash "$lim" --version | grep -qE '^todo-limit\.sh [0-9]+\.[0-9]+\.[0-9]+$' && ok "--version prints the release stamp" || bad "--version: $(bash "$lim" --version 2>&1)"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
