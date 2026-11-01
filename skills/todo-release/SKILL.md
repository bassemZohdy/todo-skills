---
name: todo-release
description: Prepare a release from CHANGELOG.md. Use for /todo-release [--version X.Y.Z]. Proposes the next semantic version from the Conventional Commit types in [Unreleased], asks for confirmation, then turns [Unreleased] into a dated version section with a fresh empty [Unreleased], and prints the tag and push commands. Never tags, pushes or edits version files.
argument-hint: [--version X.Y.Z]
---

# /todo-release

First load the `todo` core skill (invariants, guardrails). If it is not available as a skill, read `../todo/SKILL.md`. Releasing is a human decision: this command only acts after the user confirms the version in this conversation.

## Steps

1. **Preconditions.** Check git (core, "Git mode"; no-git mode works, minus the commit). Require the base branch checked out and a clean tree (git mode). Run the invariant check. Refuse when `[Unreleased]` has no entries. Warn, but do not refuse, when `TODO.md` has a `[/]` task or a claimed tree, because that work is not in this release.
2. **Previous version.** The newest `## [X.Y.Z]` heading in CHANGELOG.md, or none for a first release.
3. **Propose the version** from the entries under `[Unreleased]`:
   - any entry marked breaking (`BREAKING CHANGE`, or a `!` after the type) → major (while the version is `0.x`, minor);
   - else any `### Added` / `feat` entry → minor;
   - else (`### Fixed`, `### Changed`, others) → patch.
   With `--version`, use it, and check that it is greater than the previous version. State the reason for the proposal in one line and ask the user to confirm or give another version. Do nothing until they answer.
4. **Write the section.** After confirmation: rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` (today's date from `date +%F`) and insert a new empty `## [Unreleased]` above it. If the file ends with Keep a Changelog link references (`[Unreleased]: …compare/…`), update them to the new version and add the `[X.Y.Z]` link the same way. Do not touch older sections.
5. **Version files.** Do not edit them. List files that mention the previous version (`grep -rn "<previous>" --include=package.json --include=pyproject.toml --include=Cargo.toml --include=pom.xml .`) so the user can bump them.
6. **Commit** (git mode): `chore(release): X.Y.Z`, CHANGELOG.md only, explicit path. Run the lint script first.
7. **Report** the new section's headings and print, without running them, `git tag -a vX.Y.Z -m "X.Y.Z"` and `git push` / `git push --tags`.

Never tag, push, fetch or pull. Never rewrite a released section.
