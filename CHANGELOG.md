# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `todo` core skill (rules, task format, invariants, guardrails) and the command skills `todo-init`, `todo-add`, `todo-continue`, `todo-update`, `todo-status` and `todo-release`, with `reference/git-flow.md` and `reference/verification.md` loaded only when a command needs them.
- Task tree in `TODO.md`: dotted IDs (`FEAT-002.1`), sizes S/M/L/XL, at most 3 levels, 2-4 line tasks with `Done when` (criteria plus an exact command, optional `regression:`), `Links`, `State` and `Blocked`. A parent closes when its children are done and drains as one CHANGELOG entry ending in `Includes:`.
- Lifecycle by status: ready check, branch first, tree claim published to the base branch, claim `[/]`, red-green-refactor, verify, complete in the branch, `--no-ff` merge into the parent, refresh from the base, drain, and a root merge only with `--merge`. Interrupted work is recovered first. See `docs/LIFECYCLE.md`.
- Tree claims: the first claim in a tree is a claim-only commit fast-forwarded onto the base branch, naming the owning branch, so no other agent starts the same tree. A lost race aborts cleanly; a stale claim is released with `/todo-update <ROOT-ID> --status ready`; `/todo-status` shows claimed trees.
- Verification protocol with a recorded baseline, regression against it, and a gate script `scripts/todo-gate.sh` that runs Done when and regression, refuses forbidden commands, fails on zero-test runs and on counts below the baseline (unittest, pytest, jest, mocha, cargo and maven output recognised).
- `scripts/todo-lint.sh`: invariants I1-I10 plus warnings W1 (presence-only check), W2 (name-filtered tests) and W3 (unfamiliar runner; `TODO_LINT_STRICT=1` makes it a failure). `scripts/todo-stop-hook.sh` is an optional Claude Code Stop hook.
- `/todo-release`: proposes a semantic version from the `[Unreleased]` entries and, after confirmation, writes the dated section and links. It prints the tag and push commands without running them.
- `/todo-add --parent`, `--from` and `--clarify`; `/todo-update --status revert`; `/todo-continue --plan`, `--isolated`, `--worktree` and `--merge`; migration of the old three-section format in `/todo-init`.
- No-git mode: every command warns once and works without branches, worktrees or commits.
- `.claude-plugin/plugin.json` and `marketplace.json`; `claude plugin validate` passes and a local install copies every skill with its references and scripts. Commands are namespaced when installed as a plugin.
- `tests/run.sh` (fixtures for every invariant and warning, the gate script, the hook) and `tests/trials/` (scenarios built with plain git and checked by `assert.sh`): interrupted merge, refresh from base, claimed elsewhere, racing claims, release, monorepo.
- `docs/COMPARISON.md`, scored by an independent reviewer from primary sources, and `docs/LIFECYCLE.md` with the SDLC practices applied.
