---
name: todo-continue
description: Execute the next workable node of the TODO.md task tree end to end, driven by each task's status. Use for /todo-continue [--plan] [--lane <name> | --all-lanes [--seq]] [--worktree] [--merge]. Creates the node's git branch first, then marks it in progress, builds with red-green-refactor, runs Done when plus regression, completes it in the branch, merges it into its parent, and drains a finished root to CHANGELOG.md as one entry. Works without git, with a warning. Completes at most one node per invocation, except lane runs, where one subagent per lane works one root of that lane.
argument-hint: [--plan] [--lane <name> | --all-lanes [--seq]] [--worktree] [--merge]
---

# /todo-continue

First load the `todo` core skill (tree format, sizes, git mode, invariants, guardrails) and read `reference/git-flow.md` and `reference/verification.md` from its folder (and `reference/lanes.md` with a lane flag). If the core is not a skill, read `../todo/SKILL.md` and those files from `../todo/reference/`.

Complete at most one node per invocation (lane runs excepted, see "Lanes"). Flags (all optional):
- `--plan`: stop for approval after reading, before writing code (step 6). Not combined with a lane flag; an invalid flag combination is reported and nothing runs.
- `--lane <name>`: only take roots of that lane (core, "Lanes"); one agent, in order.
- `--all-lanes [--seq]`: one subagent per lane, one root per lane per run, in parallel; `--seq` (only with `--all-lanes`) runs the lanes one after another (see "Lanes").
- `--worktree`: put the node in its own worktree (`reference/git-flow.md`).
- `--merge`: when a **root** finishes, also merge it into the base branch. Without it the exact commands are printed.

## Steps

The order of every node is the core's "Lifecycle by status".

1. **Git mode and invariants.** Check git (core, "Git mode") and run the invariant check (core). If it fails only on the active node's `State:` line, show the corrected line and ask to fix it; on I5, apply the core's repair and go on; otherwise report and stop.
2. **Select by status.**
   - **Interrupted merge** (git mode, on a `todo/` branch; core "Interrupted work comes first"): finish the pending merge of the `[x]` node into its parent's branch exactly as step 10 item 3 (`git worktree remove` first if it has a worktree; `--no-ff`, message `Merge <ID> into <PARENT-ID>`, `git branch -d`). Then lint, report (step 11) and stop. Run no tests here: the parent's integration step runs the regression later.
   - **A `[/]` node exists:** resume it. Check out its branch (or `cd` to its worktree), run `git status` and `git diff --stat`. Uncommitted changes that fit its task line are this node's earlier work: keep them and commit them at step 10; anything outside the task line: stop and ask, never revert or commit it. A resume **skips steps 3-5** (attempts and `State:` are kept) and goes on at the step `next:` names: `read docs` → 6, `plan proposed` → 6, `build` → 7, `drain` → 10 item 4. Without a baseline in `State:`, the regression must be fully green with no test deleted, skipped or weakened in `git diff`.
   - **Otherwise** take the first **workable** `[ ]` node (core, "Which node is next"). Trees claimed by another branch are skipped and reported as the core says (with the resume hint); `[!]` nodes, including those `[!]` only on their own branch (core "Interrupted work comes first"), are skipped; `[x]` nodes are never touched. A node with `State: next: decompose` is not built: break it down with the `/todo-add` rules (step 7 there; its children replace the marker), show the proposed children, write them only after the user confirms, and stop. A node with `next: plan proposed` goes to step 6 even without `--plan`. If nothing is workable, list what blocks progress and stop.
3. **Ready check** (new nodes only). Lint clean; the `Ref:` path, if the node has one, exists; tree clean by the git-flow definition (otherwise stop and ask); in git mode a root whose base `State:` names no branch (an unclaimed tree) starts from the base, so `git switch <base>` first if you are on another branch; any other node, including a claimed root's integration step, stays on its tree's branch. Run the regression command (`reference/verification.md`, protocol step 6) for the **baseline**:
   - Green: note the pass count for step 5.
   - No test command, or it runs zero tests: `baseline none` (`reference/verification.md`, step 1).
   - Red: if the node is a `FIX` node (root or child) whose `Done when` runs the failing tests, it may start with `baseline red: <failing test ids>`. Otherwise change nothing: report "baseline red" with the failing command and its first failing test, suggest `/todo-add "fix the failing baseline: <first failing test id>" --type fix --priority P0` (its `Done when` must run that test, so it may start on the red baseline), and stop.
4. **Branch first** (git mode). Follow `reference/git-flow.md` exactly: for the first node of a tree, root branch → tree claim commit → fast-forward of the base (**do not go on until it has succeeded**) → the remaining ancestor branches → the node's branch; otherwise only the missing branches. With `--worktree`, see git-flow. No git: skip.
5. **Start.** On the node's branch set `[/]` and replace the whole `State:` with `attempts 0/3; baseline <n> passing; branch <name> from <branch it was created from>; next: read docs` (`baseline none` or `baseline red: …` as step 3 found). No git: `attempts 0/3; baseline <n> passing; no git; files: <paths>; docs: <paths>; next: read docs`, where `files:` keeps the root's rolled-up files (`-` when none) and `docs:` appears only when there are rolled-up docs. In git mode commit `chore(backlog): start <ID>` (with any pending backlog edits; skip if nothing changed). Nothing but backlog files changes before this.
6. **Read before write.** Read the `Ref:` doc (if any) and the README/doc sections that govern the area, then only the code the node needs. If a `Ref:` path does not exist or the doc contradicts the task line, stop and ask.
   - With `--plan`, or when `State:` says `next: plan proposed`: if it already says `next: plan proposed`, show that plan and ask "approve the plan? (yes / change: …)"; on a yes set `next: build` and go on, on a change re-propose it and stop. Otherwise print a plan of at most 10 lines (files, approach, risks), set `next: plan proposed`, commit `TODO.md` in git mode as `chore(backlog): plan <ID>` with the plan as the commit body, and **stop**. "That plan" is the body of that commit (`git log -1 --format=%b --grep='plan <ID>'`); no git or not found: propose a new one.
7. **Build.**
   - **Resume:** if the code and tests already exist, skip red and go to Review; review findings on that earlier work are fixed like any other.
   - **Red** (new `FIX`/`FEAT` leaf): write the tests and see them fail for the expected reason, quoting the first failing assertion or missing-symbol error. If they already pass, stop and ask: the work may exist or the test is vacuous (offer `/todo-update <ID> --status drop` or a tighter `Done when`). `TASK` refactors get characterization tests.
   - **Green:** implement only what the task line says. Adjacent findings are collected for the report, not fixed or added to TODO.md. No new `TODO`/`FIXME`. In no-git mode record touched files in `State: files:`.
   - **Refactor** with tests green.
   - **Parent (integration step):** `reference/verification.md`, protocol step 8. No feature code.
8. **Review** (after build, before the verify run). Read the whole change with `git diff` (no git: re-read each file in `State: files:`) against the task line and its `Done when`:
   - Every hunk traces to the task line; no debug output, commented-out code, new `TODO`/`FIXME` or unrelated reformatting.
   - The tests assert the `Done when` criteria (not vacuous, nothing weakened, the ID in new test names, or in a docstring or comment when `Done when` fixes the name).
   - No generated files, secrets or `.env` in the diff or in any backlog text you wrote (`Blocked:`, `State:`); only plausible files changed.
   - When a subagent tool exists, have a fresh-context reviewer do this, given only the task lines, the Ref path and the diff, and report findings. Fix what is valid yourself (at most 2 rounds). The reviewer never edits files and never runs the tests. Without a subagent tool, do the same review yourself and say so (`Reviewed: self`).
9. **Verify.** Run in full and unnarrowed: the `Done when` commands, then the regression. Update `State:` after every cycle ("Test failures"). Then the gates, all of which must pass:
   - Done when exited 0 **and** really ran tests ("0 tests", "no tests found", "collected 0 items", "NO TESTS RAN" fail). Regression is green with no fewer passing tests than the baseline and none deleted or skipped.
   - Every item of the project's Definition of Done, if one exists.
   - Documentation drift check (below).
10. **Complete, in this order.**
    1. **Child or parent:** in no-git mode first copy its `files:` and `docs:` into the root's `State:`; then set `[x]`, delete `State:`, run the invariant check. **Root:** skip this (a root is never `[x]`; item 4 drains it and lints).
    2. In git mode commit the node's files by explicit path, plus `TODO.md` when it changed, so the tree is clean for the merge or refresh that follows: `<type>(<scope>): <title>`, body `Refs: <ID>` and `Reviewed: <subagent|self>, <n> findings fixed` (`reference/git-flow.md`, "Commits").
    3. **Child:** switch to the parent's branch, `git merge --no-ff` the child with the message `Merge <ID> into <PARENT-ID>`, `git branch -d` it (`git worktree remove` first with a worktree). Report and stop; the node stays `[x]` until its root drains.
    4. **Root** (a leaf root, or all children `[x]` and the integration step just passed), in this order:
       1. Refresh from the base (`reference/git-flow.md`); if it brought changes, rerun `Done when` and the full regression.
       2. **Last gate:** if `.todo/check.sh` exists, read it first: it must hold only the shebang, comments, `set -eu`, `cd`, the lint line and test commands that pass the command-safety rules (`reference/verification.md`); otherwise show it and ask. Then run `bash .todo/check.sh`. Red blocks the root ("Test failures").
       3. Drain: (a) insert one entry as the core's "CHANGELOG entry" says; (b) delete the subtree from TODO.md; (c) lint; (d) commit `CHANGELOG.md` and `TODO.md` as `chore(backlog): drain <ID>` with the body `Refs: <ID>` (plus `Includes: <IDs>` when it has descendants).
       4. With `--merge`: as git-flow "Root" says (base moved: refresh and verify again), switch to the base (from a worktree: go to the main checkout), `git merge --no-ff` the root branch with `Merge <ID> into <base>`, `git worktree remove` its worktree if it has one, `git branch -d` it. Otherwise print the commands git-flow "Root" lists. Never push.
       No git: only the drain items (a) to (c).
11. **Report**, short (also when a step above stops early: say which step and why): ID and title, commands run and results (regression counts against the baseline), files changed, branch and commit, `children done/total` for a parent root; the checked-out branch; for a root without `--merge` the merge commands. Then adjacent problems as ready-to-run `/todo-add "<description>" --from <ID>` commands (never add them yourself), the next workable node without starting it (or "none"), and a suggestion to clear context.

## Test failures

- Diagnose before changing code: reproduce, read the first failing assertion, state one hypothesis in `State:` (`hyp:`), make the smallest change that tests it, re-run.
- At most **3** attempts in total across sessions (`State:` counter). An attempt is a failed verification run after you started implementing; the first red run is not one.
- You may change code and the tests the node itself creates, inside the task line's scope.
- Forbidden: editing the `Done when` commands, deleting, skipping or weakening tests, `|| true`, loosening assertions, or a narrower command to get green.
- A failure outside the node (flaky test, a regression that cannot be fixed within the task line) is not fixed here. Block the node: `[!]`, replace `State:` with `Blocked: <reason> → \`<command>\` <last ≤5 error lines joined with " / ", secrets and tokens redacted> → <action required>`. In git mode commit the node's changed files (by explicit path) with `TODO.md` as `chore(backlog): block <ID>`, so the work in progress stays on the node's branch; stop. After the third failed cycle, block the same way listing each hypothesis tried. A blocked root works the same way.
- Run commands only under the safety rules in `reference/verification.md`.

## Lanes

With `--lane` or `--all-lanes`, read `reference/lanes.md` from the core's folder (`../todo/reference/lanes.md`) and follow it. Without a lane flag all lanes are one queue and you work alone.

## Documentation drift

- If the implementation must deviate from the `Ref` doc, stop and choose with the user: change the code, or update the doc inside this node with approval.
- Before completing, `grep` README.md and `docs/` for the names of any public command, flag, endpoint, config key or symbol the node changed. Update stale hits if that fits the task line (note `Docs: updated <file>` for the CHANGELOG entry); otherwise report them with the exact `/todo-add` command.
- If README setup or test instructions disagree with the commands that passed, report it.
- TODO.md never duplicates docs content; move spec-like substance into `docs/` and leave a `Ref:`.
