---
name: todo-release
description: Prepare a release from CHANGELOG.md. Use for /todo-release [--version X.Y.Z]. Proposes the next semantic version from the entries in [Unreleased], asks for confirmation, then turns [Unreleased] into a dated version section with a fresh empty [Unreleased], and prints the tag and push commands. Never tags, pushes or edits version files.
disable-model-invocation: true
argument-hint: [--version X.Y.Z]
---

# /todo-release

First load the `todo` core skill (invariants, guardrails). If it is not available as a skill, read `../todo/SKILL.md`. Releasing is a human decision: act only after the user confirms the version in this conversation.

1. **Preconditions.** Run the invariant check. In git mode the base branch (core "Git mode": first of main, master, trunk, develop) must be checked out and the tree clean apart from `CHANGELOG.md` and `TODO.md`. Refuse when `[Unreleased]` has no `- ` entries. Warn, but continue, when `TODO.md` has a `[/]` task or a claimed tree: that work is not in this release.
2. **Propose the version.** The previous version is the newest `## [X.Y.Z]` heading (none for a first release). From the entries: a breaking entry (`BREAKING CHANGE`, or `!` after the type) or any `### Removed` → major (minor while the version is `0.x`); else any `### Added` / `feat` → minor; else patch. `--version` overrides the proposal (a leading `v` is dropped). The version, and the previous one when used in a command, must be `X.Y.Z` digits only, greater than the previous one and have no existing `vX.Y.Z` tag. Give the reason in one line and ask the user to confirm or name another. Do nothing until they answer; a decline ends the command.
3. **Write the section.** Rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` (`date +%F`) and put a new empty `## [Unreleased]` above it. If the file ends with link references, point `[Unreleased]` at `vX.Y.Z...HEAD` and add `[X.Y.Z]: <base URL>/compare/v<previous>...vX.Y.Z` under it (`releases/tag/vX.Y.Z` for a first release). Do not touch older sections.
4. **Version files.** Do not edit them. List files that mention the previous version (`grep -rnF "<previous>" --exclude-dir=.git --exclude-dir=node_modules --include=package.json --include=pyproject.toml --include=Cargo.toml --include=pom.xml .`) so the user can bump them; say "none found" otherwise.
5. **Commit** (git mode): run the lint script, then commit `CHANGELOG.md` only, as `chore(release): X.Y.Z`. If lint fails, stop without committing.
6. **Report** the section's headings and print, without running them, `git tag -a vX.Y.Z -m "X.Y.Z"` and `git push --follow-tags`.

Never tag, push, fetch or pull. Never rewrite a released section.
