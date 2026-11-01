---
name: todo-status
description: Read-only view of the backlog. Use for /todo-status [--search <text>] [--last <N>]. Shows what is in progress, the next eligible task, blocked items with their reasons, and recently drained work from CHANGELOG.md. Searches TODO.md and CHANGELOG.md. Never changes any file.
argument-hint: [--search <text>] [--last <N>]
---

# /todo-status

First load the `todo` core skill (schemas, IDs, invariants). If it is not available as a skill, read `../todo/SKILL.md`.

This command changes nothing: no edits, no bootstrapping, no git writes. If `TODO.md` does not exist, say so and suggest `/todo-init`.

## Default report

1. Run the invariant check and give the result in one line.
2. **In Progress**: ID, title, `Progress:` line, and whether `git status` shows changes.
3. **Next eligible**: the task `/todo-continue` would pick (ID, title, Validation), applying the same eligibility rule (`Depends:` satisfied only by an ID in CHANGELOG.md). If none, say what blocks the queue.
4. **Ready**: count, with a one-line list of IDs by priority.
5. **Blocked**: each ID with its Blocker Reason and Action Required.
6. **Recently drained**: the newest `--last <N>` entries of `## [Unreleased]` (default 5).

## Search

`--search <text>`: case-insensitive search of TODO.md and CHANGELOG.md. Return matching task blocks and changelog entries with their IDs. No match is an acceptable answer. Do not search the rest of the repository.

Keep the output short. Do not add suggestions beyond pointing to the command that would act on what you found.
