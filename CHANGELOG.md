# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Tree claim: the first claim in a tree is published to the base branch by a claim-only commit and a fast-forward, naming the owning branch, so no other agent starts the same tree. The skills never touch the network, so sharing claims is left to git. `/todo-update <ROOT-ID> --status ready` releases a stale claim; `/todo-status` shows claimed trees.
- `docs/LIFECYCLE.md`: status model, step table, command-by-status matrix and the SDLC practices applied (short-lived branches, Definition of Ready and Done, red-green-refactor, regression, CI parity, revert path).
- Lint rejects backticks that hold code or prose instead of a shell command (I3), and warns on presence-only checks (W1) and name-filtered tests (W2).
- "Writing a Done when" guidance, and `n/a (manual)` for manual blocks.
- Task tree: dotted child IDs (`FEAT-002.1`), sizes S/M/L/XL, at most 3 levels, one `## 🌳 Task Tree` section in TODO.md.
- Compact 2-4 line tasks with `Done when` (criteria plus exact command, optional `regression:`), `Links`, `State` and `Blocked`.
- Verification protocol: tests first, full `Done when`, regression run against a green baseline.
- Git flow: branch per node, `--no-ff` merge into the parent, `--worktree`, and `--merge` for the base branch.
- No-git mode: every command warns once and works without branches, worktrees or commits.
- `/todo-add --parent <ID>`, `/todo-update --status revert`, and migration of the old three-section format in `/todo-init`.
- Lint invariants I8 (tree integrity), I9 (dependency cycles) and I10 (forbidden commands in `Done when`).
- Fixtures for I1-I10, and a test that this repository's own backlog lints clean.
- `todo-status`: read-only status, recent history and search.
- `scripts/todo-lint.sh` in the `todo` skill: deterministic check of invariants I1-I7.
- `scripts/todo-stop-hook.sh`: optional Claude Code Stop hook that blocks a session end on an invalid backlog.
- `tests/run.sh` with static fixtures covering every invariant and the hook.
- `From:` provenance and `Progress:` checkpoint fields; invariant I7 for dangling `Depends:` / `From:` references.
- Optional project-wide Definition of Done, read from a `Definition of Done` heading.
- `/todo-continue --plan` (approval checkpoint) and `--isolated` (fresh-context subagent, main thread re-verifies).
- `/todo-add --from <ID>` and `--clarify`, and up to 3 clarifying questions when the request is unclear.
- `docs/COMPARISON.md`: scored comparison with two weighting profiles.
- `todo` core skill and the `todo-init`, `todo-add`, `todo-continue` and `todo-update` command skills.
- README with install steps, task format and known limits.

### Changed

- Claims are read from the base branch (`git show <base>:TODO.md`), so a tree branch also sees other trees as claimed. Releasing a live claim needs an explicit yes, a clean tree and a base-branch release commit.
- `todo-add` checks that the requested behavior does not already exist, and `todo-continue` stops and asks when new tests already pass instead of adding tests that pass at once.
- Ancestor `State:` is defined (branch only, written in the first leaf's claim commit); an unchanged re-claim skips the commit; slugs are limited to letters, digits and hyphens; `todo-status` shows "resume" for an active node; the report names the checked-out branch.
- The no-git `State:` rolls child `files:` and `docs:` up to the root, and a missing-symbol error counts as a valid red.
- Branch first: `todo-continue` creates the branch chain (ancestors top-down), then sets `[/]` and commits the claim on the new branch. `/todo-update --status in-progress` does the same.
- Backlog and generated files do not make the tree dirty. Commits stage explicit paths only; the base branch is never committed on. Merged child branches are deleted with `git branch -d`.
- Completion order is fixed: set `[x]`, lint, commit, merge into the parent.
- Build is red, green, refactor. Parents run a verify-only or cross-child integration step; a root's integration and drain happen in one run.
- `Includes:` is omitted on a leaf root. `Docs:` is derived from the branch diff, or from `docs:` entries in the root's `State:` without git.
- `State:` gains `hyp:`; an attempt is a failed run after implementation started. No-git self-review re-reads the files listed in `State:`.
- `todo-init` falls back to the README, Makefile or CI config for the test command and reports the CI test command.
- A parent closes only when all children are `[x]`; a finished root drains as one CHANGELOG entry ending in `Includes:`.
- TODO.md has one section instead of In Progress, Ready and Blocked; the marker carries the state. The old `Scope`, `Validation` and `Progress` fields are now the task sentence, `Done when` and `State`.
- Lint now accepts only the tree format.
- `todo-continue` creates a local `todo/<ID>-<slug>` branch when started on `main`, `master` or `trunk`, so the drain can commit instead of leaving changes uncommitted.
- `todo-continue` persists the fix-attempt counter in `Progress:`, so the 3-attempt cap survives a context reset.
- Test failures now require a stated hypothesis and a minimal change per cycle (root cause before retry).
- Renumbering a colliding ID rewrites every `Depends:` and `From:` reference and names the old and new ID in the commit.
- Self-review gate in `todo-continue`: every changed hunk must trace to the task's Scope before the drain.
- Invariant I1 now also ties each marker to its section; I3 rejects vacuous Validation commands.
- The "no tool dependencies" guardrail now reads "no required tooling"; the lint script and hook are optional and read-only.

### Removed

- The `Out of Scope` and `Notes` fields. Boundaries go in the task sentence or a linked doc.
