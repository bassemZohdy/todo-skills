# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

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

- `todo-continue` creates a local `todo/<ID>-<slug>` branch when started on `main`, `master` or `trunk`, so the drain can commit instead of leaving changes uncommitted.
- `todo-continue` persists the fix-attempt counter in `Progress:`, so the 3-attempt cap survives a context reset.
- Test failures now require a stated hypothesis and a minimal change per cycle (root cause before retry).
- Renumbering a colliding ID rewrites every `Depends:` and `From:` reference and names the old and new ID in the commit.
- Self-review gate in `todo-continue`: every changed hunk must trace to the task's Scope before the drain.
- Invariant I1 now also ties each marker to its section; I3 rejects vacuous Validation commands.
- The "no tool dependencies" guardrail now reads "no required tooling"; the lint script and hook are optional and read-only.
