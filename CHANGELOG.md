# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Fixed
- **FIX-036** (fix): Report lane concurrency only with independent worker activity evidence; Git worktree events alone are unverified. Ref: tests/trials/README.md. Validated: `bash tests/trials/test-lane-concurrency.sh`, `bash tests/trials/test-lane-evidence.sh`.
- **FIX-035** (fix): Claim newly added uncommitted roots without a separate backlog commit, preserving pending edits if another claim wins. Ref: docs/evals/fix-035.md. Validated: `bash tests/trials/test-pending-root.sh`.

### Added
- **TASK-028** (test): A fresh Linux Codex agent completed the Git lifecycle in an isolated scratch repository; the sandbox result is provisional pending an adversarial audit. Ref: docs/evals/codex-linux-2026-11-08/summary.md. Validated: `bash tests/trials/test-codex-evidence.sh`, `bash tests/trials/test-linux-codex-evidence.sh`.
- **TASK-029** (test): Eight Linux Codex scenarios, including the six previously blocked on Windows, have prompts, independent assertions, logs, Git state and checksums; all eight passed. Ref: docs/evals/codex-linux-2026-11-08/summary.md. Validated: `bash tests/trials/test-codex-evidence.sh`, `bash tests/trials/test-linux-codex-evidence.sh`.
- **TASK-030** (test): Separate Ubuntu and macOS CI runners verified the pinned source, prompts, session records, assertion logs and evidence hashes without running the tested agent. Ref: docs/evals/codex-linux-2026-11-08/ci-verification.md. Validated: `bash tests/run.sh`, `bash tests/trials/test-linux-codex-evidence.sh`.
- **TASK-031** (test): Clean Markdown-only Codex installations with and without optional local tools discovered all nine skills and passed the basic lifecycle assertions. Ref: docs/evals/codex-linux-2026-11-08/summary.md. Validated: `bash tests/run.sh`, `bash tests/trials/test-linux-codex-evidence.sh`.
- **TASK-032** (test): A fresh Codex agent implemented a scoped feature in a scratch clone of eval-skills, with independent regression and behavior checks after a backlog-commit workaround. Ref: docs/evals/codex-linux-2026-11-08/summary.md. Validated: `test -f docs/trials.md`, `bash tests/run.sh`, `bash tests/trials/test-linux-codex-evidence.sh`.
- **TASK-033** (docs): Reconcile current Codex and Claude trial support with historical comparison scores and documented limitations. Ref: docs/agent-compatibility.md. Validated: `bash tests/run.sh`.
- **TASK-034** (docs): Record the evidence-based decisions for issues 11 and 5 without adding persisted progress state. Ref: docs/REFERENCE.md. Validated: `bash tests/run.sh`.
- **TASK-018** (test): `run-codex.sh` and `codex-exec.sh` run a fresh Codex process whose writes are confined to the scratch repo (temp-folder exemptions off, trials kept outside the temp folder); `test-codex-isolation.sh` checks that scratch edits and commits work and that overwriting a controller file, creating or overwriting evidence files and writing beside the repo are denied. Reads cannot be denied on the unelevated Windows sandbox and Git branch or worktree creation there is unreliable; both are recorded, not hidden. Validated: `bash tests/trials/test-codex-isolation.sh`.
- **TASK-019** (test): Eight lifecycle scenarios run with fresh Codex sessions and recorded in `docs/evals/codex-2026-11-07/` with the controller's assertions, exit codes, Git state, session ids and checksums. Result: 2 PASS, 6 INFRA_ERROR (the sandbox blocked branch creation, Node child processes or `.git/hooks`), 0 FAIL; `infra-signature.sh` keeps such blocks from being counted as failures or passes. Validated: `bash tests/trials/test-codex-evidence.sh`.
- **TASK-024** (test): Codex skill discovery and invocation recorded: skills in `.agents/skills` or `.codex/skills` are found, `.claude/skills` is not, `$todo-status` and plain language run the skill, and a literal `/todo-status` has no Codex handler in `codex exec` (a model may still map it). Validated: `bash tests/trials/test-codex-invocation.sh`.
- **TASK-027** (docs): `reference/verification.md` says what to do when a Done when cannot run for an environmental reason: add one empty scaffolding file inside the node's own folders and report it, otherwise stop and report. Never edit Done when. Validated: `bash tests/run.sh`.
- **TASK-025** (fix): The `ts-lifecycle` and `java-lifecycle` trial prompts ask the agent to run `/todo-continue` again until the root is merged (it executes one node per invocation); `test-prompt-assert.sh` rejects a prompt that stops earlier than its assertion allows. Validated: `bash tests/trials/test-prompt-assert.sh`.
- **TASK-026** (fix): `tests/trials/setup.sh` reads and writes its files as UTF-8, so every scenario sets up on Windows without `PYTHONUTF8`. Validated: `bash tests/trials/selftest.sh`.
- **TASK-020** (test): The `baseline-red` trial passes only with an agent report that names the red baseline, the failing test and a FIX (`TRIAL_REPORT`); an unchanged repository alone no longer passes. Validated: `bash tests/trials/test-baseline-red-report.sh`.
- **TASK-021** (test): The `lanes` and `multi-module` trials log checkouts and commits per worktree by hook; `lane-evidence.sh` tells overlapping lanes from sequential ones and from no worktree use, and `assert.sh` requires two lane worktrees. Validated: `bash tests/trials/test-lane-evidence.sh`.
- **TASK-022** (test): `score.sh` gives every scenario one verdict (PASS, FAIL, INFRA_ERROR or UNVERIFIED) and counts all of them; a scenario without a recorded agent run, or whose agent exited non-zero, cannot pass. Validated: `bash tests/trials/test-score-outcomes.sh`.
- **TASK-023** (test): `run-claude.sh` writes a new checksummed evidence folder per invocation (prompt, command, log, exit code, report, assertions, outcome); earlier runs are never overwritten. Validated: `bash tests/trials/test-evidence-retention.sh`.
- **TASK-015** (docs): Record Claude Code and Codex lifecycle evidence in docs/agent-compatibility.md; Codex stays install-verified only. Validated: `test -f docs/agent-compatibility.md`, `bash tests/run.sh`.
- **TASK-013** (docs): Run lifecycle trials on TypeScript, Java and multi-module scratch projects and record them in docs/trials.md. Validated: `test -f docs/trials.md`, `bash tests/run.sh`.

- **TASK-012** (feat): Opt-in `todo-verify.sh --strict` also rejects output with no recognizable passing count, unchecked pipes, `set +e` and `|| echo`; default mode is unchanged. Validated: `bash tests/run.sh`.
- **TASK-014** (test): RTM check R3 (duplicate requirement rows) and fixtures for docs precedence, README fallback, missing RTM, duplicates and archived tasks. Validated: `bash tests/run.sh`.
- **TASK-016** (docs): `/todo-plan` documents an optional independent design review (fresh-context reviewer or an external tool such as EGM) for high-risk roots, never a required stage. Validated: `bash tests/run.sh`.
- Trial scenarios `ts-lifecycle`, `java-lifecycle` and `multi-module` (Node, Maven, Maven multi-module), `tests/trials/run-claude.sh`, `docs/trials.md` and `docs/agent-compatibility.md`. No agent run is recorded yet.

### Changed

- Marketplace manifest gets a description; the I10 rule text in the core skill and the command-safety text in `verification.md` describe the forbidden commands in words instead of literal shell patterns (the lint still enforces the same set), to keep directory scans from reading rules as instructions.
- **TASK-017** (docs): `docs/COMPARISON.md` separates source-backed features, estimates and end-to-end trials for the changes after 0.3.0; other tools' scores and alternatives were not re-read. Validated: `bash tests/run.sh`.

## [0.3.1] - 2026-11-07

### Added

- Listing icon (a square PNG in the plugin manifest folder) and a disclosure of what the plugin runs, reads, writes and sends (README, SECURITY.md) for the directory submission.

### Changed

- The plugin now lives in `plugin/` and ships Markdown only, as the directory accepts no scripts or HTML from unverified organizations: the optional scripts and the report generator moved to `tools/` (copy them into a project by hand), the report template is embedded in `plugin/skills/todo-report/template.md`, and `.todo/todo-lint.sh` is no longer written by `/todo-init --ci`. Both marketplaces point at `./plugin`; the install path for copied skills is `plugin/skills/*`.
- **TASK-007** (chore): Submit to the Anthropic plugin directory and record it. Ref: docs/distribution.md. Validated: `test -f docs/distribution.md`.

## [0.3.0] - 2026-11-07

### Added

- **FEAT-008** (feat): Add optional Markdown RTM traceability with docs/RTM.md preferred and README.md `## RTM` fallback; plan, add, update and continue link and record requirements only when an RTM exists. Ref: skills/todo/reference/rtm.md. Validated: `bash tests/run.sh`. Docs: updated README.md, docs/REFERENCE.md. Includes: FEAT-008.1, FEAT-008.2, FEAT-008.3, FEAT-008.4.
- **TASK-004** Codex plugin support: `.codex-plugin/plugin.json` and `.agents/plugins/marketplace.json`, version-checked against the Claude manifest in `tests/run.sh`. **TASK-005** Install and skill discovery verified on codex-cli 0.167.0; README states what was tested. **TASK-006** `npx skills add bassemZohdy/todo-skills` documented and verified to list all nine skills; `docs/distribution.md` records the channels.
- Complexity level per task (`low`, `mid`, `high`, required) so agents can pick a model; optional README `Models:` mapping, `/todo-continue --delegate`, lane and reviewer routing, and escalation one tier per failed attempt. Sizes (`S`/`M`/`L`/`XL`) become optional after the complexity; `/todo-init` migrates the earlier format.

### Changed

- **TASK-011** (docs): Documentation-drift check reports `<file>:<line>: <name>` references for changed interfaces only and never blocks unrelated nodes. Validated: `bash tests/run.sh`. **TASK-010** (test): Fixtures for interrupted resume, blocked verification and missing optional CI files. Validated: `bash tests/run.sh`. **TASK-009** (fix): Verification rejects zero-test runs, missing test targets and masked failures (`todo-verify.sh`, lint I3 and W4) without changing the task schema. Validated: `bash tests/run.sh`.
- Wording fixes from a full trial re-run (all 11 scenarios pass; `ci-local` once more where the environment refused writes under `.git/hooks`): lost-claim flow ends on the base; interrupted-work check only on a tree branch; `--revise` re-points `Depends:` on dropped IDs and does not commit; the hook lines are printed when `.git/hooks` cannot be written; the core names the allowed shell commands and the optional `.todo/` checks.
- Node commits record the review step: `Reviewed: <subagent|self>, <n> findings fixed` in the body.
- This repository now uses its own `/todo-init --ci` setup (`.todo/check.sh`, `todo-check` workflow) and tracked FIX-003 with the skills end to end. `ci.md` says the user commits the CI files before the next `/todo-continue`; a Definition of Done needs a heading named exactly so, followed by a list.

### Fixed

- Quote `argument-hint` in `todo-init`, `todo-plan`, `todo-continue` and `todo-status`: the unquoted brackets were invalid YAML, so strict loaders such as the skills CLI skipped four of the nine skills. `tests/run.sh` now checks every frontmatter.
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

[Unreleased]: https://github.com/bassemZohdy/todo-skills/compare/v0.3.1...HEAD
[0.3.1]: https://github.com/bassemZohdy/todo-skills/compare/v0.3.0...v0.3.1
[0.3.0]: https://github.com/bassemZohdy/todo-skills/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bassemZohdy/todo-skills/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bassemZohdy/todo-skills/releases/tag/v0.1.0
