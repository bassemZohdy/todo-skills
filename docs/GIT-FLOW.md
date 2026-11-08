# Git flow

How the skills use git: one branch per task, a claim on the base branch so no tree runs twice, explicit staging, fixed commit and merge messages, and conflict rules for the backlog files. The rules the model follows are in [`plugin/skills/todo/reference/git-flow.md`](../plugin/skills/todo/reference/git-flow.md) and the core's "Git mode".

The skills' own git commands never touch the network: no fetch, pull, push or tag. They never reset hard, clean or force-push. A test command may still download dependencies; when it fails for lack of network, the node is blocked with that reason.

## The base branch and the main checkout

- **Base branch:** the one you name, otherwise the README `Base: <branch>` line, otherwise the first that exists of `main`, `master`, `trunk`, `develop`. With none of them the agent asks once. When you name a base other than that default, it offers to add the `Base:` line to README.
- **Main checkout:** the first entry of `git worktree list`. Every step that checks out or merges into the base (tree claim, claim release, merge into the base, release) runs there. From a linked worktree the agent changes to it first; if it is on another branch with changes, it stops and prints the commands.

## Branches

One branch per node: `todo/<ID>-<slug>`. The slug is the title lowercased, punctuation turned into spaces (`calc.py` gives `calc` and `py`), the words a, an, the, to, of, and, for, with dropped, and the first 4 remaining words joined by hyphens (`task` when nothing is left). Example: "Add token refresh to the auth service" gives `todo/FEAT-002-add-token-refresh-auth`.

A root branches from the base, a child from its parent's branch, so a tree of 3 levels has at most 3 open branches. Ancestors carry `State: branch <name> from <parent branch>; next: build children` until they complete.

## Tree claims

A tree is claimed when its root's `State:` **in the base branch's** `TODO.md` names a branch. The claim tells every other session that starts from the base to skip the tree. Only the root's claim is published; `[/]`, `[x]` and the children's `State:` stay on the tree's branches until the root lands.

The first node of a tree claims it, each step only after the previous one succeeded:

1. Read `git show <base>:TODO.md`. If the root already names a branch, stop and report it. A root that is in your uncommitted `TODO.md` but not yet in the committed base is claimable: its pending backlog edits are carried into the claim.
2. Create the root branch from the base. If it already exists and is a **bare claim branch** of your own (exactly one claim commit that changes only the root's `State:` line in `TODO.md`) checked out nowhere, it is deleted and recreated; anything else stops with a suggestion to rename it.
3. Commit the claim on it, staging only backlog files: the root gets `State: branch todo/<ROOT-ID>-<slug> from <base>; next: build children` (a leaf root: `next: start <ROOT-ID>`); its marker stays `[ ]`. Subject: `chore(backlog): claim <ROOT-ID> on <branch>`.
4. Publish it: `git switch <base> && git merge --ff-only <root branch>`, then switch back.
5. If the fast-forward failed, read the base again:
   - **Lost or collided** (another branch claimed the root, or a different root with the same ID appeared): a bare claim branch is force-deleted (the only forced delete the skills make); otherwise the branch is kept with your pending backlog, and the agent prints `git checkout <branch> -- <paths>` so you can restore it. It reports the winner and stops on the base.
   - **The base only moved:** rebase the claim branch onto the base (backlog conflicts resolved by the rules below, anything else aborts), lint, fast-forward again. If the base changed other files, the baseline is taken again.
6. Only then create the missing ancestor branches top-down and the node's branch.

A claim is a local commit. Worktrees of one repository see it at once; it reaches other clones the way any commit does, and a clash shows up as an ordinary merge conflict. A claim whose branch no longer exists in this clone is **stale**: `/todo-update <ROOT-ID> --status ready` releases it with a `chore(backlog): release <ID>` commit on the base. Releasing a live claim needs an explicit yes, and the owner's branch keeps its state.

## Starting, resuming and recovering

- **Start commit:** on the node's branch, set `[/]`, write `State:`, commit `chore(backlog): start <ID>` with any pending backlog edits. A node that already has its own branch (earlier work) switches to it instead of creating it.
- **Interrupted work comes first.** On a tree branch the agent lists the tree's branches and reads each one's node: an `[x]` node not yet merged into its parent's branch gets that merge finished (and nothing else); a `[/]` node is resumed, deepest first; a node that is `[!]` on any of the tree's branches counts as blocked everywhere; a branch already merged into its parent is deleted with `git branch -d`.
- **Hotfix while a tree is claimed:** commit or stash, `git switch <base>`, `/todo-add "…" --type fix --priority P0`, `/todo-continue`. Claimed trees are skipped on the base, so the P0 root is picked and gets its own branch. Then switch back to the parked tree's branch and `/todo-continue` resumes it.

## `--worktree`

`/todo-continue --worktree` keeps the main checkout where it is. For an unclaimed tree it creates the root branch with `git branch`, adds a worktree at `../<repo>.todo/<ROOT-ID>` (`<repo>` is the main checkout's folder name), takes the baseline there, commits the claim there, and fast-forwards the base from the main checkout when that is on the base (otherwise it prints the command). Each node gets its own worktree (`../<repo>.todo/<ID>`; a leaf root uses the root's), which is removed after the node merges into its parent. Pending backlog edits in the main checkout refuse `--worktree`: run once without it so the claim commits them.

Lane runs (`--all-lanes`) use the same layout, one worktree per lane root, kept until the root lands ([PLANNING.md](PLANNING.md#lanes)).

## Clean tree and staging

- **Clean tree:** untracked files, backlog files and generated files (`__pycache__`, `*.pyc`, `dist/`, `build/`, `target/`, `node_modules/`, `*.log`) do not count. Any other change stops the command, which offers commit, stash or `--worktree`.
- **Staging:** explicit paths only, `git add <path>…` then `git commit -- <path>…`, so nothing staged earlier rides along. Never `git add -A`, `.` or `-p`. Backlog edits earlier todo-* commands left uncommitted go into the next claim or start commit; the agent asks only about edits no skill made ([FILES.md](FILES.md#backlog-files-and-when-they-are-committed)).

## Commit messages

**Node commits:** `<type>(<scope>): <title>`, where the type is `feat`, `fix` or the fitting conventional type for a `TASK`, the scope is the package in a monorepo, otherwise the module or top-level directory of the main change (never `tests`), and the title is lowercase without a final period. The body:

```text
Refs: FEAT-002.1
Red: AssertionError: expected 401, got 200
Reviewed: subagent, spec fail quality ok, 2 findings fixed
Checked: make smoke
```

`Reviewed:` is `Reviewed: subagent, spec <ok|fail> quality <ok|fail>, <n> findings fixed` (the reviewer's first-round verdicts) or `Reviewed: self, <n> findings fixed`. `Red:` appears on leaves that started red, and one `Checked:` line names each command the lint flagged as an unfamiliar runner (W3) that the agent judged safe.

**Backlog commits** have no body, except a drain (`Refs:` and `Includes:`) and a plan (the plan itself):

| Subject | Made by |
|---|---|
| `chore(backlog): claim <ROOT-ID> on <branch>` | The first node of a tree |
| `chore(backlog): start <ID>` | Every node, on its branch |
| `chore(backlog): plan <ID>` | `/todo-continue --plan` |
| `chore(backlog): pending edits <IDs>` | Leaving a `todo/` branch with backlog edits |
| `chore(backlog): decompose <ID>` | Breaking down a `next: decompose` node on a tree branch |
| `chore(backlog): block <ID>` | A blocked node (with its changed files) |
| `chore(backlog): ready <ID>`, `drop <ID> - <reason>`, `revert <ID>` | `/todo-update` on a `todo/` branch |
| `chore(backlog): release <ID>` | `/todo-update --status ready` on a claimed root, on the base |
| `chore(backlog): drain <ID>` | A finished root |
| `chore(release): X.Y.Z` | `/todo-release`, `CHANGELOG.md` only |

## Merges

| Message | When |
|---|---|
| `Merge <ID> into <PARENT-ID>` | A verified node, `git merge --no-ff` into its parent's branch, then `git branch -d` the child |
| `Merge <base> into <ID>` | Before a node starts, when a `Depends:` is satisfied only by the base's CHANGELOG; and the refresh of a root before it lands |
| `Merge <ROOT-ID> into <base>` | A drained root, with `--merge` |

- **Refresh before a root lands:** after the root's last verify and before the drain, `git merge <base>` into the root branch. If anything came in, `Done when` and the full regression run again on the merged result; red blocks the root.
- **Into the base:** only with `--merge`, from the main checkout and only when it is clean (backlog files included). If the base moved since the refresh, the root is refreshed and verified again first. Without `--merge` the agent prints `git switch <base> && git merge --no-ff -m "Merge <ROOT-ID> into <base>" <root branch> && git branch -d <root branch>` (with `git worktree remove` first when there is one) and the push-and-pull-request alternative, and runs none of them.
- **Concluding a merge** after resolving conflicts: `git commit --no-edit`.
- **Reverting a bad merge:** `/todo-update <ID> --status revert` resets the backlog and prints `git revert --no-commit -m 1 <merge commit>`, `git checkout HEAD -- TODO.md CHANGELOG.md`, `git commit -m "Revert <ID>"` for you.

## Conflicts

- Never take one side wholesale (`--ours`/`--theirs`) on `TODO.md` or `CHANGELOG.md`.
- **CHANGELOG.md:** keep both sides' entries and drop duplicates of the same ID.
- **TODO.md:** keep the union of task blocks. If two roots share an ID, keep the one already in the base and renumber the newer one with its subtree, rewriting every `Depends:` and `From:` that pointed into it; if the renumbered root is claimed, stop and ask. An ID now in both files is removed from `TODO.md`.
- **Source files:** inside the node's scope, resolve minimally and rerun `Done when`; otherwise stop and ask.
- One agent per working tree. Use `--worktree` or lanes for parallel work.

## No-git mode

Outside a git repository every command warns once: "This is not a git repository. The todo skills still work, but without branches, worktrees, commits or merges, so there is no isolation and no history. Run `git init` to enable them." Then:

- Every git step is skipped: no branches, claims, commits, merges or refresh.
- Progress lives in `State:` (`no git`, `files:` and `docs:` with the touched paths), and a root keeps its finished children's paths until the drain.
- The review reads the files listed in `files:`, since there is no diff.
- Markers, verification, the gates and the drain to `CHANGELOG.md` work as usual. `/todo-release` writes the section without a commit.
- `/todo-init --ci` writes only `.todo/`: CI and the hook need git.
