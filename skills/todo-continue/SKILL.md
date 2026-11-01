---
name: todo-continue
description: Execute the next workable node of the TODO.md task tree end to end. Use for /todo-continue [--plan] [--isolated] [--worktree] [--merge]. Resumes the active node or claims the next workable one, works on its own git branch or worktree (or without git, with a warning), writes tests first, runs Done when plus regression tests, merges the verified node into its parent, and drains a finished root to CHANGELOG.md as one entry. Completes at most one node per invocation.
argument-hint: [--plan] [--isolated] [--worktree] [--merge]
---

# /todo-continue

First load the `todo` core skill (tree format, sizes, git mode, git flow, invariants, verification protocol, guardrails). If it is not available as a skill, read `../todo/SKILL.md`.

Complete at most one node per invocation.

Flags (all optional):
- `--plan`: stop for approval after reading, before writing any code (step 5).
- `--isolated`: run steps 5-8 in a fresh-context subagent (see "Isolated mode").
- `--worktree`: put the node in its own worktree (`../<repo>.todo/<ID>`) instead of switching branches in the current tree.
- `--merge`: when a **root** finishes, also merge its branch into the base branch. Without it the exact commands are printed instead.

## State machine

1. **Git mode and invariants.** Check git (core, "Git mode"); in a non-git folder print the one-time warning and continue in no-git mode. Run the invariant check (use the lint script when present).
2. **Select.**
   - If a node is `[/]`: read its `State:`, and in git mode run `git status` and `git diff --stat`. Resume when the changes fit the node's task line. If they fall outside it or look unrelated, stop and ask. Never revert or commit changes you did not make.
   - Otherwise take the first **workable** node (core, "Which node is next"). In git mode the tree must be clean, otherwise stop and ask. If nothing is workable, list what blocks progress (open dependencies, `[!]` nodes) and stop.
3. **Claim.** Set the marker to `[/]` **before touching any code**. In git mode create and switch to `todo/<ID>-<slug>` (a root from the base branch, a child from its parent's branch tip; with `--worktree` use `git worktree add`). If a branch starting with `todo/<ID>-` exists, reuse it. Write `State: attempts 0/3; branch <name> [from <base>]; next: read docs`. In no-git mode write `State: attempts 0/3; no git; files: -; next: read docs`.
4. **Read before write.** Read the `Ref:` doc (or its anchored section) and the README/doc sections that govern the area. Then read only the code the node needs. If the Ref is missing or contradicts the task line, stop and ask.
5. **Plan checkpoint.** With `--plan` and no `plan approved` in `State:`: print a plan of at most 10 lines (files, approach, risks), set `next: plan proposed; awaiting approval`, and **stop**. The user's next `/todo-continue` counts as approval.
6. **Baseline.** Run the regression command (the node's `regression:` or the project's full suite). It must be green. If it is red, do not fix it: block the node as "baseline red" (see "Test failures").
7. **Tests first, then implement.**
   - Leaf `FIX` and `FEAT`: write the tests for the `Done when` criteria first and see them fail for the expected reason. If they already pass, stop: the work is done or the test is vacuous.
   - Leaf `TASK` refactors: add characterization tests that pass before and after.
   - Container nodes (all children `[x]`): write integration tests that exercise the children together. No new feature code.
   - Implement **only what the task line says**. Adjacent findings are not fixed and not added to TODO.md. Collect them for the report. In no-git mode record each touched file in `State: files:`.
8. **Verify.** Run, in full and unnarrowed: the `Done when` commands, then the regression run. Update `State:` after every cycle. See "Test failures".
9. **Gates.** All must pass, otherwise the node does not complete:
   - Done when exited 0 **and** really ran tests. "0 tests", "no tests found" or "collected 0 items" fail. The regression run is green and has no fewer passing tests than the baseline, with none deleted or skipped.
   - Every item of the project's Definition of Done, when one exists.
   - Self-review of the full diff: every changed hunk traces to the task line, no debug output, commented-out code or unrelated reformatting remains. Remove what fails or stop and ask.
   - In git mode `git diff --stat` shows only plausible files; in no-git mode the files in `State:` do.
   - Documentation drift check (below).
   - No secrets, `.env` files or build artifacts staged.
   - The lint script passes.
10. **Complete the node.**
    - **Child node:** set `[x]` and delete its `State:`. In git mode commit on its branch (`<type>(<scope>): <title>`, body `Refs: <ID>`), switch to the parent's branch (or worktree) and `git merge --no-ff` it there. Report and stop. It stays in TODO.md as `[x]` until its root drains.
    - **Root node** (a leaf root, or a root whose children are all `[x]` and whose integration step just passed): drain, in this exact order so an interrupted run can be detected and finished:
      1. Prepend one entry to `## [Unreleased]` in CHANGELOG.md (core entry format) ending in `Includes:` with every descendant ID.
      2. Delete the whole subtree from TODO.md.
      3. Commit in git mode: code, CHANGELOG.md and TODO.md together on the root's branch, `<type>(<scope>): <title>`, body `Refs: <ID>` and the included IDs.
      4. With `--merge`: switch to the base branch and `git merge --no-ff` the root's branch. Without it, print those exact commands for the user. Never push.
      In no-git mode, steps 1-2 only.
11. **Report** in 3-5 lines: ID and title, commands run and results (including regression counts), files changed, branch and commit hash if any, and `children done/total` for the root. Then:
    - Adjacent problems as ready-to-run commands: `/todo-add "<description>" --from <ID>`. Never add them yourself.
    - The next workable node (ID, title, Done when), without starting it.
    - A suggestion to clear context before the next `/todo-continue`.

## Checkpoints

`State:` is the only thing that survives a context reset. Format: `attempts <n>/3; branch <name> [from <base>]; next: <short>` (git) or `attempts <n>/3; no git; files: <list>; next: <short>`. Update it after each verification cycle and whenever you stop before completing. Read it on resume and continue the count. Never reset the counter except by a new node or a user edit through `/todo-update`.

## Test failures

- Diagnose before changing code. For each failing cycle: reproduce, read the first failing assertion or stack frame, state one hypothesis in `State:`, make the smallest change that tests that hypothesis, and re-run. Do not change several unrelated things at once or retry unchanged code.
- At most **3** fix-and-verify cycles in total across sessions (the `State:` counter).
- You may change code, and tests the node itself creates, inside the task line's scope.
- Forbidden: editing the `Done when` commands, deleting, skipping or weakening an existing test, adding `|| true`, loosening assertions, or switching to a narrower command to get green.
- A failure outside the node (flaky test, broken CI, red baseline, a regression in other code that the change caused and cannot be fixed within the task line) is not fixed here. Block the node: set `[!]`, replace `State:` with `Blocked: <reason> → \`<command>\` <last ≤5 error lines> → <action required>`, and stop. Do not pick up another node.
- After the third failed cycle, block the same way and list each hypothesis tried.
- Run commands only under the safety rules in the core skill.

## Isolated mode (`--isolated`)

Use only when a subagent tool is available. Otherwise say so and run normally.

- The main thread does steps 1-4 and 9-11. A subagent with a fresh context does steps 5-8.
- Give the subagent only: the task lines (the node and its parent), the paths of the Ref and governing docs, the branch name, and these rules: stay inside the task line, never edit `TODO.md` or `CHANGELOG.md`, never change the `Done when` commands, return a diff summary and the command output.
- Do not trust the report. The main thread re-runs Done when and the regression itself, reads the diff and applies the gates. A subagent that failed after 3 cycles blocks the node as usual.

## Documentation drift

- If the implementation must deviate from the `Ref` doc, stop. Choose with the user: change the code to match, or update the doc inside this node with explicit approval. Never diverge silently.
- Before completing, search README.md and `docs/` (`grep`) for the names of any public command, flag, endpoint, config key or symbol the node changed. If hits are stale:
  - If updating them fits the task line, update them and note `Docs: updated <file>` for the root's CHANGELOG entry.
  - Otherwise report them and give the exact `/todo-add` command. Do not create the task yourself.
- If README setup or test instructions disagree with the commands that actually passed, report the mismatch.
- TODO.md never duplicates docs content. If a task starts to read like a spec, move the substance into `docs/` and leave a `Ref:`.
