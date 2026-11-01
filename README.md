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
| `/todo` | `skills/todo` | Core rules: schemas, IDs, invariants, git-conflict handling, guardrails. Run directly, it only lists commands and checks invariants (read-only) |
| `/todo-init` | `skills/todo-init` | Creates a missing `TODO.md` / `CHANGELOG.md`, detects the test runner, reports status |
| `/todo-add <description> [--priority P0\|P1\|P2] [--ref <docs-path>] [--type feat\|fix\|task]` | `skills/todo-add` | Adds one atomic task to Ready |
| `/todo-continue` | `skills/todo-continue` | Executes one task: read refs, implement, validate, drain to `CHANGELOG.md` |
| `/todo-update <ID> [--status in-progress\|blocked\|ready\|drop] [--note "..."]` | `skills/todo-update` | Manual state changes and in-place field edits |

The four command skills load `todo` first, so keep the five folders side by side.

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
Work is tracked in TODO.md and CHANGELOG.md with the todo-* skills (/todo-init, /todo-add, /todo-continue, /todo-update). Read the `todo` skill before editing TODO.md. Do not change TODO.md outside these commands.
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
  - Validation: `npm test -- auth/middleware`
```

## Design rules

- One active task at a time, enforced by file state.
- A task closes only when its Validation command runs and passes. A run that executes zero tests does not count.
- Backlog changes come only from a user command or a completed code transition. The agent never invents tasks. Adjacent findings are returned as suggested `/todo-add` commands.
- Validation commands are limited to test, lint, typecheck and build commands, because `TODO.md` text can be influenced by docs and pull requests.
- Nothing is stored outside Markdown and git. The agent never pushes, tags or cuts a release.

## Known limits

- No upfront spec or brainstorming phase. Requirements are expected to exist in `docs/`.
- No independent reviewer. `todo-continue` self-reviews its diff against Scope.
- One agent per working tree. Use one git worktree per agent for parallel work.
- Skill triggering depends on the agent runtime. The `AGENTS.md` pointer above reduces misses.

## This repo's own backlog

`TODO.md` and `CHANGELOG.md` in this repository follow the same schemas.
