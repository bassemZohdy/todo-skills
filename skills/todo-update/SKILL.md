---
name: todo-update
description: Manually change a task node in the TODO.md tree. Use for /todo-update <ID> [--status in-progress|blocked|ready|drop|revert] [--note "<message>"], where ID may be dotted like FEAT-002.1. Changes markers, drops a node with its subtree after confirmation, and edits Title, Done when, Ref, Depends, From, State, Size or Priority in place using only text the user supplied.
argument-hint: <ID> [--status in-progress|blocked|ready|drop|revert] [--note "<message>"]
---

# /todo-update

First load the `todo` core skill (tree format, sizes, invariants, guardrails). For `--status in-progress` and `--status ready` on a claimed root also read `reference/git-flow.md` from its folder. If the core is not available as a skill, read `../todo/SKILL.md` (and `../todo/reference/git-flow.md`).

Check git (core, "Git mode"); in a non-git folder print the one-time warning and continue. Run the invariant check first. If `<ID>` is not in TODO.md, list the IDs that are and change nothing. If the ID is in CHANGELOG.md, refuse to reopen it and suggest `/todo-add --type fix --from <ID>`.

## Status changes

- `--status in-progress`: refuse if another task is `[/]` and suggest `ready` for that one first. Refuse if the node is not workable (open children, unmet `Depends:`, blocked ancestor) and say why. Otherwise run the ready check, create the branch chain, make the tree claim when it is the first node of its tree, and claim exactly as `/todo-continue` does (core "Lifecycle by status" and `reference/git-flow.md`: branch first, tree claim published to the base branch, then `[/]`, `State:`, claim commit). It builds nothing; `/todo-continue` resumes from there.
- Run `--status ready`, `blocked` and `revert` on the branch that holds the node's state (the tree's branch), because `[!]` and `[/]` live there and the base branch still shows the node as `[ ]`.
- `--status ready` on a **root with a `branch` in its `State:`** releases the tree claim. First check whether it is stale: does the named branch still exist in this clone (local or remote-tracking refs you have already fetched)? If it is **live**, say so with the branch's last commit date and require an explicit yes to release a live claim, and warn that the owner's branch keeps its `[/]` and `State:` and will conflict if merged later. Require a clean tree. Then switch to the base branch, delete the whole `State:` line of the root (it holds only the claim when the tree is not active), commit just that as `chore(backlog): release <ID>` (the one direct base commit the skills make), and switch back. The branch is kept unless the user asks to delete it. Otherwise it is valid on `[/]` (abandons the attempt, keeps the branch) and `[!]`. Set `[ ]`, delete `Blocked:` (keep its gist out of the file, in your reply), and if a `State:` exists set its attempts to `0/3`. If there is none (a blocked node lost its `State:`), write `State: attempts 0/3; branch <current todo/ branch> [from <base>]; next: resume` in git mode, so the branch is not forgotten.
- `--status blocked`: set `[!]`, replace `State:` with `Blocked: <reason> → \`<command>\` <error> → <action required>` built from `--note` and the last failing command. For a manual block with no failing command, write `n/a (manual)` as the middle part. If `--note` gives only a reason, use the action "resolve this, then run /todo-update <ID> --status ready"; ask only when even the reason is missing. Then **stop autonomous execution** and do not pick up another node.
- `--status drop`: refuse on `[/]` (set it `ready` first). Require a reason in `--note`, otherwise ask. List the node and its whole subtree and every task that names any of them in `Depends:` or `From:`, and ask for confirmation. Refuse to drop an `[x]` node (use `revert`) or a claimed root (release the claim first). A node inside a claimed tree can be dropped, from that tree's branch. Then delete the node and its subtree, recompute the parent's size (a parent left without children becomes a leaf and needs `S` or `M`, ask which), and re-run lint. The audit trail is a commit `chore(backlog): drop <ID> - <reason>` in git mode when you are on a `todo/` branch (staging `TODO.md` only; other pending edits go with the next claim), never on the base branch, where the edit stays uncommitted; otherwise the reason is in your reply. Never write dropped tasks to CHANGELOG. Dangling references are flagged by I7 until the user fixes them.
- `--status revert`: only for an `[x]` node. Set it back to `[ ]` with `State: attempts 0/3; next: redo after revert` so it is workable again. Its parent must not be `[x]` (roots never are). In git mode mention that the merged commit stays in history.

## Field edits

`--note` without a status: if the note starts with `Title:`, `Done when:`, `Ref:`, `Depends:`, `From:`, `State:`, `Size:` or `Priority:`, replace that part with the user's text verbatim. Otherwise tell the user the note was not applied; notes have no field of their own.

- `Done when:` must keep at least one backticked non-vacuous command and must not contain a forbidden command (I3, I10).
- `Size:` must obey the tree rules (leaf S or M, parent L or XL). `Priority:` only on roots.
- A new `Ref:` path must exist, and `Depends:` / `From:` IDs must exist, otherwise ask. A `Depends:` that would create a cycle is refused.
- A user edit of `State:` is how the attempt counter is reset.

Only text the user supplied may change a field. Never rewrite Done when on your own. Re-run lint after any edit and reply with the updated task lines (or a one-line confirmation for a drop). Do not start work.
