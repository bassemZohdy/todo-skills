# todo-skills

Agent skills for tracking software work in two Markdown files, `TODO.md` and `CHANGELOG.md`. There is no issue tracker, no database and no framework. The repository is the state machine.

Work is one **task tree** in `TODO.md`. Each task is 2 to 4 lines: what to do, and how it is validated, with the exact test command. Big work is broken into children (`FEAT-002.1`, `FEAT-002.1.2`) until every leaf is small. Each node is built on its own git branch or worktree, verified with its tests and a regression run, and merged into its parent. Only a finished root is drained to `CHANGELOG.md`, as a single entry, so the active queue stays small enough for an agent's context window. Without git the skills still work, just without branches and commits.

## The four layers

| Layer | File | Role |
|---|---|---|
| Requirements | `README.md`, `docs/*.md` | Ground truth. Read-mostly |
| Active queue | `TODO.md` | One task tree of 2-4 line work items, capped at 120 lines |
| Validation | Source and tests | What decides "done" |
| Version store | git | A branch or worktree per task. Nothing reaches the base branch unverified |
| Archive | `CHANGELOG.md` | Append-only, Keep a Changelog + Conventional Commits |

## Skills

| Command | Skill folder | What it does |
|---|---|---|
| `/todo` | `skills/todo` | Core rules: tree format, sizes, IDs, git flow, invariants, Definition of Done, guardrails. Run directly, it only lists commands and checks invariants (read-only) |
| `/todo-init` | `skills/todo-init` | Creates a missing `TODO.md` / `CHANGELOG.md`, detects git and the test runner, migrates the old format, reports status |
| `/todo-add <description> [--priority P0\|P1\|P2] [--ref <docs-path>] [--type feat\|fix\|task] [--from <ID>] [--parent <ID>] [--clarify]` | `skills/todo-add` | Sizes the request and adds a task, or a whole tree, until every leaf is S or M. Asks up to 3 questions when unclear |
| `/todo-continue [--plan] [--isolated] [--worktree] [--merge]` | `skills/todo-continue` | Executes one node: branch, tests first, verify plus regression, merge into the parent, drain a finished root |
| `/todo-update <ID> [--status in-progress\|blocked\|ready\|drop\|revert] [--note "..."]` | `skills/todo-update` | Manual state changes (dotted IDs allowed) and in-place field edits |
| `/todo-status [--search <text>] [--last <N>]` | `skills/todo-status` | Read-only tree, recent history and search |
| `/todo-release [--version X.Y.Z]` | `skills/todo-release` | Proposes a semantic version from the `[Unreleased]` entries and, after you confirm, writes the dated section. Prints the tag and push commands; never runs them |

The command skills load `todo` first, so keep the seven folders side by side. The core skill keeps two reference files in `skills/todo/reference/` (`git-flow.md`, `verification.md`) that only the commands needing them read, which keeps the always-loaded part small.

### `/todo-continue` flags

- `--plan` stops after reading the docs and prints a short plan. The next `/todo-continue` counts as approval.
- `--isolated` runs the implement-and-verify steps in a fresh-context subagent. The main thread re-runs the commands and reviews the diff itself.
- `--worktree` builds the node in its own worktree (`../<repo>.todo/<ID>`) instead of switching branches.
- `--merge` also merges a finished root into the base branch. Without it the exact `git merge --no-ff` commands are printed and the merge is yours to run.

## Install

Copy the folders into the skills directory your agent reads. Use `.claude/skills/` inside one project or `~/.claude/skills/` for all projects:

```bash
git clone https://github.com/bassemZohdy/todo-skills
mkdir -p ~/.claude/skills
cp -r todo-skills/skills/* ~/.claude/skills/
```

Copying (or symlinking) keeps the short command names. Installing them as a namespaced plugin would prefix them, which is not tested here.

Skills only load when their description matches, so add this to `AGENTS.md` or `CLAUDE.md` for reliable use:

```markdown
## Backlog
Work is tracked in TODO.md and CHANGELOG.md with the todo-* skills (/todo-init, /todo-add, /todo-continue, /todo-update, /todo-status). Read the `todo` skill before editing TODO.md. Do not change TODO.md outside these commands.
```

## Typical session

```text
/todo-init
/todo-add Reject expired JWTs in the auth middleware --priority P0 --ref docs/auth.md#tokens
/todo-continue        # implements, validates, drains one task
/clear
/todo-continue        # next task, fresh context
```

## Task tree

```markdown
# Active Backlog

## 🌳 Task Tree

- [ ] **FEAT-002** · P1 · XL · Add token refresh to the auth service
  - Done when: old token rejected after refresh; `npm test -- auth`; regression: `npm test`
  - Links: Ref: docs/auth.md#refresh · Depends: TASK-001 · From: FIX-001
  - [ ] **FEAT-002.1** · L · Refresh endpoint
    - Done when: endpoint covered by an integration test; `npm test -- auth/refresh`
    - [x] **FEAT-002.1.1** · S · Token store interface
      - Done when: store round-trips a token; `npm test -- auth/store`
    - [/] **FEAT-002.1.2** · M · Rotate refresh tokens
      - Done when: reuse of a rotated token fails; `npm test -- auth/rotate`
      - State: attempts 1/3; branch todo/FEAT-002.1.2-rotate from todo/FEAT-002.1-refresh; next: add reuse test
```

- **2 to 4 lines per task.** The header says what to do. `Done when:` gives the criteria and at least one exact command. Longer planning goes into `docs/` (for example `docs/plans/FEAT-002-refresh.md`) and is linked with `Ref:`. TODO.md only tracks work.
- **Markers:** `[ ]` open, `[/]` active (only one), `[!]` blocked, `[x]` verified and merged into its parent, waiting for the root to drain.
- **Sizes:** leaves are `S` (at most 2 files) or `M` (one context window, at most 5 files). Parents are `L` (children are leaves) or `XL` (has grandchildren). At most 3 levels. The lint script enforces this.
- **Order:** roots by priority P0 to P2, then by ID. Inside a root, depth first. A parent becomes workable again when all its children are `[x]`; that is its integration step.
- **Closing:** a child is merged into its parent's branch when verified. A parent closes only when all children are done, and the whole tree is written to `CHANGELOG.md` as one entry ending in `Includes: FEAT-002.1, FEAT-002.1.1, ...`.
- **Blocked** tasks replace `State:` with `Blocked: reason → \`command\` error → action required`.

## Lifecycle

The marker is the status, and every command acts only as that status allows. The branch is created **before** the task is marked in progress:

`[ ]` ready check → create branch → `[/]` claim → red, green, refactor → verify (Done when + regression + gates) → `[x]` commit → merge into the parent's branch. A root is then drained to `CHANGELOG.md` and merged into the base branch only with `--merge`. `[!]` blocked stops the flow until `/todo-update --status ready`.

See [docs/LIFECYCLE.md](docs/LIFECYCLE.md) for the diagram, the command-by-status matrix and how it maps to short-lived branches, Definition of Ready and Done, red-green-refactor, regression testing and CI parity.

## Claims: no tree runs twice

When the first node of a tree is claimed, the root branch gets a claim-only commit (`State: branch todo/<ID>-<slug> from main` on the root, plus any pending backlog edits), and the base branch is fast-forwarded to it. Anyone starting from the base branch sees the tree as claimed, with the owning branch name, and skips it. Only the root is published; `[/]` and the children's state stay on the tree's branches. A stale claim (branch gone) is released with `/todo-update <ROOT-ID> --status ready`. A claim is a local commit. Worktrees of one repository see it at once; how it reaches other clones is left to git (push, pull request, your usual flow), and a clash shows up as a normal merge conflict.

## Verification

Each node: write the tests first, run `Done when` in full (target a test id or path, not a name filter), then run the regression command (the task's `regression:` or the full suite) and compare with the baseline taken before coding. A red baseline blocks the node. Deleted, skipped or weakened tests and runs that execute zero tests do not count. Three failed fix cycles block the node.

## Git flow and no-git mode

- One branch per node, `todo/<ID>-<slug>`. A root starts from the base branch, a child from its parent's branch. Verified children are merged `--no-ff` into the parent's branch. Nothing is merged into `main` or `develop` until the root is verified, and then only with `--merge`. The one earlier change on the base branch is the tree claim.
- **No git repository?** Every command warns once and carries on without branches, worktrees, commits or merges. Progress and touched files are recorded in `State:`, and markers and the CHANGELOG drain work as usual. Run `git init` to get isolation and history.

## Definition of Done

Optional. If `README.md`, `CONTRIBUTING.md` or a file in `docs/` has a heading `Definition of Done`, its checklist applies to every task on top of that task's Validation. Command items run under the same safety rules as Validation. Statement items are checked by inspection and reported one by one.

## Optional enforcement

The invariants I1-I10 (one active task, unique IDs, task fields and size limits, 120-line cap, no ID in both files, exact headings, no dangling references, tree integrity, no dependency cycles, no forbidden commands) can be checked by a script instead of by the model. Both scripts are read-only, need only bash, awk and grep, and are installed with the `todo` skill.

```bash
bash ~/.claude/skills/todo/scripts/todo-lint.sh          # from the repository root
```

Exit code 0 means I1-I10 hold. It also prints `WARN` lines that never fail the run: W1 for a `Done when` that only checks text or files exist, W2 for tests selected by a name filter that some runners accept with zero matches, W3 for a command that is not a known test, lint, typecheck or build runner. Use it as a pre-commit hook or a CI step. To stop an agent session from ending on a corrupted backlog, add a Claude Code Stop hook:

```json
{ "hooks": { "Stop": [ { "hooks": [
  { "type": "command", "command": "bash .claude/skills/todo/scripts/todo-stop-hook.sh" }
] } ] } }
```

The hook blocks the stop once with the lint output and never loops (it honors `stop_hook_active`).

Run the tests for both scripts with `bash tests/run.sh`. They use static fixtures in `tests/fixtures` and create no files.

## Design rules

- One active task at a time, enforced by file state.
- A node closes only when its `Done when` command and the regression run pass. A run that executes zero tests does not count.
- Nothing reaches the base branch before its root is verified.
- Backlog changes come only from a user command or a completed code transition. The agent never invents tasks. Adjacent findings are returned as ready-to-run `/todo-add ... --from <ID>` commands.
- `Done when` commands are limited to test, lint, typecheck and build commands, because `TODO.md` text can be influenced by docs and pull requests.
- Nothing is required beyond Markdown. Git is used when present. The skills never tag, release, fetch, pull or push; sharing is git's job.

## Comparison

[docs/COMPARISON.md](docs/COMPARISON.md) scores todo-skills against Superpowers, Spec Kit, BMAD, OpenSpec, Backlog.md, beads, Taskmaster and GSD, under two weightings (scored before the task tree and git flow were added, so the numbers are stale). In short, it is competitive for lean solo work and weak on planning depth, team work and maturity.

## Known limits

- Planning is shallow: the tree breakdown, `--plan` and `--clarify`. Requirements and long plans are expected to live in `docs/`.
- There is no Out of Scope field any more. Boundaries live in the task sentence or in the linked doc.
- The 120-line cap holds roughly 28 tasks, so big trees are decomposed lazily.
- The only independent review is `--isolated`, and it needs a subagent tool.
- One agent per working tree. Use `--worktree` for parallel work.
- Skill triggering depends on the agent runtime. The `AGENTS.md` pointer above reduces misses.
- The skills have not been run in live agent sessions yet. Only the lint script and stop hook have automated tests (`tests/run.sh`).

## This repo's own backlog

`TODO.md` and `CHANGELOG.md` in this repository follow the same schemas.
