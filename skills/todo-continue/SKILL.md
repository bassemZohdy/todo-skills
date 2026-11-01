---
name: todo-continue
description: Execute the next workable node of the TODO.md task tree end to end, driven by each task's status. Use for /todo-continue [--plan] [--lane <name> | --all-lanes [--seq]] [--worktree] [--merge]. Creates the node's git branch first, then marks it in progress, builds with red-green-refactor, runs Done when plus regression, completes it in the branch, merges it into its parent, and drains a finished root to CHANGELOG.md as one entry. Works without git, with a warning. Completes at most one node per invocation, except lane runs, where one subagent per lane works its lane's trees.
argument-hint: [--plan] [--lane <name> | --all-lanes [--seq]] [--worktree] [--merge]
---

# /todo-continue

First load the `todo` core skill (tree format, sizes, git mode, invariants, guardrails) and read `reference/git-flow.md` and `reference/verification.md` from its folder. If the core is not a skill, read `../todo/SKILL.md` and `../todo/reference/*.md`.

Complete at most one node per invocation (lane runs excepted, see "Lanes"). Flags (all optional):
- `--plan`: stop for approval after reading, before writing code (step 6).
- `--lane <name>`: only take roots of that lane (core, "Lanes"); one agent, in order.
- `--all-lanes [--seq]`: one subagent per lane, one root per lane per run, in parallel; `--seq` runs the lanes one after another (see "Lanes").
- `--worktree`: put the node in its own worktree (`../<repo>.todo/<ID>`).
- `--merge`: when a **root** finishes, also merge it into the base branch. Without it the exact commands are printed.

## Steps

Lifecycle: ready check → branch → claim → build → review → verify → complete → merge (core, "Lifecycle by status").

1. **Git mode and invariants.** Check git (core, "Git mode"). Run the lint script when present. If it fails only on the active node's `State:` line, show the corrected line and ask to fix it; otherwise stop. The markers are the status of every node.
2. **Select by status.** In git mode first do the core's "Interrupted work comes first" check: finish a pending merge of an `[x]` child (then lint and run the parent's regression on the parent branch; block the parent if red; report and stop), or resume an unmerged `[/]` branch.
   - A `[/]` node exists: resume it from its `State:` (check out its branch; `git status` and `git diff --stat`). Continue if the changes fit its task line, otherwise stop and ask. Never revert or commit changes you did not make.
   - Otherwise take the first **workable** `[ ]` node (core, "Which node is next"). Trees claimed by another branch are skipped and reported with their branch; `[!]` nodes are skipped; `[x]` nodes are never touched. If nothing is workable, list what blocks progress and stop.
3. **Ready check** (new nodes only). Lint clean; `Ref:` exists; tree clean by the git-flow definition (otherwise stop and ask); in git mode a new root starts from the base, so `git switch <base>` first if you are on another branch. Run the regression command for the **baseline**; it must be green, otherwise change nothing: report "baseline red" with the failing command and suggest `/todo-add "fix the failing baseline" --type fix --priority P0`, and stop. The pass count goes into `State:` at the claim.
4. **Branch first** (git mode). Create the missing ancestor branches top-down, then `todo/<ID>-<slug>`, and switch to it (or `--worktree`). For the first node of a tree, do the **tree claim** right after the root branch exists (`reference/git-flow.md`): claim-only commit, then fast-forward the base to it.
5. **Claim.** On the node's branch set `[/]` and replace the whole `State:` with `attempts 0/3; baseline <n> passing; branch <name> [from <base>]; next: read docs` (no git: `attempts 0/3; baseline <n> passing; no git; files: -; next: read docs`). In git mode commit `chore(backlog): start <ID>` (skip if nothing changed). Nothing but backlog files changes before this.
6. **Read before write.** Read the `Ref:` doc and the README/doc sections that govern the area, then only the code the node needs. If the Ref is missing or contradicts the task line, stop and ask. With `--plan` and no `plan approved` in `State:`: print a plan of at most 10 lines (files, approach, risks), set `next: plan proposed; awaiting approval`, and **stop**; the next `/todo-continue` counts as approval.
7. **Build.**
   - **Resume:** if the code and tests already exist, skip red and go to Review; compare against the `baseline` recorded in `State:` (missing: take it from the base branch's passing count). Commit uncommitted earlier work only at step 10.
   - **Red** (new `FIX`/`FEAT` leaf): write the tests and see them fail for the expected reason, quoting the failing assertion. If they already pass, stop and ask: the work may exist or the test is vacuous (offer `/todo-update <ID> --status drop` or a tighter `Done when`). `TASK` refactors get characterization tests.
   - **Green:** implement only what the task line says. Adjacent findings are collected for the report, not fixed or added to TODO.md. No new `TODO`/`FIXME`. In no-git mode record touched files in `State: files:`.
   - **Refactor** with tests green.
   - **Parent (integration step):** `reference/verification.md`, protocol step 8. No feature code.
8. **Review** (after build, before the verify run). Read the whole change with `git diff` (no git: re-read each file in `State: files:`) against the task line and its `Done when`:
   - Every hunk traces to the task line; no debug output, commented-out code, new `TODO`/`FIXME` or unrelated reformatting.
   - The tests assert the `Done when` criteria (not vacuous, nothing weakened, ID in the new test names).
   - No generated files, secrets or `.env` in the diff or in any backlog text you wrote (`Blocked:`, `State:`); only plausible files changed.
   - When a subagent tool exists, have a fresh-context reviewer do this, given only the task lines, the Ref path and the diff, and report findings. Fix what is valid (at most 2 rounds). The reviewer never edits `TODO.md` and never runs the tests.
9. **Verify.** Run in full and unnarrowed: the `Done when` commands, then the regression. Update `State:` after every cycle ("Test failures"). Then the gates, all of which must pass:
   - Done when exited 0 **and** really ran tests ("0 tests", "no tests found", "collected 0 items", "NO TESTS RAN" fail). Regression is green with no fewer passing tests than the baseline and none deleted or skipped.
   - Every item of the project's Definition of Done, if one exists.
   - Documentation drift check (below).
10. **Complete, in this order.**
    1. **Child or parent:** set `[x]`, delete `State:`, run the lint script. **Root:** skip this (a root is never `[x]`; item 4 drains it and lints).
    2. In git mode commit the node's files by explicit path, plus `TODO.md` unless it is an undrained root: `<type>(<scope>): <title>`, body `Refs: <ID>`.
    3. **Child:** switch to the parent's branch, `git merge --no-ff` the child, `git branch -d` it (`git worktree remove` first with a worktree). Report and stop; the node stays `[x]` until its root drains. No git: first merge its `files:` and `docs:` into the root's `State:`.
    4. **Root** (a leaf root, or all children `[x]` and the integration step just passed): first refresh from the base (`reference/git-flow.md`). Then drain in this order: (a) prepend one entry to `## [Unreleased]` (core entry format); (b) delete the subtree from TODO.md; (c) lint; (d) commit `chore(backlog): drain <ID>` with `Refs:` and the included IDs. With `--merge`: switch to the base, `git merge --no-ff` the root branch, `git branch -d` it; otherwise print those commands. Never push. No git: do (a) to (c).
11. **Report**, short: ID and title, commands run and results (regression counts against the baseline), files changed, branch and commit, `children done/total` for a root; the checked-out branch; for a root without `--merge` the merge commands. Then adjacent problems as ready-to-run `/todo-add "<description>" --from <ID>` commands (never add them yourself), the next workable node without starting it, and a suggestion to clear context.

## Test failures

- Diagnose before changing code: reproduce, read the first failing assertion, state one hypothesis in `State:` (`hyp:`), make the smallest change that tests it, re-run.
- At most **3** attempts in total across sessions (`State:` counter). An attempt is a failed verification run after you started implementing; the first red run is not one.
- You may change code and the tests the node itself creates, inside the task line's scope.
- Forbidden: editing the `Done when` commands, deleting, skipping or weakening tests, `|| true`, loosening assertions, or a narrower command to get green.
- A failure outside the node (flaky test, a regression that cannot be fixed within the task line) is not fixed here. Block the node: `[!]`, replace `State:` with `Blocked: <reason> → \`<command>\` <last ≤5 error lines joined with " / ", secrets and tokens redacted> → <action required>`, commit it in git mode (`chore(backlog): block <ID>`), stop. After the third failed cycle, block the same way listing each hypothesis tried.
- Run commands only under the safety rules in `reference/verification.md`.

## Lanes

A lane is a track of roots handled by one agent context (core, "Lanes"). Without a lane flag all lanes are one queue and you work alone.

- `--lane <name>`: select only roots whose `Lane:` is `<name>`; everything else is unchanged. Nothing workable in that lane: say so and stop.
- `--all-lanes`: needs a subagent tool, otherwise say so and run the lanes one after another in this thread (as `--seq`). The main thread is the **coordinator**:
  1. Run steps 1-3 for the first workable root of every lane that has one. Stop if a lane's baseline is red.
  2. Do each tree claim in turn on the base branch (`reference/git-flow.md`), then create each root's worktree `../<repo>.todo/<ROOT-ID>` on its claimed branch.
  3. Start one subagent per lane, all at once (with `--seq`, one at a time). Each gets only: its root ID and worktree path, the `Ref` paths, the rules below. It works only inside its worktree and runs steps 1-9 and step 10 items 1-3 (complete and merge into the parent) for each node of that one root depth-first, including the root's own integration step (a parent root only), with everything committed, and **stops before the root's drain** (step 10, item 4). Rules: stay inside the task lines; never edit another lane's nodes, `Done when`, or the base branch; never merge to base; never drain; never push; return a summary per node (ID, commands and results, commit).
  4. Do not trust the summaries. For each finished root, one at a time: refresh from the base in its worktree (`reference/git-flow.md`; `TODO.md` and `CHANGELOG.md` conflicts from earlier roots are resolved by the coordinator with the conflict rules there; expect them for every root after the first: keep this root's block, drop IDs already drained to `CHANGELOG.md`), re-run `Done when` and the regression there against the base's current pass count, then drain it (step 10, item 4). With `--merge` merge it into the base, otherwise print the commands. A real conflict or a red result stops the coordinator and is reported with the branch name.
  5. Report per lane: finished, blocked (with `Blocked:`), still open, and the merge commands.
- Work that `Depends:` on another lane's open node is not workable; the lane stops there and reports what it waits for.
- Lanes only work if their trees touch different files. If a rebase conflict shows they do not, say so and suggest putting them in one lane.

## Documentation drift

- If the implementation must deviate from the `Ref` doc, stop and choose with the user: change the code, or update the doc inside this node with approval.
- Before completing, `grep` README.md and `docs/` for the names of any public command, flag, endpoint, config key or symbol the node changed. Update stale hits if that fits the task line (note `Docs: updated <file>` for the CHANGELOG entry); otherwise report them with the exact `/todo-add` command.
- If README setup or test instructions disagree with the commands that passed, report it.
- TODO.md never duplicates docs content; move spec-like substance into `docs/` and leave a `Ref:`.
