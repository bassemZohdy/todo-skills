# Reference

The full format and rules of the todo-skills. The rules themselves live in [`plugin/skills/todo/SKILL.md`](../plugin/skills/todo/SKILL.md) (the model reads that file); this page is the human-readable version. New here? Start with [GETTING-STARTED.md](GETTING-STARTED.md).

## Task tree

```markdown
# Active Backlog

## 🌳 Task Tree

- [ ] **FEAT-002** · P1 · mid · XL · Add token refresh to the auth service
  - Done when: old token rejected after refresh; `npm test -- auth`; regression: `npm test`
  - Links: Ref: docs/auth.md#refresh · Depends: TASK-001 · From: FIX-001
  - [ ] **FEAT-002.1** · mid · L · Refresh endpoint
    - Done when: endpoint covered by an integration test; `npm test -- auth/refresh`
    - [x] **FEAT-002.1.1** · low · S · Token store interface
      - Done when: store round-trips a token; `npm test -- auth/store`
    - [/] **FEAT-002.1.2** · high · M · Rotate refresh tokens
      - Done when: reuse of a rotated token fails; `npm test -- auth/rotate`
      - State: attempts 1/3; branch todo/FEAT-002.1.2-rotate-refresh-tokens from todo/FEAT-002.1-refresh-endpoint; next: add reuse test
```

- **2 to 4 lines per task.** The header says what to do. `Done when:` gives the criteria and at least one exact command. Longer planning goes into `docs/` (for example `docs/plans/FEAT-002-refresh.md`) and is linked with `Ref:`. TODO.md only tracks work.
- **Markers:** `[ ]` open, `[/]` active (only one), `[!]` blocked, `[x]` verified and merged into its parent, waiting for the root to drain.
- **Complexity** (required): `low`, `mid` or `high`, how hard the reasoning is, so an agent can pick a model. An optional README line `Models: low=…, mid=…, high=…` maps levels to models for `--delegate`, lane subagents and the reviewer; a failed attempt escalates one tier.
- **Sizes** (optional, after the complexity): leaves are `S` (at most 2 files) or `M` (one context window, at most 5 files). Parents are `L` (children are leaves) or `XL` (has grandchildren). Every leaf must fit one context window whether or not a size is written. At most 3 levels. The lint script enforces this.
- **Order:** roots by priority P0 to P2, then by ID. Inside a root, depth first. A parent becomes workable again when all its children are `[x]`; that is its integration step.
- **Closing:** a child is merged into its parent's branch when verified. A parent closes only when all children are done, and the whole tree is written to `CHANGELOG.md` as one entry ending in `Includes: FEAT-002.1, FEAT-002.1.1, ...`.
- **Blocked** tasks replace `State:` with `Blocked: reason → \`command\` error → action required`.

## Lifecycle

The marker is the status, and every command acts only as that status allows. The branch is created **before** the task is marked in progress:

`[ ]` ready check → create branch → `[/]` claim → red, green, refactor → verify (Done when + regression) → `[x]` commit → merge into the parent's branch. A root is then drained to `CHANGELOG.md` and merged into the base branch only with `--merge`. `[!]` blocked stops the flow until `/todo-update --status ready`.

See [LIFECYCLE.md](LIFECYCLE.md) for the diagram, the command-by-status matrix and how it maps to short-lived branches, Definition of Ready and Done, red-green-refactor, regression testing and CI parity.

## Claims: no tree runs twice

When the first node of a tree is claimed, the root branch gets a claim-only commit (`State: branch todo/<ID>-<slug> from main` on the root, plus any pending backlog edits), and the base branch is fast-forwarded to it. Anyone starting from the base branch sees the tree as claimed, with the owning branch name, and skips it. Only the root is published; `[/]` and the children's state stay on the tree's branches. A stale claim (branch gone) is released with `/todo-update <ROOT-ID> --status ready`. A root you have just added and not yet committed is claimable: the claim commit carries those pending backlog edits, and if another claim wins the race (or a root with the same ID appears on the base) they stay on your branch for you to restore. A claim is a local commit. Worktrees of one repository see it at once; how it reaches other clones is left to git (push, pull request, your usual flow), and a clash shows up as a normal merge conflict.

## Verification

Each node: write the tests first, run `Done when` in full (target a test id or path, not a name filter), then run the regression command (the task's `regression:` or the full suite) and compare with the baseline taken before coding. A red baseline blocks the node. Deleted, skipped or weakened tests, runs that execute zero tests, masked failures (`|| true`, `; exit 0`) and test paths that do not exist do not count; the optional `todo-verify.sh` classifies a finished run, and the lint rejects masked failures in a `Done when`. Three failed fix cycles block the node.

## Git flow and no-git mode

- One branch per node, `todo/<ID>-<slug>`. A root starts from the base branch, a child from its parent's branch. Verified children are merged `--no-ff` into the parent's branch. Nothing is merged into `main` or `develop` until the root is verified, and then only with `--merge`. The one earlier change on the base branch is the tree claim.
- **No git repository?** Every command warns once and carries on without branches, worktrees, commits or merges. Progress and touched files are recorded in `State:`, and markers and the CHANGELOG drain work as usual. Run `git init` to get isolation and history.

## Requirements traceability (optional)

Simple projects need no RTM. A project that wants requirement-to-task-to-test links keeps a Markdown table (`Req | Requirement | Tasks | Verification`) in `docs/RTM.md`, or, when that file is absent, in a `## RTM` section of README.md; `docs/RTM.md` wins when both exist. `/todo-plan` and `/todo-add` link a root to a listed requirement with `Ref: <rtm path>#R-001` and propose the row change; `/todo-continue` records the node's test references in Verification; task state is never copied into the RTM, and archived task IDs keep resolving through CHANGELOG.md. `bash tools/todo-rtm.sh` (an optional script from this repository, copied into your project) prints the resolved location and flags stale task IDs (R1), archived rows without verification (R2) and duplicate requirement rows (R3). Format and rules: `plugin/skills/todo/reference/rtm.md`.

## Project Definition of Done (optional)

Optional. If `README.md`, `CONTRIBUTING.md` or a file in `docs/` has a heading `Definition of Done`, its checklist applies to every task on top of that task's Done when. Command items run under the same safety rules as Done when. Statement items are checked by inspection and reported one by one.

## Optional enforcement

The invariants I1-I10 (one active task, unique IDs, task fields, complexity and any sizes, 120-line cap, no ID in both files, exact headings, no dangling references, tree integrity, no dependency cycles, no forbidden commands) can be checked by a script instead of by the model. The scripts are read-only, need only bash, awk, grep, sed and tr, and live in `tools/` of the todo-skills repository (the plugin itself ships Markdown only); copy the ones you want into your project.

```bash
bash tools/todo-lint.sh          # from the repository root
```

Exit code 0 means I1-I10 hold. It also prints `WARN` lines that never fail the run: W1 for a `Done when` that only checks text or files exist, W2 for tests selected by a name filter that some runners accept with zero matches, W3 for a command that is not a known test, lint, typecheck or build runner, W4 for a test runner piped into another command, which hides its exit status unless `pipefail` is set. Use it as a pre-commit hook or a CI step. To stop an agent session from ending on a corrupted backlog, add a Claude Code Stop hook:

```json
{ "hooks": { "Stop": [ { "hooks": [
  { "type": "command", "command": "bash tools/todo-stop-hook.sh" }
] } ] } }
```

Use the path where you copied the script as the command. The hook blocks the stop once with the lint output and never loops (it honors `stop_hook_active`).

Run the tests with `bash tests/run.sh`. They use static fixtures in `tests/fixtures` and create no files. The agent trials and their harness tests are described in [trials.md](trials.md).

## Lanes and parallel work

A **lane** is a named track of root trees that one agent context works alone. Put `Lane: <name>` in a root's `Links:` (default lane `main`); children inherit it. A lane can hold one task or many.

- `/todo-continue --lane <name>` takes only that lane's roots, in order.
- `/todo-continue --all-lanes [--seq]` starts one subagent per lane, each in its own worktree. The main thread is the coordinator: it publishes the tree claims, then refreshes each finished root from the base, re-runs its tests, drains it and (with `--merge`) merges it, one root at a time. `--seq` runs the lanes one after another; without a subagent tool the lanes run sequentially anyway.
- Order across lanes is `Depends:` only. Lanes work best when their trees touch different files; the second and later roots to land will usually conflict in `TODO.md` and `CHANGELOG.md`, which the coordinator resolves by the conflict rules in `plugin/skills/todo/reference/git-flow.md`.

## Planning

`/todo-init --plan` asks up to three pre-planning questions and can save the answers as `docs/plans/PROJECT.md`. `/todo-plan "<goal>"` turns a goal into that plan doc and a proposed tree with lanes. `/todo-plan --revise "<reason>"` re-plans at any time: only open `[ ]` nodes change, you confirm the diff, IDs are kept, and the change is logged under *Revisions* in the plan doc.

## Review

Between build and verify, `/todo-continue` reads the whole diff against the task line and its `Done when` (hunks trace to the task, tests assert the criteria, no debug code or secrets). With a subagent tool a fresh-context reviewer does this; otherwise it is a self-review. Only then do `Done when` and the regression run.

## Status page

`/todo-report` writes `docs/status.html`: a self-contained interactive page with counts, lanes with progress, the filterable task tree (Done when, links, state, blockers), release history, claims, test command and the plan. It is a snapshot; rerun the command to refresh. The optional `tools/todo-report.sh` (bash and sed) fills the template deterministically; without it the agent does the same encoding by hand. It renders text with `textContent` only and loads nothing from the network.

## CI and the local fallback

`/todo-init --ci` (rules in `plugin/skills/todo/reference/ci.md`) writes, each on your yes:

- `.todo/check.sh`, which runs the project's test command and, when you have copied `tools/todo-lint.sh` to `.todo/todo-lint.sh` (so CI needs no skills installed; the skills never download it), the lint first;
- a CI job that runs `bash .todo/check.sh`: `.github/workflows/todo-check.yml` (runtime set up from the project's marker files), a `todo-check` job for `.gitlab-ci.yml`, or the one line to add for other CI. If CI already runs the tests, the job only runs the lint.

Fallback without CI: a git `pre-push` hook that runs the same check and refuses the push when it fails. In every case `/todo-continue` runs `.todo/check.sh` as the last gate before a root's drain, so the same lint and tests run whether or not CI exists. Commit `.todo/` and the workflow yourself; the skills never push.

## Versioning

This project follows [Semantic Versioning](https://semver.org/). The public interface is the set of things an existing project depends on: the `TODO.md` and `CHANGELOG.md` formats, the command names and flags, the `State:` grammar, the invariants the lint enforces, and the script exit codes.

- **MAJOR** when a valid `TODO.md` or `CHANGELOG.md` can become invalid, a command or flag changes meaning or is removed, or a lint invariant gets stricter in a way old files fail. While the version is `0.x`, such changes bump MINOR.
- **MINOR** for a new command, flag, optional field, warning or script that existing valid files still pass.
- **PATCH** for wording fixes, bug fixes and documentation.

The version lives in `plugin/.claude-plugin/plugin.json` and `plugin/.codex-plugin/plugin.json` and must equal the newest `## [X.Y.Z]` heading in `CHANGELOG.md` (`tests/run.sh` checks this; Codex caches an install by version, so bump it on every release). Releases are cut with `/todo-release` and tagged by a person.

## Design rules

- One active task at a time, enforced by file state.
- A node closes only when its `Done when` command and the regression run pass. A run that executes zero tests does not count.
- Nothing reaches the base branch before its root is verified.
- Backlog changes come only from a user command or a completed code transition. The agent never invents tasks. Adjacent findings are returned as ready-to-run `/todo-add ... --from <ID>` commands.
- `Done when` commands are limited to test, lint, typecheck and build commands, because `TODO.md` text can be influenced by docs and pull requests.
- Nothing is required beyond Markdown. Git is used when present. The skills never tag, release, fetch, pull or push; sharing is git's job.

## Issue reconciliation

- [Issue #11](https://github.com/bassemZohdy/todo-skills/issues/11) asks for the TASK-007 submission date and reference. Both are recorded in [distribution.md](distribution.md); TASK-007 is archived in CHANGELOG.md. Recommend closing the issue as satisfied; the directory's automatic review remains pending.
- [Issue #5](https://github.com/bassemZohdy/todo-skills/issues/5) proposes persisted progress bars in the backlog. Keep it open for discussion, but do not add derived progress state to TODO.md without a separate decision; `/todo-report` already provides a read-only view.
