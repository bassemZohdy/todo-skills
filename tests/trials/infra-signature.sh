#!/usr/bin/env bash
# Says whether a trial agent's output shows that the ENVIRONMENT, not the skills, stopped it. Read-only.
# Usage: bash tests/trials/infra-signature.sh <file>...    exit 0 and print the matching line when a signature is found, else exit 1
# Signatures seen in real runs:
#   - Git refusing to create refs or directories under .git inside a Codex workspace-write sandbox
#       fatal: cannot lock ref '...': unable to create directory for .git/refs/heads/...
#       fatal: cannot lock ref '...': Unable to create '...lock': Permission denied
#   - the sandbox or an exec policy rejecting a command:  rejected: blocked by policy
#   - an access error on the scratch repo or its worktree folder: Access to the path '...' is denied
#   - the agent itself reporting that .git or the session is read-only, or that the environment does not permit writing under .git
#   - child processes the sandbox will not start:  Error: spawn EPERM (Node's test runner), Git Bash "CreateFileMapping ... Win32 error 5"
# run-codex.sh uses this to write INFRA_ERROR instead of FAIL; it never hides a failed assertion that has no such signature.
for f in "$@"; do
  [ -f "$f" ] || continue
  grep -E -i -m1 \
    -e "cannot lock ref .*(unable to create directory|permission denied)" \
    -e "unable to create directory for \.git" \
    -e "rejected: blocked by policy" \
    -e "Access to the path '.*' is denied" \
    -e "\.git['\` ]+is read-only" \
    -e "\.git[^.]{0,80}read-only" \
    -e "read-only[^.]{0,40}\.git" \
    -e "read-only access to \.git"     -e "does not permit writing under \.git"     -e "spawn EPERM"     -e "CreateFileMapping.*Win32 error 5" "$f" && exit 0
done
exit 1
