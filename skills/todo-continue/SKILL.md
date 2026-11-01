---
name: todo-continue
description: Execute the next workable node of the TODO.md task tree end to end, driven by each task's status. Use for /todo-continue [--plan] [--isolated] [--worktree] [--merge]. Creates the node's git branch first, then marks it in progress, builds with red-green-refactor, runs Done when plus regression, completes it in the branch, merges it into its parent, and drains a finished root to CHANGELOG.md as one entry. Works without git, with a warning. Completes at most one node per invocation.
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

Lifecycle: ready check → branch → claim → build → verify → complete → merge. Details and the status matrix are in the core skill ("Lifecycle by status", "Git flow").

1. **Git mode and invariants.** Check git (core, "Git mode"); in a non-git folder print the one-time warning and continue in no-git mode. Run the invariant check (use the lint script when present). Read the markers: that is the status of every node.
2. **Select by status.**
   - A `[/]` node exists: resume it. Read its `State:`; in git mode check out its branch, run `git status` and `git diff --stat`. Resume when the changes fit its task line, otherwise stop and ask. Never revert or commit changes you did not make.
   - Otherwise take the first **workable** `[ ]` node (core, "Which node is next"). `[!]` nodes are skipped and `[x]` nodes are never touched. If nothing is workable, list what blocks progress (open dependencies, `[!]` nodes) and stop.
3. **Ready check** (new nodes only). Lint is clean; the `Ref:` exists; the tree is clean by the core definition (backlog files and generated files excluded), otherwise stop and ask; run the regression command for the **baseline**. It must be green; if it is red do not fix it: block the node as "baseline red" (see "Test failures"). Record the pass count.
4. **Branch first** (git mode). Create every missing ancestor branch top-down (root from the base branch, each child from its parent), then `todo/<ID>-<slug>`, and switch to it (or `git worktree add` with `--worktree`). Reuse an existing branch that starts with `todo/<ID>-`. Never commit on the base branch.
5. **Claim.** On the node's branch set `[/]` and write `State: attempts 0/3; branch <name> [from <base>]; next: read docs`. In no-git mode write `State: attempts 0/3; no git; files: -; next: read docs`. In git mode commit `chore(backlog): start <ID>` with `TODO.md` (and `CHANGELOG.md` if new). Nothing else is touched before this. Skip the commit if nothing changed.
6. **Read before write.** Read the `Ref:` doc (or its anchored section) and the README/doc sections that govern the area. Then read only the code the node needs. If the Ref is missing or contradicts the task line, stop and ask.
   - With `--plan` and no `plan approved` in `State:`: print a plan of at most 10 lines (files, approach, risks), set `next: plan proposed; awaiting approval`, and **stop**. The user's next `/todo-continue` counts as approval.
7. **Build.**
   - **Red** (leaf `FIX`/`FEAT`): write the tests for the `Done when` criteria and see them fail for the expected reason, quoting the failing assertion in your report. If they already pass, stop and ask the user: the work may already exist or the test is vacuous. Offer `/todo-update <ID> --status drop`, or a tighter `Done when`. Do not add tests that pass immediately just to continue. Leaf `TASK` refactors: add characterization tests that pass before and after.
   - **Green:** implement **only what the task line says**. Adjacent findings are not fixed and not added to TODO.md; collect them for the report. No new `TODO`/`FIXME` comments. In no-git mode record each touched file in `State: files:`.
   - **Refactor:** clean up with the tests green.
   - **Parent (integration step):** follow core "Verification protocol" step 7. No feature code.
8. **Verify.** Run, in full and unnarrowed: the `Done when` commands, then the regression run. Update `State:` after every cycle. See "Test failures".
9. **Gates.** All must pass, otherwise the node does not complete:
   - Done when exited 0 **and** really ran tests ("0 tests", "no tests found", "collected 0 items", "NO TESTS RAN" fail). Regression is green with no fewer passing tests than the baseline and none deleted or skipped.
   - Every item of the project's Definition of Done, when one exists.
   - Self-review: every changed hunk traces to the task line, and no debug output, commented-out code or unrelated reformatting remains. In git mode review `git diff`; in no-git mode there is no diff, so re-read each file listed in `State: files:` (for a root: the roll-up in its own `State:`) in full against the task line.
   - Only plausible files changed (`git diff --stat`, or `State: files:` in no-git mode); no generated files, secrets or `.env` staged.
   - Documentation drift check (below).
10. **Complete, in this order.**
    1. Set the marker to `[x]` and delete `State:`. Skip this for a root: a root is never `[x]`, it is drained in step 5, and its lint runs there.
    2. Run the lint script (children and parents only). It must pass with the new marker.
    3. In git mode commit the node's files by explicit path plus `TODO.md`: `<type>(<scope>): <title>`, body `Refs: <ID>`. In no-git mode skip.
    4. **Child node:** switch to the parent's branch (or worktree), `git merge --no-ff` the child there, then `git branch -d` the child branch. Report and stop. The node stays `[x]` until its root drains. In no-git mode, before deleting the child's `State:`, merge its `files:` and any doc files it updated (`docs:`) into the root's `State:` (create the item, no duplicates).
    5. **Root node** (a leaf root, or a root whose children are all `[x]` and whose integration step just passed in this run): drain, in this exact order so an interrupted run can be detected and finished: (a) prepend one entry to `## [Unreleased]` in CHANGELOG.md (core entry format; `Includes:` only when it has descendants); (b) delete the whole subtree from TODO.md; (c) lint; (d) commit on the root's branch with body `Refs: <ID>` and the included IDs. With `--merge`: switch to the base branch, `git merge --no-ff` the root's branch, then `git branch -d` it. Without it, print those exact commands. Never push. In no-git mode do (a) to (c) only.
11. **Report** in 3-5 lines (name the branch now checked out): ID and title, commands run and results (including regression counts against the baseline), files changed, branch and commit hash if any, and `children done/total` for the root. Then:
    - Adjacent problems as ready-to-run commands: `/todo-add "<description>" --from <ID>`. Never add them yourself.
    - The next workable node (ID, title, Done when), without starting it.
    - A suggestion to clear context before the next `/todo-continue`.

## Checkpoints

`State:` is the only thing that survives a context reset. Format: `attempts <n>/3; [hyp: <one line>;] branch <name> [from <base>]; next: <short>` (git) or `attempts <n>/3; no git; files: <list>; next: <short>`. Update it after each verification cycle and whenever you stop before completing. Read it on resume and continue the count. Never reset the counter except by a new node or a user edit through `/todo-update`.

## Test failures

- Diagnose before changing code. For each failing cycle: reproduce, read the first failing assertion or stack frame, state one hypothesis in `State:` (`hyp:`), make the smallest change that tests that hypothesis, and re-run. Do not change several unrelated things at once or retry unchanged code.
- At most **3** attempts in total across sessions (the `State:` counter). An attempt is a verification run that fails after you started implementing; the first red run is not one.
- You may change code, and tests the node itself creates, inside the task line's scope.
- Forbidden: editing the `Done when` commands, deleting, skipping or weakening an existing test, adding `|| true`, loosening assertions, or switching to a narrower command to get green.
- A failure outside the node (flaky test, broken CI, red baseline, a regression in other code that the change caused and cannot be fixed within the task line) is not fixed here. Block the node: set `[!]`, replace `State:` with `Blocked: <reason> → \`<command>\` <last ≤5 error lines> → <action required>`, commit it in git mode (`chore(backlog): block <ID>`), and stop. Do not pick up another node.
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
