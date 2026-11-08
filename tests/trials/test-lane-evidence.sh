#!/usr/bin/env bash
# Checks that the lane evidence records worktree use without inferring worker concurrency,
# without an agent: it drives git by hand in the `lanes` scenario's repo, whose hooks write the event log.
# Usage: bash tests/trials/test-lane-evidence.sh    Works in a temporary directory that it removes at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }
g() { git -c user.email=t@t -c user.name=t "$@"; }
ev() { bash "$here/lane-evidence.sh" "$1" | sed -n "s/^$2: //p"; }

fresh() { # fresh <name>: a new `lanes` repo with its hooks
  bash "$here/setup.sh" "$tmp/$1" lanes >/dev/null 2>&1 || { bad "setup lanes for $1"; return 1; }
}
step() { # step <worktree> <file>: one commit in that worktree
  ( cd "$1" && echo x >> "$2" && g add "$2" && g commit -q -m "chore: $2" ) >/dev/null 2>&1; sleep 0.05
}

# 1. overlapping: two worktrees take turns
fresh over || exit 1
g -C "$tmp/over" worktree add -q "$tmp/over.todo/a" -b todo/a >/dev/null 2>&1; g -C "$tmp/over" worktree add -q "$tmp/over.todo/b" -b todo/b >/dev/null 2>&1
step "$tmp/over.todo/a" a1; step "$tmp/over.todo/b" b1; step "$tmp/over.todo/a" a2; step "$tmp/over.todo/b" b2
g -C "$tmp/over" worktree remove --force "$tmp/over.todo/a"; g -C "$tmp/over" worktree remove --force "$tmp/over.todo/b"
[ "$(g -C "$tmp/over" worktree list | wc -l | tr -d ' ')" = 1 ] && ok "overlap case ends with a clean worktree list" || bad "overlap case worktree list"
[ "$(ev "$tmp/over" worktrees)" = 2 ] && ok "overlapping lanes: 2 worktrees seen after both were removed" || bad "overlapping: worktrees=$(ev "$tmp/over" worktrees)"
[ "$(ev "$tmp/over" execution)" = unverified ] && ok "interleaved commits in two worktrees: unverified" || bad "overlapping: execution=$(ev "$tmp/over" execution)"

# 2. sequential: lane a finishes before lane b starts
fresh seq || exit 1
g -C "$tmp/seq" worktree add -q "$tmp/seq.todo/a" -b todo/a >/dev/null 2>&1
step "$tmp/seq.todo/a" a1; step "$tmp/seq.todo/a" a2
g -C "$tmp/seq" worktree add -q "$tmp/seq.todo/b" -b todo/b >/dev/null 2>&1
step "$tmp/seq.todo/b" b1; step "$tmp/seq.todo/b" b2
g -C "$tmp/seq" worktree remove --force "$tmp/seq.todo/a"; g -C "$tmp/seq" worktree remove --force "$tmp/seq.todo/b"
[ "$(ev "$tmp/seq" worktrees)" = 2 ] && ok "sequential lanes: 2 worktrees seen" || bad "sequential: worktrees=$(ev "$tmp/seq" worktrees)"
[ "$(ev "$tmp/seq" execution)" = unverified ] && ok "worktree event order alone: unverified" || bad "sequential: execution=$(ev "$tmp/seq" execution)"

# 3. no worktree: branches checked out in the main checkout only; the final worktree count looks identical
fresh none || exit 1
g -C "$tmp/none" switch -q -c todo/a; step "$tmp/none" a1; g -C "$tmp/none" switch -q main; g -C "$tmp/none" switch -q -c todo/b; step "$tmp/none" b1; g -C "$tmp/none" switch -q main
[ "$(g -C "$tmp/none" worktree list | wc -l | tr -d ' ')" = 1 ] && ok "no-worktree case also ends with a clean worktree list" || bad "none case worktree list"
[ "$(ev "$tmp/none" execution)" = none ] && [ "$(ev "$tmp/none" worktrees)" = 0 ] && ok "no lane worktree used: execution none" || bad "none: $(bash "$here/lane-evidence.sh" "$tmp/none" | tr '\n' ' ')"

# 4. assert.sh uses the evidence: the lanes check fails when no lane worktree was used
if bash "$here/assert.sh" "$tmp/none" lanes 2>&1 | grep -q 'FAIL  lane work ran in separate worktrees'; then ok "assert.sh lanes fails the worktree-use check without lane worktrees"; else bad "assert.sh lanes does not check worktree use"; fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
