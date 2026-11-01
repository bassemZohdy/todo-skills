# todo-skills

Agent skills for tracking software work in two Markdown files, `TODO.md` and `CHANGELOG.md`. There is no issue tracker, no database and no framework. The repository is the state machine.

A task is one atomic unit with a Scope, an Out of Scope list, a Ref to the governing doc and an exact Validation command. It lives in `TODO.md` until its Validation passes. Then it is written to `CHANGELOG.md` and deleted from `TODO.md`, so the active queue stays small enough for an agent's context window.

## The four layers

| Layer | File | Role |
|---|---|---|
| Requirements | `README.md`, `docs/*.md` | Ground truth. Read-mostly |
| Active queue | `TODO.md` | Atomic work items, capped at ~120 lines |
| Validation | Source and tests | What decides "done" |
| Archive | `CHANGELOG.md` | Append-only, Keep a Changelog + Conventional Commits |

## Skills

| Command | Skill folder | What it does |
|---|---|---|
| `/todo` | `skills/todo` | Core rules: schemas, IDs, invariants, Definition of Done, git-conflict handling, guardrails. Run directly, it only lists commands and checks invariants (read-only) |
| `/todo-init` | `skills/todo-init` | Creates a missing `TODO.md` / `CHANGELOG.md`, detects the test runner, reports status |
| `/todo-add <description> [--priority P0\|P1\|P2] [--ref <docs-path>] [--type feat\|fix\|task] [--from <ID>] [--clarify]` | `skills/todo-add` | Adds one atomic task to Ready. Asks up to 3 questions when the request is unclear |
| `/todo-continue [--plan] [--isolated]` | `skills/todo-continue` | Executes one task: read refs, implement, validate, drain to `CHANGELOG.md` |
| `/todo-update <ID> [--status in-progress\|blocked\|ready\|drop] [--note "..."]` | `skills/todo-update` | Manual state changes and in-place field edits |
| `/todo-status [--search <text>] [--last <N>]` | `skills/todo-status` | Read-only status, recent history and search |

The command skills load `todo` first, so keep the six folders side by side.

### `/todo-continue` flags

- `--plan` stops after reading the docs and prints a short plan. The next `/todo-continue` counts as approval.
- `--isolated` runs the implement-and-validate steps in a fresh-context subagent. The main thread re-runs Validation and reviews the diff itself.

On `main`, `master` or `trunk` it first creates a local branch `todo/<ID>-<slug>`. It never pushes.

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

## Task format

```markdown
- [ ] **FIX-004** · P0 · Reject expired JWTs in the auth middleware
  - Scope: Add an expiry check in `auth/middleware.ts` before the role lookup.
  - Out of Scope: Refresh-token flow, session storage, changes to the token format.
  - Ref: docs/auth.md#tokens
  - Depends: TASK-003            (optional: must be in CHANGELOG.md first)
  - From: FIX-002                (optional: the task during which this was found)
  - Validation: `npm test -- auth/middleware`
  - Progress: attempts 1/3; done: ...; next: ...   (written by /todo-continue)
```

`Progress:` is the only state that survives a context reset. It carries the fix-attempt counter so the 3-attempt limit holds across sessions.

## Definition of Done

Optional. If `README.md`, `CONTRIBUTING.md` or a file in `docs/` has a heading `Definition of Done`, its checklist applies to every task on top of that task's Validation. Command items run under the same safety rules as Validation. Statement items are checked by inspection and reported one by one.

## Optional enforcement

The invariants (one active task, unique IDs, required fields, 120-line cap, no ID in both files, exact headings, no dangling references) can be checked by a script instead of by the model. Both scripts are read-only, need only bash, awk and grep, and are installed with the `todo` skill.

```bash
bash ~/.claude/skills/todo/scripts/todo-lint.sh          # from the repository root
```

Exit code 0 means I1-I7 hold. Use it as a pre-commit hook or a CI step. To stop an agent session from ending on a corrupted backlog, add a Claude Code Stop hook:

```json
{ "hooks": { "Stop": [ { "hooks": [
  { "type": "command", "command": "bash .claude/skills/todo/scripts/todo-stop-hook.sh" }
] } ] } }
```

The hook blocks the stop once with the lint output and never loops (it honors `stop_hook_active`).

Run the tests for both scripts with `bash tests/run.sh`. They use static fixtures in `tests/fixtures` and create no files.

## Design rules

- One active task at a time, enforced by file state.
- A task closes only when its Validation command runs and passes. A run that executes zero tests does not count.
- Backlog changes come only from a user command or a completed code transition. The agent never invents tasks. Adjacent findings are returned as ready-to-run `/todo-add ... --from <ID>` commands.
- Validation commands are limited to test, lint, typecheck and build commands, because `TODO.md` text can be influenced by docs and pull requests.
- Nothing is required beyond Markdown and git. The agent never pushes, tags or cuts a release.

## Comparison

[docs/COMPARISON.md](docs/COMPARISON.md) scores todo-skills against Superpowers, Spec Kit, BMAD, OpenSpec, Backlog.md, beads, Taskmaster and GSD, under two weightings. In short, it is competitive for lean solo work and weak on planning depth, team work and maturity.

## Known limits

- Planning is shallow: `--plan` and `--clarify` only. Requirements are expected to exist in `docs/`.
- The only independent review is `--isolated`, and it needs a subagent tool.
- One agent per working tree. Use one git worktree per agent for parallel work.
- Skill triggering depends on the agent runtime. The `AGENTS.md` pointer above reduces misses.
- The skills have not been run in live agent sessions yet. Only the lint script and stop hook have automated tests.

## This repo's own backlog

`TODO.md` and `CHANGELOG.md` in this repository follow the same schemas.
