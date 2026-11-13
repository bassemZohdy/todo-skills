---
name: todo-release
description: Prepare a release from CHANGELOG.md. Use for /todo-release [--version X.Y.Z]. Proposes the next semantic version from the entries in [Unreleased], asks for confirmation, then turns [Unreleased] into a dated version section with a fresh empty [Unreleased], and prints the tag and push commands. Never tags, pushes or edits version files.
disable-model-invocation: true
argument-hint: "[--version X.Y.Z]"
---

# /todo-release

First load the `todo` core skill (invariants, guardrails). If you cannot load a skill by name, read `../todo/SKILL.md`. Releasing is a human decision: act only after the user confirms the version in this conversation.

1. **Preconditions.** Check git and run the invariant check (core). In git mode the base branch (core "Git mode") must be checked out, and `git status --porcelain` may list nothing but backlog files (core) and untracked files; otherwise refuse and list the other paths. Refuse when `[Unreleased]` has no `- ` entries. Warn, but continue, when `TODO.md` or `git show <base>:TODO.md` has a `[/]` task or a claimed tree: that work is not in this release.
2. **Propose the version.** The previous version is the newest `## [X.Y.Z]` heading (none for a first release). Read every entry under `[Unreleased]`: `BREAKING CHANGE` anywhere in an entry, a type followed by an exclamation mark inside its parentheses (written by hand, as in (feat!) at the start of an entry), or any `### Removed` entry → major (minor while the previous version is `0.x`); else any `### Added` entry or `(feat)` type → minor; else (Changed, Fixed, Deprecated, Security) patch. For a first release propose `0.1.0` (the user may name `1.0.0`). `--version` replaces the proposal (a leading `v` is dropped) but still needs the confirmation. The new version must be `X.Y.Z` digits only, greater than the previous one, and have no local `vX.Y.Z` tag (`git tag --list`); the previous one, which goes into commands below, must also be digits only. Give the reason in one line and ask the user to confirm or name another. Do nothing until they answer; a decline ends the command.
3. **Write the section.** Rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` (`date +%F`) and put a new, empty `## [Unreleased]` (no subheadings) above it, with a blank line between. If the file ends with link references, take the base URL from the existing `[Unreleased]:` line (the part before `/compare/`; without such a line, add no links and say so), point `[Unreleased]` at `<base URL>/compare/vX.Y.Z...HEAD` and add `[X.Y.Z]: <base URL>/compare/v<previous>...vX.Y.Z` under it (`<base URL>/releases/tag/vX.Y.Z` for a first release). Without link references add none. Do not touch older sections.
4. **Version files.** Do not edit them. With a previous version, list files that mention it (`grep -rnF "<previous>" --exclude-dir=.git --exclude-dir=node_modules --include=package.json --include=pyproject.toml --include=Cargo.toml --include=pom.xml .`; exit 1 means none) so the user can bump them, or say "none found"; for a first release skip this and say so.
5. **Commit** (git mode): run the invariant check again (it reads CHANGELOG.md for I5 and I7); if it fails, stop and report, leaving the edit uncommitted. Otherwise commit `CHANGELOG.md` only (`git commit -- CHANGELOG.md`), as `chore(release): X.Y.Z`, without a body. No git: skip the commit.
6. **Report** the new version heading and its `###` headings, and print, without running them, `git tag -a vX.Y.Z -m "X.Y.Z"` and `git push --follow-tags` (git mode only).

Never rewrite a released section (core guardrails 4-5).
