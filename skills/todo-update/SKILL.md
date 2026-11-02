---
name: todo-update
description: Manually change a task node in the TODO.md tree. Use for /todo-update <ID> [--status in-progress|blocked|ready|drop|revert] [--note "<message>"], where ID may be dotted like FEAT-002.1. Changes markers, drops a node with its subtree after confirmation, and edits Title, Done when, Ref, Depends, From, State, Size, Priority or Lane in place using only text the user supplied.
argument-hint: <ID> [--status in-progress|blocked|ready|drop|revert] [--note "<message>"]
---

# /todo-update

First load the `todo` core skill (tree format, sizes, invariants, guardrails). For `--status in-progress` also read `../todo-continue/SKILL.md` (steps 3-5), and `reference/git-flow.md` and `reference/verification.md` from the core's folder; for `--status ready` on a claimed root, `reference/git-flow.md`. If the core is not available as a skill, read them under `../todo/`.

Check git (core, "Git mode"); in a non-git folder print the core's warning and continue. Run the invariant check first. If the ID is in CHANGELOG.md, refuse to reopen it and suggest `/todo-add --type fix --from <ID>`. Otherwise, if `<ID>` is not in TODO.md, list the IDs that are and change nothing.

## Status changes

- `--status in-progress`: refuse if another task is `[/]` and suggest `ready` for that one first. Refuse if the node is not workable (open children, unmet `Depends:`, blocked ancestor, tree claimed by another branch) and say why. Otherwise do `/todo-continue` steps 3-5 for it (ready check, branches with the tree claim, `[/]`, `State:`, start commit). It builds nothing; `/todo-continue` resumes from there.
- `ready`, `blocked` and `revert` act where the node's state lives: `[/]`, `[!]` and `[x]` live on the tree's branches, while the base shows the node as `[ ]`. Except for a claim release (below), which runs from any branch: for a node in a claimed tree, if you are not on that tree's branch that holds the node, name the branch and stop; do not switch.
- `--status ready`, by the node's marker:
  - **`[ ]` root whose `State:` names a branch** (a tree claim): release it. Check whether it is stale: does the branch still exist in this clone (local, or remote-tracking refs already fetched)? If it is **live**, say so with the branch's last commit date, require an explicit yes, and warn that the owner's branch keeps its `[/]` and `State:` and will conflict if merged later. Require a clean tree. Switch to the base, delete the root's whole `State:` line (it holds only the claim), commit `TODO.md` alone as `chore(backlog): release <ID>` (a direct base commit, like the tree claim; other uncommitted TODO.md edits: list them and ask, per git-flow "Staging"), and switch back. The branch is kept unless the user asks to delete it. Nothing else changes.
  - **`[/]` or `[!]`:** set `[ ]` (a `[/]` abandons the attempt; its branch is kept) and delete `Blocked:` (its gist goes in your reply, not the file). Write `State: attempts 0/3; branch <the node's own todo/ branch> from <the branch it was created from>; next: resume` (no branch item when it has none; no git: `attempts 0/3; no git; next: resume`). In git mode commit `TODO.md` as `chore(backlog): ready <ID>`. `/todo-continue` then reuses that branch (git-flow "Start commit").
  - **Any other `[ ]` node:** say it is already ready and change nothing.
- `--status blocked`: set `[!]`, replace `State:` (or add as the last field line) with `Blocked:` in the core format, built from `--note` and the last failing command. For a manual block with no failing command, write `n/a (manual)` as the middle part. If `--note` gives only a reason, the action is `resolve this, then run /todo-update <ID> --status ready` (written without quotes); ask only when even the reason is missing. On a `todo/` branch commit it as `chore(backlog): block <ID>`; on the base leave it uncommitted (a backlog edit). Then **stop autonomous execution** and do not pick up another node.
- `--status drop`: refuse on `[/]` (set it `ready` first), on `[x]` (use `revert`) and on a claimed root (release the claim first); a node inside a claimed tree is dropped from that tree's branch. Require a reason in `--note`, otherwise ask. List the node, its whole subtree, every ancestor whose size changes, and every task that names any dropped ID in `Depends:` or `From:` with your proposal to remove or re-point each reference, and ask for confirmation. Then delete the node and its subtree, apply the reference changes, recompute every ancestor's size (a parent left without children becomes a leaf and needs `S` or `M`: ask which), and lint. So the ID is never reused (core "IDs"): when `docs/plans/PROJECT.md` exists, append `- <date +%F> · <reason> · dropped <IDs>` to its `## Revisions`; otherwise create `docs/plans/PROJECT.md` holding only `## Revisions` and that line (a backlog file), telling the user why. In git mode on a `todo/` branch, commit the change as `chore(backlog): drop <ID> - <reason>` (backlog files only); on the base leave it uncommitted (a backlog edit). Never write dropped tasks to CHANGELOG.
- `--status revert`: only for an `[x]` node whose parent is not `[x]` (roots never are). Print `git revert -m 1 <merge commit>` for the user if the merge should be undone (the skill does not run it). Set the node and every descendant back to `[ ]`, each with `State: attempts 0/3; next: redo after revert`, so the work is redone from the leaves up; on a `todo/` branch commit it as `chore(backlog): revert <ID>`. In git mode mention that the merged commit stays in history.

## Field edits

`--note` without a status: if the note starts with `Title:`, `Done when:`, `Ref:`, `Depends:`, `From:`, `State:`, `Size:`, `Priority:` or `Lane:`, replace that part with the user's text verbatim. Otherwise tell the user the note was not applied; notes have no field of their own.

- `Done when:` must keep at least one backticked non-vacuous command and must not contain a forbidden command (I3, I10).
- `Lane:` only on roots (name: lowercase letters, digits, dashes).
- `Size:` must obey the tree rules (leaf S or M, parent L or XL). `Priority:` only on roots.
- A new `Ref:` path must exist, and `Depends:` / `From:` IDs must exist, otherwise ask. A `Depends:` that would create a cycle is refused.
- A user edit of `State:` is one way to reset the attempt counter (`--status ready` is the other).

Only text the user supplied may change a field. Never rewrite Done when on your own. Re-run lint after any edit and reply with the updated task lines (or a one-line confirmation for a drop). Do not start work.
