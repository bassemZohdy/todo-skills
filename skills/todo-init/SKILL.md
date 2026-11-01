---
name: todo-init
description: Bootstrap and report on the todo backlog workspace. Use for /todo-init [--plan] [--ci] or when the user wants to set up or check TODO.md and CHANGELOG.md. Scans README.md, docs/, TODO.md and CHANGELOG.md, creates the missing backlog files, detects git, runtime, package manager and test command, offers to migrate the old three-section format to the task tree, and reports the tree. Optionally asks pre-planning questions and sets up CI (or a local pre-push fallback) running the backlog lint and the tests. Idempotent.
argument-hint: [--plan] [--ci]
---

# /todo-init

First load the `todo` core skill (tree format, invariants, guardrails). If it is not available as a skill, read `../todo/SKILL.md`.

## Steps

1. Check git (`git rev-parse --is-inside-work-tree`). If this is not a repository, print the one-time warning from the core skill and say the skills will run in no-git mode. Do not run `git init` unless the user asks.
2. Look for `README.md`, `docs/`, `TODO.md`, `CHANGELOG.md`.
3. Bootstrap only what is missing:
   - Leave both new files uncommitted; the first claim commit carries them.
   - `TODO.md`:
     ```markdown
     # Active Backlog

     ## 🌳 Task Tree
     ```
   - `CHANGELOG.md`:
     ```markdown
     # Changelog

     All notable changes to this project will be documented in this file.

     The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
     and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

     ## [Unreleased]
     ```
   - If CHANGELOG.md exists without an Unreleased heading, add `## [Unreleased]` above the newest version section and change nothing else.
   - If TODO.md exists in the **old format** (sections `In Progress`, `Ready`, `Blocked`; fields Scope, Out of Scope, Validation, Progress), do not overwrite it. Report that and offer a migration. On the user's yes, convert each task to a root: Scope becomes the header sentence, Validation becomes `Done when:` (criteria plus the command), Ref/Depends/From become `Links:`, Progress becomes `State:`, the three blocker fields become one `Blocked:` line, `[/]`/`[ ]`/`[!]` markers are kept. Size each as S or M and ask when unsure. **Out of Scope has no place in the new format:** ask whether to move each one into a `docs/` note or drop it, and never drop it silently. Re-run lint afterwards.
   - If TODO.md has any other structure (for example a free-form list), do not overwrite it. Report the mismatch and offer to move it aside to `TODO.legacy.md` (on the user's yes).
   - Never create README.md or docs/. Report them as missing.
4. Detect runtime, package manager and test command by marker file (in a monorepo list one per package):

   | Marker | Test command |
   |---|---|
   | `pom.xml` | `mvn test` |
   | `build.gradle(.kts)` | `./gradlew test` |
   | `package.json` with `scripts.test` | `pnpm test` / `yarn test` / `bun test` / `npm test`, chosen by lockfile |
   | `Cargo.toml` | `cargo test` |
   | `pyproject.toml`, `pytest.ini`, `setup.cfg` | `uv run pytest` if `uv.lock` exists, else `pytest` |
   | `go.mod` | `go test ./...` |
   | `*.csproj` / `*.sln` | `dotnet test` |
   | `Gemfile` | `bundle exec rspec` or `bundle exec rake test` |
   | `Makefile` with a `test` target | `make test` |

   If no marker matches (for example plain `python3 -m unittest`), use the test command stated in README.md, CONTRIBUTING.md, the Makefile or the CI config, and name that source. If none is stated, report "unknown" and ask the user once; never invent one. Also report the test command CI runs (`.github/workflows`, `.gitlab-ci.yml`, `Jenkinsfile`), so the regression command can match it, and flag a mismatch. If README does not state the command after `Tests:` (on its own line or in a sentence), offer to add a `Tests:` line (`Tests: \`<command>\``) so every later run uses the same command; write it only on the user's yes.

   Do not run the suite. Apart from that optional `Tests:` line and `.todo/check.sh` (`--ci`), do not persist the detected command. It is reported, and reused as the default regression command and when `todo-add` proposes `Done when` lines.
5. In a git repo, report the base branch (`main`, `master`, `trunk` or `develop`) and whether the tree is clean.
6. Check for a heading named exactly `Definition of Done` followed by a checklist (list items) in README.md, CONTRIBUTING.md or `docs/`; a heading that only describes the feature does not count. Report where it is, or that none exists. Never create one.
7. Run the invariant check (the lint script when present). Report concisely: what was created, git or no-git mode, base branch, runtime / package manager / test command, doc files found, Definition of Done location, whether the lint script is installed, the tree summary (roots with `children done/total`, active node, blocked IDs) and any invariant violations.

8. **Pre-planning** (only when the tree is empty and the user gave a goal, or `/todo-init --plan` is used). Ask once, at most 3 short questions the repo does not answer: the goal and done-state, what is out of scope, and which parts could run as parallel lanes. Offer to save the answers as `docs/plans/PROJECT.md`; write it only on the user's yes. Then point to `/todo-plan` for the tree.
9. **CI** (only with `--ci`, or when the user asks for it). Read `reference/ci.md` from the core's folder (`../todo/reference/ci.md`) and follow it: `.todo/check.sh` (lint + tests), the CI job that fits the repository, or the local pre-push fallback. Every file only on the user's yes. Without `--ci`, mention it once in the report if `.todo/check.sh` does not exist.

Do not add, start or modify tasks. For a read-only view without bootstrapping, use `/todo-status`.
