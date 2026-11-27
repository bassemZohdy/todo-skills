#!/usr/bin/env bash
# FEAT-148.1: the optional test classes (sanity, smoke, regression). reference/test-tiers.md holds the rule, read only when the
# README has a `Smoke:` line; verification.md and docs/VERIFICATION.md point to it. The load budget of the always-loaded files is
# checked by tests/run.sh ("every command's always-loaded files fit its budget").
# Usage: bash tests/test-smoke-tier.sh      Prints PASS and FAIL lines and a count; tests/run.sh runs it and adds its counts.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ref="$root/plugin/skills/todo/reference/test-tiers.md"
ver="$root/plugin/skills/todo/reference/verification.md"
doc="$root/docs/VERIFICATION.md"
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  smoke-tier: %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  smoke-tier: %s\n' "$1"; }
has() { # has <file> <pattern> <name>
  if [ -f "$1" ] && tr -d '\r' < "$1" | grep -Eq -- "$2"; then ok "$3"; else bad "$3"; fi
}

[ -f "$ref" ] && ok "reference/test-tiers.md exists" || bad "reference/test-tiers.md exists"
has "$ref" 'sanity.*`Done when`' "defines sanity as the node's Done when"
has "$ref" 'smoke.*broad, shallow, fast' "defines smoke as broad, shallow and fast"
has "$ref" 'regression.*broad, deep.*full suite' "defines regression as broad, deep and the full suite"
has "$ref" 'one class tag' "requires one class tag per new test, from the project's own runner"
has "$ref" "project's own runner" "names the project's own runner as the source of the tag"
has "$ref" 'its own count' "compares each class with its own pass count"
has "$ref" '^## Finding the node' "has a section on finding the node that broke a failure seen at the root"
has "$ref" 'no `Smoke:` line.*nothing changes' "says that without a Smoke: line nothing changes"
has "$ref" 'root.s `State:`.*`baseline <n> passing`' "writes the tree's full count into the root's State"
has "$ref" 'baseline red:' "leaves out the ids of a known red baseline when it finds the node"
has "$ref" 'detached worktree' "walks the merges in a temporary detached worktree"
has "$ref" 'Blocked: .*→ `<test command>`.* → ' "gives the Blocked line in the format of the core"
has "$ref" 'takes its baseline and verification from the full suite' "a node that changes the test setup uses the full suite as its baseline"
has "$ref" 'a new test file or a package marker such as `__init__\.py` does not change the test setup' "TASK-150: a new test file or a package marker is not a test setup change (the node keeps smoke)"
has "$ref" 'child node does not run the full suite: it runs only its `Done when` and smoke.*first node.s start.*integration step' "TASK-151: a child node does not run the full suite (the first node's start and the integration step do)"
has "$ver" 'reference/test-tiers\.md' "verification.md points to reference/test-tiers.md"
has "$ver" '`Smoke:`' "verification.md names the Smoke: line"
has "$doc" 'test-tiers' "docs/VERIFICATION.md describes the classes"

printf '%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" = 0 ]
