# todo-skills

[![test](https://github.com/bassemZohdy/todo-skills/actions/workflows/test.yml/badge.svg)](https://github.com/bassemZohdy/todo-skills/actions/workflows/test.yml) MIT licensed · version 0.1.0 (early, see [Status](#status))

Skills that let a coding agent run a software backlog from two Markdown files, `TODO.md` and `CHANGELOG.md`. No tracker, no database, no framework: the repository is the state machine.

- **One task tree** in `TODO.md`. Each task is 2 to 4 lines: what to do, and the exact command that proves it is done. Big work is split until every leaf is small.
- **A git branch per task.** Tests are written first, then `Done when` and the full regression run against a baseline taken before coding. Nothing reaches your main branch before its whole tree is verified.
- **Plan, review, report.** `/todo-plan` (and `--revise` when the plan is off), a review step before verification, lanes for parallel agents, and an interactive `docs/status.html`.
- **Safe by construction.** The skills never touch the network, tag or push. No required tooling beyond Markdown; git is used when present.

```markdown
- [ ] **FEAT-002** · P1 · L · Add token refresh to the auth service
  - Done when: old token rejected after refresh; `npm test -- auth`; regression: `npm test`
  - Links: Ref: docs/auth.md#refresh · Lane: api
  - [/] **FEAT-002.1** · M · Rotate refresh tokens
    - Done when: reuse of a rotated token fails; `npm test -- auth/rotate`
    - State: attempts 1/3; baseline 42 passing; branch todo/FEAT-002.1-rotate-refresh-tokens from todo/FEAT-002-add-token-refresh-auth; next: add reuse test
```

## Quick start

```bash
git clone https://github.com/bassemZohdy/todo-skills
mkdir -p ~/.claude/skills && cp -r todo-skills/skills/* ~/.claude/skills/
```

Then, in your project:

```text
/todo-init
/todo-add Reject expired JWTs in the auth middleware --priority P0
/todo-continue
```

The full walkthrough is in [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md). Try it in a scratch repository first.

## Commands

| Command | Skill folder | What it does |
|---|---|---|
| `/todo` | `skills/todo` | Core rules: tree format, sizes, IDs, git flow, invariants, Definition of Done, guardrails. Run directly, it only lists commands and checks invariants (read-only) |
| `/todo-init [--plan]` | `skills/todo-init` | Creates a missing `TODO.md` / `CHANGELOG.md`, detects git and the test runner, migrates the old format, reports status. `--plan` adds up to 3 pre-planning questions and an optional `docs/plans/PROJECT.md` |
| `/todo-plan [<goal>] [--revise [<reason>]]` | `skills/todo-plan` | Plans the work into lanes and a proposed tree. `--revise` re-plans at any time: only open `[ ]` nodes change, you confirm the diff, IDs are kept |
| `/todo-add <description> [--priority P0\|P1\|P2] [--ref <docs-path>] [--type feat\|fix\|task] [--from <ID>] [--parent <ID>] [--clarify]` | `skills/todo-add` | Sizes the request and adds a task, or a whole tree, until every leaf is S or M. Asks up to 3 questions when unclear |
| `/todo-continue [--plan] [--lane <name> \| --all-lanes [--seq]] [--worktree] [--merge]` | `skills/todo-continue` | Executes one node: branch, tests first, review, verify plus regression, merge into the parent, drain a finished root. Lane flags run one subagent per lane |
| `/todo-update <ID> [--status in-progress\|blocked\|ready\|drop\|revert] [--note "..."]` | `skills/todo-update` | Manual state changes (dotted IDs allowed) and in-place field edits |
| `/todo-status [--search <text>] [--last <N>]` | `skills/todo-status` | Read-only tree by lane, recent history and search |
| `/todo-report` | `skills/todo-report` | Writes `docs/status.html`: an interactive, self-contained page with KPIs, lanes, the filterable task tree (Done when, links, state, blockers), release history, claims, test command and the plan |
| `/todo-release [--version X.Y.Z]` | `skills/todo-release` | Proposes a semantic version from the `[Unreleased]` entries and, after you confirm, writes the dated section. Prints the tag and push commands; never runs them |

All nine skill folders go together: the command skills load the `todo` core skill and its `reference/` files.

## Install

- **Claude Code skills:** copy `skills/*` to `~/.claude/skills/` (all projects) or `.claude/skills/` (one project), as above.
- **Claude Code plugin:** `/plugin marketplace add bassemZohdy/todo-skills`, then `/plugin install todo-skills@todo-skills`. Commands are namespaced, for example `/todo-skills:todo-add`.
- **Other agents** (Codex, Cursor, and so on): the skills are plain Markdown. Copy `skills/` where your agent reads skills, or point its `AGENTS.md` at `skills/todo/SKILL.md`. Only git and bash are needed, and nothing is Claude-specific, but only Claude Code has been tested.

Skills load when their description matches, so add this to `AGENTS.md` or `CLAUDE.md` for reliable use:

```markdown
## Backlog
Work is tracked in TODO.md and CHANGELOG.md with the todo-* skills (/todo-init, /todo-plan, /todo-add, /todo-continue, /todo-update, /todo-status, /todo-report). Read the `todo` skill before editing TODO.md. Do not change TODO.md outside these commands.
```

## How it works

| Layer | File | Role |
|---|---|---|
| Requirements | `README.md`, `docs/*.md` | Ground truth, read-mostly |
| Active queue | `TODO.md` | One task tree, capped at 120 lines |
| Validation | Source and tests | What decides "done" |
| Version store | git | A branch or worktree per task |
| Archive | `CHANGELOG.md` | Append-only, Keep a Changelog + Conventional Commits |

The lifecycle of every node is: ready check → branch → claim `[/]` → red, green, refactor → **review** → verify (Done when + regression) → complete `[x]` → merge into the parent; a finished root is drained into `CHANGELOG.md`. The marker on each task is its status, and every command acts only as that status allows. Details: [docs/LIFECYCLE.md](docs/LIFECYCLE.md) (diagram, command-by-status matrix, the SDLC practices applied) and [docs/REFERENCE.md](docs/REFERENCE.md) (task format, sizes, claims, verification, lanes, planning, lint and hook, versioning, design rules).

## Optional checks

`bash skills/todo/scripts/todo-lint.sh` checks the backlog rules (I1-I10) and warns about weak test commands; an optional Claude Code Stop hook runs it at the end of a session. Both are read-only and need only bash, awk and grep. `bash tests/run.sh` runs the fixture and hook tests.

## Status

Version 0.1.0 is early. What exists: the specification, a lint with fixtures, and fresh-agent trials of nine scenarios in scratch projects (interrupted merge, refresh from base, claims and races, release, monorepo, lanes through the sequential fallback, replan). What does not: use on real projects or teams, a tested parallel `--all-lanes` run, and any agent besides Claude Code. "Done" is enforced by the agent following the rules and by the optional lint, not by a sandbox, so read a task before you let an agent run its command. [docs/COMPARISON.md](docs/COMPARISON.md) scores todo-skills against eight similar tools (75 and 71 under two weightings, by an independent reviewer; read the caveats there).

Known limits: planning is shallow (a short plan doc and the tree), the 120-line cap holds about 28 tasks (big trees are decomposed lazily), sharing claims between clones is left to git, and the review step is a self-review when no subagent tool exists.

## Contributing and support

Trial reports are the most useful contribution: run it on a project and open an issue. See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) and the [code of conduct](CODE_OF_CONDUCT.md). Versions follow [Semantic Versioning](https://semver.org/) (policy in [docs/REFERENCE.md](docs/REFERENCE.md#versioning)); see [CHANGELOG.md](CHANGELOG.md). This repository tracks its own work with the same `TODO.md` and `CHANGELOG.md`.

## License

[MIT](LICENSE)
