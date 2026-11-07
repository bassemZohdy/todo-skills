# todo-skills

[![test](https://github.com/bassemZohdy/todo-skills/actions/workflows/test.yml/badge.svg)](https://github.com/bassemZohdy/todo-skills/actions/workflows/test.yml) MIT licensed · version 0.3.0 (early, see [Status](#status))

Skills that let a coding agent run a software backlog from two Markdown files, `TODO.md` and `CHANGELOG.md`. No tracker, no database, no framework: the repository is the state machine.

- **One task tree** in `TODO.md`. Each task is 2 to 4 lines: what to do, and the exact command that proves it is done. Big work is split until every leaf is small.
- **A git branch per task.** Tests are written first, then `Done when` and the full regression run against a baseline taken before coding. Nothing reaches your main branch before its whole tree is verified.
- **Plan, review, report.** `/todo-plan` (and `--revise` when the plan is off), a review step before verification, lanes for parallel agents, and an interactive `docs/status.html`.
- **Safe by construction.** The skills never touch the network, tag or push. No required tooling beyond Markdown; git is used when present.

```markdown
- [ ] **FEAT-002** · P1 · mid · L · Add token refresh to the auth service
  - Done when: old token rejected after refresh; `npm test -- auth`; regression: `npm test`
  - Links: Ref: docs/auth.md#refresh · Lane: api
  - [/] **FEAT-002.1** · high · M · Rotate refresh tokens
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
| `/todo` | `skills/todo` | Core rules: tree format, complexity (low/mid/high, for model choice) and optional sizes, IDs, git flow, invariants, Definition of Done, guardrails. Run directly, it only lists commands and checks invariants (read-only) |
| `/todo-init [--plan]` | `skills/todo-init` | Creates a missing `TODO.md` / `CHANGELOG.md`, detects git and the test runner, migrates the old format, reports status. `--plan` adds up to 3 pre-planning questions and an optional `docs/plans/PROJECT.md` |
| `/todo-plan [<goal>] [--revise [<reason>]]` | `skills/todo-plan` | Plans the work into lanes and a proposed tree. `--revise` re-plans at any time: only open `[ ]` nodes change, you confirm the diff, IDs are kept |
| `/todo-add <description> [--priority P0\|P1\|P2] [--ref <docs-path>] [--type feat\|fix\|task] [--from <ID>] [--parent <ID>] [--lane <name>] [--clarify]` | `skills/todo-add` | Splits the request, rates each node's complexity and adds a task, or a whole tree, until every leaf is S or M. Asks up to 3 questions when unclear |
| `/todo-continue [--plan] [--lane <name> \| --all-lanes [--seq]] [--worktree] [--delegate] [--merge]` | `skills/todo-continue` | Executes one node: branch, tests first, review, verify plus regression, merge into the parent, drain a finished root. Lane flags run one subagent per lane |
| `/todo-update <ID> [--status in-progress\|blocked\|ready\|drop\|revert] [--note "..."]` | `skills/todo-update` | Manual state changes (dotted IDs allowed) and in-place field edits |
| `/todo-status [--search <text>] [--last <N>]` | `skills/todo-status` | Read-only tree by lane, recent history and search |
| `/todo-report` | `skills/todo-report` | Writes `docs/status.html`: an interactive, self-contained page with KPIs, lanes, the filterable task tree (Done when, links, state, blockers), release history, claims, test command and the plan |
| `/todo-release [--version X.Y.Z]` | `skills/todo-release` | Proposes a semantic version from the `[Unreleased]` entries and, after you confirm, writes the dated section. Prints the tag and push commands; never runs them |

All nine skill folders go together: the command skills load the `todo` core skill and its `reference/` files.

## Install

- **Claude Code skills:** copy `skills/*` to `~/.claude/skills/` (all projects) or `.claude/skills/` (one project), as above.
- **Claude Code plugin:** `/plugin marketplace add bassemZohdy/todo-skills`, then `/plugin install todo-skills@todo-skills`. Commands are namespaced, for example `/todo-skills:todo-add`.
- **Codex plugin:** `codex plugin marketplace add bassemZohdy/todo-skills`, then `codex plugin add todo-skills@todo-skills`. Verified on codex-cli 0.167.0: the marketplace is read from `.agents/plugins/marketplace.json` and all nine skills install from `.codex-plugin/plugin.json`.
- **Any agent via the skills CLI:** `npx skills add bassemZohdy/todo-skills` lists and installs the nine skills for the agents it supports. Add `--skill <name>` for one, but install all nine together: the command skills load the `todo` core skill.
- **Other agents** (Cursor, and so on): the skills are plain Markdown. Copy `skills/` where your agent reads skills, or point its `AGENTS.md` at `skills/todo/SKILL.md`. Only git and bash are needed, and nothing is Claude-specific. Tested: Claude Code (full use) and Codex (installs and discovers the skills; the workflows were not run end to end there).

Skills load when their description matches, so add this to `AGENTS.md` or `CLAUDE.md` for reliable use:

```markdown
## Backlog
Work is tracked in TODO.md and CHANGELOG.md with the todo-* skills (/todo-init, /todo-plan, /todo-add, /todo-continue, /todo-update, /todo-status, /todo-report, /todo-release). Read the `todo` skill before editing TODO.md. Do not change TODO.md outside these commands.
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

**CI with a local fallback.** `/todo-init --ci` writes `.todo/check.sh` (the backlog lint plus your test command) and a vendored copy of the lint. When the project has CI it adds a job that runs the check: a GitHub Actions workflow, a GitLab job on your yes, or the one line to add for other CI. Without CI it offers a git `pre-push` hook that runs the same check. Either way `/todo-continue` runs `.todo/check.sh` as the last gate before a root lands, so "done" is checked by a script, not only by the agent.

`bash skills/todo/scripts/todo-lint.sh` checks the backlog rules (I1-I10) and warns about weak test commands; an optional Claude Code Stop hook runs it at the end of a session. Optional `todo-verify.sh` rejects zero-test, masked or missing-target verification runs, and `todo-rtm.sh` checks an optional requirements traceability matrix (`docs/RTM.md`, else a README `## RTM` section). All are read-only and need only bash, awk, grep, sed and tr. `bash tests/run.sh` runs the fixture and hook tests.

Tests: `bash tests/run.sh`

## Security and disclosure

The plugin sends no data and has no network access, MCP server or shipped hook. It runs local `git`, your own test commands and four optional read-only scripts, reads project docs and the task's files, and writes only the backlog, docs and task files. It never reads credentials. Details: [SECURITY.md](SECURITY.md).

## Status

Version 0.3.0 is early. What exists: the specification, a lint with fixtures, and fresh-agent trials of eleven scenarios in scratch projects (interrupted merge, refresh from base, claims and races, release, monorepo, lanes, replan, CI setup with and without a remote). `--all-lanes` has run once with two lane subagents truly in parallel. What does not: use on real projects or teams, and any agent besides Claude Code. "Done" is enforced by the agent following the rules, by the optional lint, and, with `/todo-init --ci`, by `.todo/check.sh` in CI or a pre-push hook; none of that is a sandbox, so read a task before you let an agent run its command. [docs/COMPARISON.md](docs/COMPARISON.md) scores todo-skills against eight similar tools (78 and 73 under two weightings, by an independent reviewer; read the caveats there).

Known limits: planning is shallow (a short plan doc and the tree), the 120-line cap holds about 30 tasks (big trees are decomposed lazily), sharing claims between clones is left to git, and the review step is a self-review when no subagent tool exists.

## Contributing and support

Trial reports are the most useful contribution: run it on a project and open an issue. See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) and the [code of conduct](CODE_OF_CONDUCT.md). Versions follow [Semantic Versioning](https://semver.org/) (policy in [docs/REFERENCE.md](docs/REFERENCE.md#versioning)); see [CHANGELOG.md](CHANGELOG.md). This repository tracks its own work with the same `TODO.md` and `CHANGELOG.md`.

## License

[MIT](LICENSE)

A project-level Claude Code install may be discovered by a running session without a restart; availability depends on the client version. The installed lint script is a copy: keep any project-vendored `.todo/todo-lint.sh` synchronized when upgrading or patching `skills/todo/scripts/todo-lint.sh`.
