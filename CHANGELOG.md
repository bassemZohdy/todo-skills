# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed

- Wording fixes from a full trial re-run (all 11 scenarios pass; `ci-local` once more where the environment refused writes under `.git/hooks`): lost-claim flow ends on the base; interrupted-work check only on a tree branch; `--revise` re-points `Depends:` on dropped IDs and does not commit; the hook lines are printed when `.git/hooks` cannot be written; the core names the allowed shell commands and the optional `.todo/` checks.
- Node commits record the review step: `Reviewed: <subagent|self>, <n> findings fixed` in the body.
- This repository now uses its own `/todo-init --ci` setup (`.todo/check.sh`, `todo-check` workflow) and tracked FIX-003 with the skills end to end. `ci.md` says the user commits the CI files before the next `/todo-continue`; a Definition of Done needs a heading named exactly so, followed by a list.

### Fixed

- Make the lint portable to macOS awk, recognize virtualenv and local tool runners, and warn for unknown local scripts. Document verification for non-code deliverables and infrastructure-dependent suites; run tests on macOS and Linux.

- **FIX-003** (fix): Make todo-report.sh exit 1 with a stderr message starting "todo-report:" when TODO.md is missing in the current directory. Validated: `bash tests/run.sh`.

## [0.2.0] - 2026-11-02

### Added

- CI integration with a local fallback: `/todo-init --ci` writes `.todo/check.sh` (backlog lint + tests) and a vendored lint, adds a GitHub Actions workflow (or a GitLab job on a yes, or prints the step for other CI), and without CI offers a `pre-push` hook. `/todo-continue` runs `.todo/check.sh` as the last gate before a root lands. Trial scenarios `ci-github` and `ci-local`.
- `/todo-plan`: turns a goal into a plan doc (`docs/plans/PROJECT.md`) and a proposed tree with lanes; `--revise` re-plans at any time, changes only open `[ ]` nodes, shows the diff, keeps IDs and logs the revision in the plan doc.
- `/todo-init --plan`: up to 3 pre-planning questions and an optional plan doc.
- Lanes: `Lane: <name>` on a root (default `main`) puts its tree in a track for one agent context. `/todo-continue --lane <name>` works one lane; `--all-lanes [--seq]` runs one subagent per lane in its own worktree while the main thread claims, re-verifies and merges. The lint accepts `Lane:` on roots only.
- `/todo-report`: writes `docs/status.html`, a self-contained interactive page (KPIs, lanes, filterable task tree with Done when, links, state and blockers, release history, claims, test command, plan).
- Review step between build and verify, done by a fresh-context reviewer when a subagent tool exists.
- Trial scenarios `lanes` and `replan`.

### Changed

- Lane agents hand off a root as `[/]` with `next: drain`; the review step is a self-review without a subagent tool. `--all-lanes` was run with two lane subagents in parallel.
- Lane rules moved from `/todo-continue` to `reference/lanes.md`, loaded only with a lane flag (smaller context for normal runs).
- Review pass: `Ref:` is optional everywhere (the ready check only checks a given path); `--plan` approval uses `next: plan proposed` instead of an off-grammar State item; a node's commit always includes `TODO.md`; lane agents skip the base switch and tree claim; a broken test command stops like a red baseline; root merge message defined; guardrail 6 no longer contradicts `/todo-release`.
- Resume treats changes that fit the task line as the node's own work; a missing baseline means the regression must be fully green. Lane coordinator keeps the main checkout on the base and removes worktrees before deleting branches. Refresh merge message defined; `--plan` commit named.
- The regression command comes first from a README `Tests:` line, which `/todo-init` offers to add.
- `/todo-add --lane <name>`; `/todo-plan` omits `Lane: main`.
- `/todo-report` ships an optional `todo-report.sh` (bash + sed) that fills the template with encoded text. `tests/run.sh` checks skill names, command listings and the report encoding.
- `/todo-report` encodes `&` and `<` in the embedded text and the page sets a Content-Security-Policy, so hostile `TODO.md`/`CHANGELOG.md` text cannot run script; CRLF input and odd lane names render correctly.
- The forced `git branch -D` of a lost claim runs only when the branch holds exactly the claim commit. `Blocked:` text is redacted of secrets. A red baseline now stops without writing anything.
- Lint I10 also rejects `eval`, `sh -c`/`bash -c`, `python -c` and `node -e`; the stop hook marks lint output as data and emits valid JSON for tabs and CR. `/todo-release` is manual-only.
- Plan drafts are written only after confirmation; `Lane:` can be edited with `/todo-update`; ID numbering also counts `docs/plans/`.
- Open-source files: LICENSE (MIT), CONTRIBUTING, SECURITY, CODE_OF_CONDUCT, issue and PR templates, CI workflow, `docs/GETTING-STARTED.md`, `docs/REFERENCE.md`, and a shorter README.
- A tree claim that fails only because the base moved is rebased once and fast-forwarded again; a base without `TODO.md` means no claim.
- Lane coordinator drains and merges each root; lane agents stop before the drain.
- `docs/COMPARISON.md` re-scored: 75 (solo/lean) and 71 (team/spec-first).

### Removed

- `/todo-continue --isolated`, replaced by lanes and the review step.

## [0.1.0] - 2026-11-01

### Added

- Semantic versioning policy in the README, and a test that `plugin.json` matches the newest changelog version.
- `todo` core skill (rules, task format, invariants, guardrails) and the command skills `todo-init`, `todo-add`, `todo-continue`, `todo-update`, `todo-status` and `todo-release`, with `reference/git-flow.md` and `reference/verification.md` loaded only when a command needs them.
- Task tree in `TODO.md`: dotted IDs (`FEAT-002.1`), sizes S/M/L/XL, at most 3 levels, 2-4 line tasks with `Done when` (criteria plus an exact command, optional `regression:`), `Links`, `State` and `Blocked`. A parent closes when its children are done and drains as one CHANGELOG entry ending in `Includes:`.
- Lifecycle by status: ready check, branch first, tree claim published to the base branch, claim `[/]`, red-green-refactor, verify, complete in the branch, `--no-ff` merge into the parent, refresh from the base, drain, and a root merge only with `--merge`. Interrupted work is recovered first. See `docs/LIFECYCLE.md`.
- Tree claims: the first claim in a tree is a claim-only commit fast-forwarded onto the base branch, naming the owning branch, so no other agent starts the same tree. A lost race aborts cleanly; a stale claim is released with `/todo-update <ROOT-ID> --status ready`; `/todo-status` shows claimed trees.
- Verification protocol with a recorded baseline, regression against it, with the rule that a run of zero tests does not count.
- `scripts/todo-lint.sh`: invariants I1-I10 plus warnings W1 (presence-only check), W2 (name-filtered tests) and W3 (unfamiliar runner). `scripts/todo-stop-hook.sh` is an optional Claude Code Stop hook.
- `/todo-release`: proposes a semantic version from the `[Unreleased]` entries and, after confirmation, writes the dated section and links. It prints the tag and push commands without running them.
- `/todo-add --parent`, `--from` and `--clarify`; `/todo-update --status revert`; `/todo-continue --plan`, `--isolated`, `--worktree` and `--merge`; migration of the old three-section format in `/todo-init`.
- No-git mode: every command warns once and works without branches, worktrees or commits.
- `.claude-plugin/plugin.json` and `marketplace.json`; `claude plugin validate` passes and a local install copies every skill with its references and scripts. Commands are namespaced when installed as a plugin.
- `tests/run.sh` (fixtures for every invariant and warning, the hook) and `tests/trials/` (scenarios built with plain git and checked by `assert.sh`): interrupted merge, refresh from base, claimed elsewhere, racing claims, release, monorepo.
- `docs/COMPARISON.md`, scored by an independent reviewer from primary sources, and `docs/LIFECYCLE.md` with the SDLC practices applied.

[Unreleased]: https://github.com/bassemZohdy/todo-skills/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/bassemZohdy/todo-skills/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bassemZohdy/todo-skills/releases/tag/v0.1.0
