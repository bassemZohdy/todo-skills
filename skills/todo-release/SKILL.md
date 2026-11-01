---
name: todo-release
description: Prepare a release from CHANGELOG.md. Use for /todo-release [--version X.Y.Z]. Proposes the next semantic version from the Conventional Commit types in [Unreleased], asks for confirmation, then turns [Unreleased] into a dated version section with a fresh empty [Unreleased], and prints the tag and push commands. Never tags, pushes or edits version files.
argument-hint: [--version X.Y.Z]
---

# /todo-release

First load the `todo` core skill (invariants, guardrails). If it is not available as a skill, read `../todo/SKILL.md`. Releasing is a human decision: this command only acts after the user confirms the version in this conversation.

## Steps

1. **Preconditions.** Check git (core, "Git mode"; no-git mode works, minus the commit). Require the base branch (`reference/git-flow.md`: the branch the root branches start from; usually `main`) to be checked out and a clean tree (git mode); otherwise stop and say which branch to switch to. Run the invariant check; on failure report and change nothing. Refuse when `[Unreleased]` has no `- ` entries (empty `###` headings count as none). Warn, but do not refuse, when `TODO.md` has a `[/]` task or, from `git show <base>:TODO.md`, a claimed tree, because that work is not in this release.
2. **Previous version.** The newest `## [X.Y.Z]` heading in CHANGELOG.md, or none for a first release.
3. **Propose the version** from the entries under `[Unreleased]`:
   - any entry marked breaking (`BREAKING CHANGE` or a `!` after the type, in the entry text) or any `### Removed` entry → major (while the version is `0.x`: minor);
   - else any `### Added`, `### Deprecated` or `feat` entry → minor;
   - else (`### Fixed`, `### Changed`, `### Security`) → patch.
   Moving from `0.x` to `1.0.0` is proposed only when the user asks for it.
   With `--version`, strip a leading `v` and use it. Whichever version is used (proposed, given with the flag, or named in the answer) must match `X.Y.Z`, be greater than the previous version, and have no existing `vX.Y.Z` tag (`git tag --list`); otherwise say which check failed and ask again. State the reason for the proposal in one line and ask the user to confirm or give another version. Do nothing until they answer; a decline or no answer ends the command with no change. A `--version` still needs the confirmation.
4. **Write the section.** After confirmation: rename `## [Unreleased]` to `## [X.Y.Z] - YYYY-MM-DD` (today's date from `date +%F`, the machine's local date) and insert a new `## [Unreleased]` heading above it with no `###` subheadings, one blank line on each side. If the file ends with Keep a Changelog link references (`[Unreleased]: …compare/…`), point `[Unreleased]` at `vX.Y.Z...HEAD` and add `[X.Y.Z]: <same base URL>/compare/v<previous>...vX.Y.Z` directly below it (newest first); for a first release use `<base URL>/releases/tag/vX.Y.Z`. Leave the older links as they are. Do not touch older sections.
5. **Version files.** Do not edit them. List files that mention the previous version (`grep -rnF "<previous>" --include=package.json --include=package-lock.json --include=pyproject.toml --include=setup.py --include=setup.cfg --include=Cargo.toml --include=pom.xml --include=version.txt --include=__init__.py .`) so the user can bump them. Say "none found" when nothing matches, and note that matches may be dependency versions.
6. **Commit** (git mode): `chore(release): X.Y.Z`, CHANGELOG.md only, explicit path. Run the lint script after the edit and before the commit; if it fails, restore nothing silently: report it and stop without committing.
7. **Report** the `###` headings and the number of entries in the new section, and print, without running them, `git tag -a vX.Y.Z -m "X.Y.Z"` (it tags the release commit) and then `git push --follow-tags` (or `git push` and `git push --tags` separately).

Never tag, push, fetch or pull. Never rewrite a released section.
