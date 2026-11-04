---
name: todo-status
description: Read-only view of the TODO.md task tree. Use for /todo-status [--search <text>] [--last <N>]. Shows the tree with markers and complexity, children done/total per root, the active node, the next workable node, blocked nodes with their reasons, and recently drained work from CHANGELOG.md. Searches TODO.md and CHANGELOG.md. Never changes any file.
argument-hint: [--search <text>] [--last <N>]
---

# /todo-status

First load the `todo` core skill (tree format, IDs, invariants). If it is not available as a skill, read `../todo/SKILL.md`.

This command changes nothing: no edits, no bootstrapping, no git writes. If `TODO.md` does not exist, say so and suggest `/todo-init`. In a non-git folder print the core's no-git warning. An invariant violation is reported, never repaired.

## Default report

1. Run the invariant check and give the result in one line.
2. **Tree**: in git mode read claims from the base branch (`git show <base>:TODO.md`, core "Which node is next"), so a tree branch also shows other trees as claimed. Group roots by lane (core "Lanes", `main` when none) and show each root with marker, complexity, title, `children done/total` (parents only), its priority and, when claimed, `claimed by <branch>` with that branch's last commit date (marked stale if the branch no longer exists in this clone); children indented beneath it as `marker ID complexity title`. Collapse fully `[x]` subtrees to the count.
3. **Active** ("none" without a `[/]` node): the `[/]` node and its ancestors (shown as in progress), its `State:` line, and in git mode whether `git status` shows changes and which branch is checked out. In no-git mode show its `State:` and `files:` only.
4. **Next**: if a `[/]` node exists, `/todo-continue` resumes it: show "resume <ID>". Otherwise show the first workable `[ ]` node (ID, title, Done when command). If none, say what blocks the tree.
5. **Blocked**: each `[!]` node with its `Blocked:` reason and action required.
6. **Recently drained**: the newest `--last <N>` entries of CHANGELOG.md (default 5): `## [Unreleased]` first, then the latest version section when `[Unreleased]` has fewer.

## Search

`--search <text>`: print only the search result, not the default report. Case-insensitive search of TODO.md and CHANGELOG.md. Return matching task lines and changelog entries with their IDs. No match is an acceptable answer. Do not search the rest of the repository.

Keep the output short. Do not add suggestions beyond pointing to the command that would act on what you found.
