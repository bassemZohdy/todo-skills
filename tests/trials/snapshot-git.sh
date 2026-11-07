#!/usr/bin/env bash
# Prints the Git state of a scratch repository: what an agent left behind, for the evidence folder. Read-only.
# Usage: bash tests/trials/snapshot-git.sh <repo>
# run-claude.sh and run-codex.sh call it BEFORE assert.sh, because some assertions check out branches.
repo="${1:?usage: snapshot-git.sh <repo>}"
g() { git -C "$repo" "$@" 2>&1; }
echo "## HEAD";            g rev-parse HEAD
echo "## current branch";  g branch --show-current
echo "## branches";        g branch -a -vv
echo "## worktrees";       g worktree list
echo "## tags";            g tag
echo "## refs";            g for-each-ref --format='%(refname) %(objectname)'
echo "## log --all --graph"; g log --all --graph --format='%h %d %s'
echo "## status --porcelain"; g status --porcelain
echo "## stash";           g stash list
echo "## files (excluding .git and .claude)"; (cd "$repo" && find . -path ./.git -prune -o -path ./.claude -prune -o -type f -print | sort) 2>&1
