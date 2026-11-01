---
name: todo-init
description: Bootstrap and report on the todo backlog workspace. Use for /todo-init or when the user wants to set up or check TODO.md and CHANGELOG.md. Scans README.md, docs/, TODO.md and CHANGELOG.md, creates the missing backlog files, detects runtime, package manager and test command, and reports pending items. Idempotent, so it also serves as the status view.
---

# /todo-init

First load the `todo` core skill (schemas, invariants, guardrails). If it is not available as a skill, read `../todo/SKILL.md`.

## Steps

1. Look for `README.md`, `docs/`, `TODO.md`, `CHANGELOG.md`.
2. Bootstrap only what is missing:
   - `TODO.md` with the core schema and three empty sections.
   - `CHANGELOG.md`:
     ```markdown
     # Changelog

     All notable changes to this project will be documented in this file.

     The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
     and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

     ## [Unreleased]
     ```
   - If CHANGELOG.md exists without `## [Unreleased]`, add that heading and change nothing else.
   - If TODO.md exists with a different structure, do not overwrite it. Report the mismatch and offer a migration.
   - Never create README.md or docs/. Report them as missing.
3. Detect runtime, package manager and test command by marker file (in a monorepo list one per package):

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

   Do not run the suite and do not persist the detected command anywhere. It is reported, and reused when `todo-add` proposes Validation lines.
4. Run the invariant check. Report concisely: what was created, runtime / package manager / test command, doc files found, counts for In Progress / Ready / Blocked with their IDs, and any invariant violations.

Do not add, start or modify tasks.
