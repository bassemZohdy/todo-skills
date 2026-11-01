---
name: todo-add
description: Add one atomic task to TODO.md. Use for /todo-add <description> [--priority P0|P1|P2] [--ref <docs-path>] [--type feat|fix|task]. Assigns the next ID, decomposes the request into Scope, Out of Scope, Ref and an exact Validation command, and inserts it into Ready in priority order. Never starts work.
argument-hint: <description> [--priority P0|P1|P2] [--ref <docs-path>] [--type feat|fix|task]
---

# /todo-add

First load the `todo` core skill (schemas, IDs, invariants, guardrails). If it is not available as a skill, read `../todo/SKILL.md`.

Defaults: priority `P1`. Type is inferred from the description (bug, crash, regression, broken → `FIX`; add, implement, support, new → `FEAT`; otherwise `TASK`) unless `--type` is given. Show the chosen prefix in the result.

## Steps

1. Run the invariant check. If the new block would push TODO.md past 120 lines, refuse. Suggest finishing, dropping or splitting something. Do not trim existing tasks.
2. Resolve `--ref`. If the path does not exist, say so and ask. Anchors (`#section`) are allowed. If no `--ref` is given and a doc in `docs/` clearly governs the work, propose it. Otherwise use `none`. Never invent a path.
3. Decompose into one atomic unit:
   - **Scope**: one context window of work. It should touch one module or concern and roughly ≤ 5 files.
   - **Out of Scope**: at least one concrete boundary that blocks plausible over-engineering (extra refactors, adjacent features, dependency upgrades).
   - **Validation**: one exact, runnable command that fails now and passes when the work is done. Prefer the targeted test (`pytest tests/test_x.py::test_y`) over the full suite. If the test does not exist yet, name the test file this task will create. If no command can be derived from the repo, ask one question. Never write `manual`, `n/a` or a vacuous command (`true`, `echo`, `ls`).
   - Optional `Depends:` only if the user named a prerequisite.
4. If the description is too large for one task, do not add it. Propose a split into numbered atomic tasks and wait for confirmation. Add only what the user confirms.
5. Assign the ID (core ID rules). Insert the block into **Ready**, ordered P0 → P1 → P2 and by ascending ID within a priority.
6. Reply with the inserted block and its position. Do not start work.

Nothing enters TODO.md unless this command created it from the user's request.
