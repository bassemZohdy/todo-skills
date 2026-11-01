# Git flow and conflicts

Loaded by `/todo-continue` and by `/todo-update` when it claims or releases. Part of the `todo` core skill.

## Git flow

One branch per node: `todo/<ID>-<slug>`. Slug: the title lowercased, punctuation turned into spaces, the words a, an, the, to, of, and, for, with dropped, the first 4 words left, joined with hyphens (`calc.py` counts as two words, `calc` and `py`; empty means `task`).

- **Base branch.** The first that exists of `main`, `master`, `trunk`, `develop`, unless the user names another.
- **Branch chain.** A root branches from the base, a child from its parent's branch. When the first leaf of a tree is claimed, create the missing ancestor branches top-down, then the leaf's. Ancestors get `State: branch <name>[ from <base>]; next: build children` (written in the leaf's start commit) until they complete.
- **Tree claim** (so no one runs the same tree twice), once per tree, right after the root branch is created:
  1. Before creating it, read `git show <base>:TODO.md` (a `TODO.md` the base does not have yet means no claim). If the root's `State:` already names a branch, stop and report it. Never reuse a `todo/<ID>-…` branch that is not yours.
  2. Commit only backlog files on the root branch as `chore(backlog): claim <ROOT-ID> on <branch>`: the root gets `State: branch todo/<ID>-<slug> from <base>; next: build children` (leaf root: `next: start <ID>`), plus pending backlog edits (new tasks). The marker stays `[ ]`.
  3. Fast-forward the base to it: `git merge --ff-only <root branch>` in the worktree where the base is checked out (or `git switch <base>` first, then always switch back to the root branch, even when the merge failed).
  4. If that fails, read the base's claim again. Another branch took the tree: from the base branch, delete your new root branch with `git branch -D` (the only forced delete the skills make, and only when `git log <base>..<branch>` shows exactly your one claim commit; with more commits, leave the branch and report it), report who has it, and stop. Otherwise the base only moved: `git rebase <base>` the claim-only branch once and fast-forward again. If that also fails, stop and tell the user (your unpublished claim branch may stay; a rerun may delete it the same way under the same check and start again).
- **Read claims from the base.** A tree branch only knows its own claim, so take every root's claim from `git show <base>:TODO.md` too. A root is **claimed** when its `State:` there names a branch; its tree is workable only from a branch of that family (`todo/<ROOT-ID>-…` or `todo/<ROOT-ID>.…`). Otherwise skip it and report `claimed by <branch>`. If that branch no longer exists in this clone, the claim is stale: `/todo-update <ROOT-ID> --status ready` releases it.
- **Sharing is git's job.** The claim is a local commit. The skills never fetch, pull or push; how a claim reaches other clones is your usual flow.
- **Claim on the node's branch.** Switch to the branch first, then set `[/]`, write `State:`, commit `chore(backlog): start <ID>` (skip if nothing changed). `--worktree` makes the branch and claim commit first, then `git worktree add ../<repo>.todo/<ID> <branch>`.
- **Clean tree.** Untracked files, `TODO.md`, `CHANGELOG.md` and generated files (`__pycache__`, `*.pyc`, `dist/`, `build/`, `target/`, `node_modules/`, `*.log`) do not count. Any other change: stop and offer commit, stash or `--worktree`.
- **Staging.** Explicit paths only: the node's files, `TODO.md`, and `CHANGELOG.md` only if a skill changed it. Never `git add -A` or `.`.
- **Merging.** A verified node is committed on its branch, then merged `--no-ff` into its parent's branch and its branch deleted with `git branch -d` (with a worktree, `git worktree remove` first). Commit subject: `<type>(<scope>): <title>`, scope the top-level directory or module (the package name in a monorepo), title lowercase, no final period, body `Refs: <ID>`. Merge message: `Merge <ID> into <PARENT-ID>` (a root: `Merge <ROOT-ID> into <base>`).
- **Refresh before a root lands.** After the root's integration step and before the drain, `git merge <base>` into the root branch. Message `Merge <base> into <ROOT-ID>`. If it brought changes, rerun `Done when` and the full regression; block the root if red.
- **Root.** Drain it, then merge into the base only with `--merge`. Otherwise print the local merge (`git switch <base> && git merge --no-ff <branch>`) and the push-and-pull-request steps, and run neither. Apart from the tree claim, a claim release, `/todo-release` and a verified root merge, nothing reaches the base.
- **Backlog edits** by `/todo-add`, `/todo-update` and `/todo-init` stay uncommitted until the next claim commit carries them. Add new roots on the base branch; children and `--from` follow-ups can be added on the tree's branch.
- **Revert** a bad merge with `git revert -m 1 <merge>` and `/todo-update <ID> --status revert`.

## Git conflicts

- Never take one side wholesale (`--ours`/`--theirs`) on TODO.md or CHANGELOG.md.
- **CHANGELOG.md**: keep both sides' entries, drop duplicates of the same ID.
- **TODO.md**: keep the union of task blocks. If two roots share an ID, keep the one already in the base, renumber the newer one and its subtree, and rewrite every `Depends:` and `From:` that pointed into it. If an ID is now in both files, remove it from TODO.md.
- **Source files**: inside the node's scope, resolve minimally and rerun `Done when`; otherwise stop and ask.
- One agent per working tree. Use `--worktree` or lanes (`/todo-continue --all-lanes`) for parallel work.
