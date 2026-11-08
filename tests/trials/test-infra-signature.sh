#!/usr/bin/env bash
# Checks that infra-signature.sh recognises sandbox and permission blocks and nothing else. No agent needed.
# Usage: bash tests/trials/test-infra-signature.sh    Works in a temporary directory that it removes at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }
sig() { printf '%s\n' "$2" > "$tmp/$1.txt"; bash "$here/infra-signature.sh" "$tmp/$1.txt" >/dev/null 2>&1; }

sig a "fatal: cannot lock ref 'refs/heads/todo/FEAT-001-x': unable to create directory for .git/refs/heads/todo/FEAT-001-x" && ok "git cannot create a ref directory under .git" || bad "ref directory block missed"
sig b "fatal: cannot lock ref 'refs/heads/b': Unable to create 'C:/r/.git/refs/heads/b.lock': Permission denied" && ok "git cannot create a ref lock (permission denied)" || bad "ref lock block missed"
sig c "exec_command failed: CreateProcess { message: \"Rejected(\\\"... rejected: blocked by policy\\\")\" }" && ok "command rejected by policy" || bad "policy rejection missed"
sig d "Set-Content : Access to the path 'C:\\x\\y.txt' is denied." && ok "access to a path denied" || bad "access denied missed"
sig e "Stopped: .git is read-only in this session." && ok "agent reports .git read-only" || bad "read-only report missed"
sig h "npm test exited 1 because Node's test runner could not spawn a process: Error: spawn EPERM" && ok "node cannot spawn a child process (EPERM)" || bad "spawn EPERM missed"
sig i "Git Bash failed to start with CreateFileMapping ... Win32 error 5" && ok "Git Bash cannot start in the sandbox" || bad "CreateFileMapping error missed"
sig j "The environment does not permit writing under .git/, so the pre-push hook was not created." && ok "agent reports no writes under .git" || bad ".git write report missed"
sig k "the required branch and worktree operations need writes to .git, which this session's filesystem permissions make read-only" && ok "writes to .git described as read-only in a longer sentence" || bad "long read-only sentence missed"
sig l "the environment does not permit writes under \`.git/\`. To install it yourself, put these lines in .git/hooks/pre-push" && ok "agent reports writes under .git not permitted (TASK-045 ci-local)" || bad "'does not permit writes under .git' missed"
sig m "python3 -m unittest discover -s tests could not run: The system cannot execute the specified program." && ok "Windows cannot start the test program (TASK-045)" || bad "'cannot execute the specified program' missed"
sig n "exit 1: python3.exe cannot be accessed by the system. No tests ran" && ok "Windows refuses access to the test program (TASK-045)" || bad "'cannot be accessed by the system' missed"
sig o "mvn -B test could not run: Maven reported Could not create local repository at C:\.m2\repository" && ok "Maven cannot create its local repository (TASK-045)" || bad "Maven local repository block missed"
sig f "FAIL  subtract and its test on main. The test failed: AssertionError: -1 != 3" && bad "an ordinary assertion failure was taken for infrastructure" || ok "an ordinary test failure is not infrastructure"
sig g "Merge conflict in calc.py; I resolved it and committed." && bad "a merge conflict was taken for infrastructure" || ok "a merge conflict is not infrastructure"
bash "$here/infra-signature.sh" "$tmp/does-not-exist.txt" >/dev/null 2>&1 && bad "a missing file matched" || ok "a missing file is not infrastructure"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
