# todo-skills

[![test](https://github.com/bassemZohdy/todo-skills/actions/workflows/test.yml/badge.svg)](https://github.com/bassemZohdy/todo-skills/actions/workflows/test.yml) MIT licensed · version 0.5.0 (early, see [Status](#status))

Skills that let a coding agent run a software backlog inside the repository it works on. There is no tracker, database or framework: the repository is the state machine.

- **The queue and the archive** are two Markdown files: `TODO.md` holds one task tree, `CHANGELOG.md` keeps every finished tree.
- **The rest of the state is files the project already has.** `README.md` and `docs/` say what to build and how to test it, plan docs in `docs/plans/` hold longer plans, the tests decide when a task is done, and git keeps a branch per task. Optional extras are a requirements matrix (`docs/RTM.md`), a status page (`docs/status.html`) and a check script with a CI job (`.todo/`). [What each command reads and writes](#what-the-skills-read-and-write) is listed below.
- **Small, verified steps.** Each task is 2 to 4 lines: what to do and the exact command that proves it. Big work is split until every leaf fits one context window. Tests are written first, then `Done when` and the full regression run against a baseline taken before coding. Nothing reaches your main branch before its whole tree is verified.
- **Plan, review, report.** `/todo-plan` (and `--revise` when the plan is off), a review step before verification, lanes for parallel agents, and an interactive status page.
- **Safe by construction.** The skills never touch the network, tag or push. Nothing is required beyond Markdown; git is used when present.

```markdown
- [ ] **FEAT-002** · P1 · mid · L · Add token refresh to the auth service
  - Done when: old token rejected after refresh; `npx jest tests/auth`; regression: `npm test`
  - Links: Ref: docs/auth.md#refresh · Lane: api
  - [/] **FEAT-002.1** · high · M · Rotate refresh tokens
    - Done when: reuse of a rotated token fails; `npx jest tests/auth/rotate.test.ts`
    - State: attempts 1/3; baseline 42 passing; branch todo/FEAT-002.1-rotate-refresh-tokens from todo/FEAT-002-add-token-refresh-auth; next: build
```

## Quick start

```bash
git clone https://github.com/bassemZohdy/todo-skills
mkdir -p ~/.claude/skills && cp -r todo-skills/plugin/skills/* ~/.claude/skills/
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
| `/todo` | `plugin/skills/todo` | Core rules: tree format, complexity (low/mid/high, for model choice) and optional sizes, IDs, git flow, invariants, Definition of Done, guardrails. Run directly, it only lists commands and checks invariants (read-only) |
| `/todo-init [--plan] [--ci]` | `plugin/skills/todo-init` | Creates a missing `TODO.md` / `CHANGELOG.md`, detects git, the base branch and the test command, migrates older formats, reports status. `--plan` asks up to 3 pre-planning questions and can save `docs/plans/PROJECT.md`; `--ci` sets up `.todo/check.sh` and a CI job or pre-push hook |
| `/todo-plan [<goal>] [--revise [<reason>]]` | `plugin/skills/todo-plan` | Writes a plan doc and proposes a tree split into lanes. `--revise` re-plans at any time: only open `[ ]` nodes change, you confirm the diff, IDs are kept |
| `/todo-add <description> [--priority P0\|P1\|P2] [--ref <docs-path>] [--type feat\|fix\|task] [--from <ID>] [--parent <ID>] [--lane <name>] [--clarify]` | `plugin/skills/todo-add` | Adds a task, or splits a request into a tree until every leaf fits one context window, rating each node's complexity. Asks up to 3 questions when unclear |
| `/todo-continue [--plan] [--lane <name> \| --all-lanes [--seq]] [--worktree] [--delegate] [--merge]` | `plugin/skills/todo-continue` | Executes one node: branch, tests first, review, verify plus regression, merge into the parent, drain a finished root to `CHANGELOG.md`. Lane flags run one subagent per lane |
| `/todo-update <ID> [--status in-progress\|blocked\|ready\|drop\|revert] [--note "..."]` | `plugin/skills/todo-update` | Manual state changes (dotted IDs allowed), claim releases and in-place field edits |
| `/todo-status [--search <text>] [--last <N>]` | `plugin/skills/todo-status` | Read-only tree by lane, active and next node, blockers, recent history and search |
| `/todo-report` | `plugin/skills/todo-report` | Writes `docs/status.html`: a self-contained interactive page with KPIs, lanes, the filterable task tree, release history, claims, test command and the plan |
| `/todo-release [--version X.Y.Z]` | `plugin/skills/todo-release` | Proposes a semantic version from the `[Unreleased]` entries and, after you confirm, writes the dated section and commits it. Prints the tag and push commands; never runs them |

All nine skill folders go together: the command skills load the `todo` core skill and its `reference/` files. Every flag and step is described in [docs/COMMANDS.md](docs/COMMANDS.md).

## What the skills read and write

`TODO.md` and `CHANGELOG.md` are the backlog, but the skills read and write more than those two files. Each write outside the backlog is either part of the task the agent is working on or is made only after you say yes.

| Area | Files | Read for | Written by |
|---|---|---|---|
| Backlog | `TODO.md`, `CHANGELOG.md` | Every command | `/todo-init` creates them. `/todo-add`, `/todo-plan`, `/todo-update` and `/todo-continue` edit `TODO.md`; only a root drain and `/todo-release` edit `CHANGELOG.md` |
| Project instructions | `README.md`, `CONTRIBUTING.md`, `docs/*.md` | The test command (`Tests:` line), base branch (`Base:`), model map (`Models:`), a `Definition of Done` checklist, the docs a task's `Ref:` points to | `/todo-init` adds the `Tests:` line on your yes; any command may add `Base:` on your yes; `/todo-continue` updates README and `docs/` references a task's interface change made stale |
| Plans | `docs/plans/PROJECT.md`, `docs/plans/<ROOT-ID>-<slug>.md` | Goal, scope, lanes, decisions, revisions | `/todo-init --plan`, `/todo-plan`, `/todo-add` for a long request, `/todo-update --status drop` (a Revisions line), each on your yes |
| Traceability (optional) | `docs/RTM.md`, else a `## RTM` section in README | Which requirement a task implements | Only when it exists: `/todo-plan` and `/todo-add` on your yes, `/todo-continue` fills Verification |
| Status page | `docs/status.html` | | `/todo-report` |
| Checks (optional) | `.todo/check.sh`, `.todo/todo-lint.sh`, `.todo/todo-replay.sh`, `.github/workflows/todo-check.yml`, a job in `.gitlab-ci.yml`, `.git/hooks/pre-push` | The lint before each command, the check before a root lands | `/todo-init --ci`, each on your yes (you copy `todo-lint.sh` yourself) |
| Code | The task's source and test files | Only what the task needs | `/todo-continue`, within the task line |
| Detection only | `package.json`, `pom.xml`, `pyproject.toml`, `go.mod`, `Makefile`, CI config and other marker files | Runtime, package manager and test command | Never |
| Git | Branches `todo/<ID>-<slug>`, worktrees in `../<repo>.todo/`, commits | Claims, interrupted work | `/todo-continue`, `/todo-update`, `/todo-release` (never tags, fetches, pulls or pushes) |

The complete map, with which files are committed when and what is never touched, is in [docs/FILES.md](docs/FILES.md).

## Install

- **Claude Code skills:** copy `plugin/skills/*` to `~/.claude/skills/` (all projects) or `.claude/skills/` (one project), as above. A running session may pick up a project-level install without a restart, depending on the client version.
- **Claude Code plugin:** `/plugin marketplace add bassemZohdy/todo-skills`, then `/plugin install todo-skills@todo-skills`. Commands are namespaced, for example `/todo-skills:todo-add`.
- **Codex plugin:** `codex plugin marketplace add bassemZohdy/todo-skills`, then `codex plugin add todo-skills@todo-skills`. Verified on codex-cli 0.167.0: the marketplace is read from `.agents/plugins/marketplace.json` and all nine skills install from `plugin/.codex-plugin/plugin.json`.
- **Codex without the plugin:** copy `plugin/skills/*` to `<project>/.agents/skills/` (or `.codex/skills/`). Codex does not read `.claude/skills`. Start a skill with `$todo-status` or in plain language; a literal `/todo-status` is not handled by `codex exec`.
- **Any agent via the skills CLI:** `npx skills add bassemZohdy/todo-skills` lists and installs the nine skills for the agents it supports. `--skill <name>` installs one, but install all nine together: the command skills load the `todo` core skill.
- **Other agents** (Cursor and so on): the skills are plain Markdown. Copy `plugin/skills/` where your agent reads skills, or point its `AGENTS.md` at `plugin/skills/todo/SKILL.md`. Only git and bash are needed. Agents with recorded trials: Claude Code ([evidence](docs/evals/claude-code-2026-11-07/summary.md)) and Codex ([Windows](docs/evals/codex-windows-2026-11-08/summary.md), [Linux](docs/evals/codex-linux-2026-11-08/summary.md), [lanes](docs/evals/lanes-codex-2026-11-08/summary.md)); no other agent has been run. Their limits are in [agent compatibility](docs/agent-compatibility.md).

Skills load when their description matches, so add this to `AGENTS.md` or `CLAUDE.md` for reliable use:

```markdown
## Backlog
Work is tracked in TODO.md and CHANGELOG.md with the todo-* skills (/todo-init, /todo-plan, /todo-add, /todo-continue, /todo-update, /todo-status, /todo-report, /todo-release). Read the `todo` skill before editing TODO.md. Do not change TODO.md outside these commands.
```

## How it works

Every node of the tree goes through the same steps: ready check → branch (the first node of a tree publishes a claim on the base branch) → start `[/]` → red, green, refactor → **review** → verify (`Done when` + regression against the baseline) → complete `[x]` → merge into the parent's branch. A finished root is refreshed from the base, checked once more, drained into `CHANGELOG.md` as one entry, and merged into the base only with `--merge`. The marker on each task is its status, and every command acts only as that status allows.

| Page | Covers |
|---|---|
| [docs/LIFECYCLE.md](docs/LIFECYCLE.md) | Status diagram, the steps, the command-by-status matrix, SDLC practices |
| [docs/REFERENCE.md](docs/REFERENCE.md) | `TODO.md` and `CHANGELOG.md` formats, IDs, complexity and sizes, invariants and warnings, versioning, design rules |
| [docs/GIT-FLOW.md](docs/GIT-FLOW.md) | Branches, tree claims, worktrees, commit messages, merges, conflicts, no-git mode |
| [docs/VERIFICATION.md](docs/VERIFICATION.md) | Baseline, writing a `Done when`, review, failures and blocking, Definition of Done, command safety, documentation drift |
| [docs/PLANNING.md](docs/PLANNING.md) | Plan docs, re-planning, design review, lanes and parallel agents |

## Optional tools and CI

The plugin ships Markdown only. Read-only helper scripts live in [`tools/`](tools/) of this repository, and you copy the ones you want into your project: `todo-lint.sh` checks the backlog rules (I1-I10) and warns about weak test commands, `todo-verify.sh` rejects zero-test, masked or missing-target verification runs, `todo-rtm.sh` checks the optional requirements matrix, `todo-replay.sh` re-runs the `Validated:` commands of newly drained entries (refusing any the lint does not accept), `todo-report.sh` fills the status page deterministically, and `todo-stop-hook.sh` is a Claude Code Stop hook that runs the lint. They need only bash, awk, grep, sed and tr.

`/todo-init --ci` writes `.todo/check.sh` (the lint, once you have copied `tools/todo-lint.sh` to `.todo/todo-lint.sh`, plus your test command) and a CI job that runs it, or a git `pre-push` hook when the project has no CI. `/todo-continue` runs the same check as the last gate before a root lands. Usage, exit codes and the CI choices are in [docs/TOOLS.md](docs/TOOLS.md).

Git keeps LF line endings for shell scripts in new checkouts, Windows included. If an older checkout or an already-copied script has CRLF endings, refresh it from a clean checkout or convert it to LF before running it on Linux.

Tests: `bash tests/run.sh`

## Security and disclosure

The plugin sends no data and has no network access, MCP server or shipped hook. It runs local `git` and your own test commands (the optional scripts are not part of the plugin). It reads project docs and the files the current task needs, and writes only the files listed [above](#what-the-skills-read-and-write). It never reads credentials. Details: [SECURITY.md](SECURITY.md).

## Status

Version 0.5.0 is early. Fresh Claude Code and Codex agents have run scratch-project trials; a Linux Codex batch passed eight scenarios, and an existing-project trial first completed only after a backlog-commit workaround. After the fix for its cause (a new root left uncommitted by `/todo-add`, [FIX-035](docs/evals/fix-035.md)), the same feature on the same project passed on the first attempt with no commit between the sessions ([TASK-043](docs/evals/eval-skills-2026-11-08/summary.md)). The Linux results are provisional: a boundary audit with dummy sentinels passed its probes ([details](docs/evals/linux-boundary-2026-11-08.md)) but does not prove full isolation. On native Windows the trial assertions now run in the elevated Codex sandbox by default and fail closed; its dummy-sentinel probes passed on this host and on hosted Windows runners, with the same limits as the Linux profile ([FIX-041](docs/evals/fix-041.md)); a rerun of the Windows Codex batch with that verifier scored 2 PASS, 0 FAIL and 6 INFRA_ERROR, as the agent's own Windows sandbox still blocks the `.git` writes the lifecycle needs ([TASK-045](docs/evals/codex-windows-2026-11-08/summary.md)). The multi-module Codex lanes first ran sequentially; the harness now reports concurrency only from independent worker-activity evidence, and a later run with one fresh Codex process per lane recorded them working at the same time and passed ([TASK-044](docs/evals/lanes-codex-2026-11-08/summary.md)). See [the evidence](docs/evals/codex-linux-2026-11-08/summary.md). Team use remains unverified. "Done" is enforced by the agent following the rules, by the optional lint, and, with `/todo-init --ci`, by `.todo/check.sh` in CI or a pre-push hook; none of that is a sandbox, so read a task before you let an agent run its command. [docs/COMPARISON.md](docs/COMPARISON.md) records historical scores under two weightings and their caveats.

Known limits: planning is shallow (a short plan doc and the tree), the 120-line cap holds about 30 tasks (big trees are decomposed lazily), sharing claims between clones is left to git, and the review step is a self-review when no subagent tool exists.

## Documentation

| Page | What it covers |
|---|---|
| [Getting started](docs/GETTING-STARTED.md) | A ten-minute walkthrough on a scratch project |
| [Commands](docs/COMMANDS.md) | Every command and flag: what it does, when it stops, what it writes and commits |
| [Files](docs/FILES.md) | Every file the skills read or write, by command, and when each is committed |
| [Reference](docs/REFERENCE.md) | Task and CHANGELOG formats, IDs, invariants, warnings, versioning, design rules |
| [Lifecycle](docs/LIFECYCLE.md) | Status diagram, steps, command-by-status matrix, SDLC practices |
| [Git flow](docs/GIT-FLOW.md) | Branches, claims, worktrees, commits, merges, conflicts, no-git mode |
| [Verification](docs/VERIFICATION.md) | How "done" is decided and what blocks a task |
| [Planning and lanes](docs/PLANNING.md) | Plan docs, re-planning, design review, parallel lanes |
| [Tools and CI](docs/TOOLS.md) | The optional scripts, the Stop hook, `/todo-init --ci` |
| [Development](docs/DEVELOPMENT.md) | Repository layout, packaging rules, tests and CI of this repository |
| [Agent compatibility](docs/agent-compatibility.md) | What was observed on Claude Code and Codex, and what was not |
| [Trials](docs/trials.md) and [harness README](tests/trials/README.md) | The scenarios, how to run and score them, recorded results |
| [Evaluations](docs/evals/) | Retained evidence: [Claude Code](docs/evals/claude-code-2026-11-07/summary.md), [Codex on Windows](docs/evals/codex-2026-11-07/summary.md) ([rerun with the isolated verifier](docs/evals/codex-windows-2026-11-08/summary.md)), [Codex on Linux](docs/evals/codex-linux-2026-11-08/summary.md); the [agent benchmark](docs/evals/benchmark/README.md) harness (no real runs yet) |
| [Distribution](docs/distribution.md) | Install channels and the plugin-directory submission |
| [Comparison](docs/COMPARISON.md) | Similar tools, scored under two weightings, with caveats |

## Contributing and support

Trial reports are the most useful contribution: run it on a project and open an issue. See [CONTRIBUTING.md](CONTRIBUTING.md), [SECURITY.md](SECURITY.md) and the [code of conduct](CODE_OF_CONDUCT.md). Versions follow [Semantic Versioning](https://semver.org/) (policy in [docs/REFERENCE.md](docs/REFERENCE.md#versioning)); see [CHANGELOG.md](CHANGELOG.md). This repository tracks its own work with the same skills, in its own `TODO.md` and `CHANGELOG.md`.

## License

[MIT](LICENSE)
