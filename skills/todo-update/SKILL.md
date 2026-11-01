---
name: todo-update
description: Manually change a backlog task's state or fields. Use for /todo-update <ID> [--status in-progress|blocked|ready|drop] [--note "<message>"]. Moves tasks between In Progress, Ready and Blocked, drops tasks with an audit reason, and edits Scope, Out of Scope, Ref, Validation, Depends, From, Progress or Notes in place using only text the user supplied.
argument-hint: <ID> [--status in-progress|blocked|ready|drop] [--note "<message>"]
---

# /todo-update

First load the `todo` core skill (schemas, invariants, guardrails). If it is not available as a skill, read `../todo/SKILL.md`.

Run the invariant check first. If `<ID>` is not in TODO.md, list the IDs that are and change nothing. If the ID is in CHANGELOG.md, refuse to reopen it and suggest `/todo-add --type fix --from <ID>`.

## Status changes

- `--status in-progress`: refuse if another task is In Progress and suggest moving that one to `ready` first. Otherwise set `[/]` and move it to In Progress.
- `--status ready`: move to Ready in priority order (P0 → P1 → P2, ascending ID). Clear the three blocker fields (keep their gist in Notes). Reset `Progress:` attempts to `0/3`. Set `[ ]`.
- `--status blocked`: move to **Blocked**, set `[!]`, and fill `Blocker Reason`, `Command/Error` and `Action Required` from `--note` and the last failing command. If you cannot fill them truthfully, ask. Then **stop autonomous execution**. Do not pick up another task.
- `--status drop`: require a reason in `--note`, otherwise ask for one. If other tasks list this ID in `Depends:` or `From:`, warn first and name them. Delete the block. The audit trail is a commit `chore(backlog): drop <ID> - <reason>` (or the reason in the reply if the repo has no git). Never write dropped tasks to CHANGELOG. Dangling references are then flagged by invariant I7 until the user fixes them.

## Field edits

`--note` without a status: if the note starts with `Scope:`, `Out of Scope:`, `Ref:`, `Validation:`, `Depends:`, `From:` or `Progress:`, replace that field with the user's text verbatim. Otherwise set or append the `Notes:` line.

Only text the user supplied may change a field. Never rewrite Validation on your own. A new `Ref:` path must exist, and `Depends:` / `From:` IDs must exist, otherwise ask. A user edit of `Progress:` is how the attempt counter is reset.

Reply with the updated block (or a one-line confirmation for a drop). Do not start work.
