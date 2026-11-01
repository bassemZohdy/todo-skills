---
name: todo-update
description: Manually change a task node in the TODO.md tree. Use for /todo-update <ID> [--status in-progress|blocked|ready|drop|revert] [--note "<message>"], where ID may be dotted like FEAT-002.1. Changes markers, drops a node with its subtree after confirmation, and edits Title, Done when, Ref, Depends, From, State, Size or Priority in place using only text the user supplied.
argument-hint: <ID> [--status in-progress|blocked|ready|drop|revert] [--note "<message>"]
---

# /todo-update

First load the `todo` core skill (tree format, sizes, invariants, guardrails). If it is not available as a skill, read `../todo/SKILL.md`.

Check git (core, "Git mode"); in a non-git folder print the one-time warning and continue. Run the invariant check first. If `<ID>` is not in TODO.md, list the IDs that are and change nothing. If the ID is in CHANGELOG.md, refuse to reopen it and suggest `/todo-add --type fix --from <ID>`.

## Status changes

- `--status in-progress`: refuse if another task is `[/]` and suggest `ready` for that one first. Refuse if the node is not workable (open children, unmet `Depends:`, blocked ancestor) and say why. Otherwise set `[/]`. This does not create a branch; `/todo-continue` does.
- `--status ready`: set `[ ]`, delete `Blocked:` (keep its gist out of the file, in your reply), and reset `State:` attempts to `0/3`.
- `--status blocked`: set `[!]`, replace `State:` with `Blocked: <reason> → \`<command>\` <error> → <action required>` built from `--note` and the last failing command. If you cannot fill all three parts truthfully, ask. Then **stop autonomous execution** and do not pick up another node.
- `--status drop`: require a reason in `--note`, otherwise ask. List the node and its whole subtree and every task that names any of them in `Depends:` or `From:`, and ask for confirmation. Refuse to drop an `[x]` node (use `revert`). Then delete the node and its subtree, recompute the parent's size (a parent left without children becomes a leaf and needs `S` or `M`, ask which), and re-run lint. The audit trail is a commit `chore(backlog): drop <ID> - <reason>` in git mode, or the reason in your reply otherwise. Never write dropped tasks to CHANGELOG. Dangling references are flagged by I7 until the user fixes them.
- `--status revert`: only for an `[x]` node. Set it back to `[ ]` with `State: attempts 0/3; next: redo after revert` so it is workable again. Its parent must not be `[x]` (roots never are). In git mode mention that the merged commit stays in history.

## Field edits

`--note` without a status: if the note starts with `Title:`, `Done when:`, `Ref:`, `Depends:`, `From:`, `State:`, `Size:` or `Priority:`, replace that part with the user's text verbatim. Otherwise tell the user the note was not applied; notes have no field of their own.

- `Done when:` must keep at least one backticked non-vacuous command and must not contain a forbidden command (I3, I10).
- `Size:` must obey the tree rules (leaf S or M, parent L or XL). `Priority:` only on roots.
- A new `Ref:` path must exist, and `Depends:` / `From:` IDs must exist, otherwise ask. A `Depends:` that would create a cycle is refused.
- A user edit of `State:` is how the attempt counter is reset.

Only text the user supplied may change a field. Never rewrite Done when on your own. Re-run lint after any edit and reply with the updated task lines (or a one-line confirmation for a drop). Do not start work.
