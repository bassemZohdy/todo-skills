---
name: todo
description: Core rules for the todo-* skills (todo-init, todo-add, todo-continue, todo-update) - file schemas, ID scheme, invariants, git-conflict rules and hard guardrails for a TODO.md / CHANGELOG.md backlog. Load this before running any todo-* command or when editing TODO.md. Invoked directly as /todo it only prints the command list and a read-only invariant check.
---

# todo (core)

The repository is a closed-loop state machine built from files that already exist. Nothing else stores state.

| Layer | File(s) | Role | Write policy |
|---|---|---|---|
| Requirements | `README.md`, `docs/*.md` | Ground truth: contracts, specs, setup | Read-mostly. Edited only under "Documentation drift" in `todo-continue` |
| Active queue | `TODO.md` | Ephemeral, atomic work items, max ~120 lines | Edited only by the four todo-* skills |
| Validation | Source code + test suites | Ground truth for "done" | Changed only inside a task's Scope |
| Archive | `CHANGELOG.md` | Permanent, append-only (Keep a Changelog + Conventional Commits) | Only `## [Unreleased]` is touched, only by the drain in `todo-continue` |

Use native file tools (Read/Edit/Write) for all Markdown edits. Use the shell only for `git` and Validation commands.

## Direct use

`/todo` with no further command is read-only: list the four commands below, run the invariant check on `TODO.md` if it exists, and report the result. Change nothing.

The skills: `todo-init` (bootstrap and status), `todo-add` (create a task), `todo-continue` (execute one task and drain it), `todo-update` (manual state changes). Each skill runs only its own command and never chains into another unprompted.

## TODO.md schema

Headings must match exactly, in this order:

```markdown
# Active Backlog

## 🏗️ In Progress (Max 1)

## 📋 Ready (Prioritized Queue)

## ⛔ Blocked
```

### Task block

```markdown
- [ ] **FEAT-002** · P1 · Short imperative title
  - Scope: Single-context boundary, 1-2 sentences.
  - Out of Scope: Explicit negative boundaries.
  - Ref: docs/architecture.md#auth   (or `none`)
  - Depends: TASK-001                (optional line; omit if none)
  - Validation: `npm test -- auth`
  - Notes: free text                 (optional line)
```

Markers: `[ ]` ready, `[/]` in progress, `[!]` blocked. A blocked task adds three fields:

```markdown
  - Blocker Reason: ...
  - Command/Error: `cmd` → last relevant error lines (max 5)
  - Action Required: what a human must do or decide
```

A task block is at most ~8 lines. Design prose belongs in `docs/`, never in TODO.md. Link to it with `Ref`.

## IDs

- Format `<PREFIX>-<NNN>`, one global sequence shared by all prefixes, zero-padded to 3 digits.
- Next number = highest number found anywhere in `TODO.md` **and** `CHANGELOG.md`, plus 1. Searching only TODO.md would reuse IDs after a drain.

| Prefix | Meaning | CHANGELOG heading | Commit type |
|---|---|---|---|
| `FEAT` | New capability | `### Added` | `feat` |
| `FIX` | Bug or regression | `### Fixed` | `fix` |
| `TASK` | Refactor, chore, docs, test, perf, build | `### Changed` | `refactor`, `chore`, `docs`, `test`, `perf` or `build`, whichever fits |

## CHANGELOG entry (written only by the drain)

Inserted at the top of the matching `###` list under `## [Unreleased]`. Create the heading if missing, keeping the Keep a Changelog order (Added, Changed, Deprecated, Removed, Fixed, Security):

```markdown
- **FEAT-002** (feat): Short imperative title. <Scope condensed to one line>. Ref: docs/architecture.md#auth. Validated: `npm test -- auth`.
```

If the task changed a doc, append `Docs: updated docs/x.md.`

## Invariants (every todo-* skill checks these first)

| # | Invariant |
|---|---|
| I1 | At most one `[/]` item, and only under In Progress |
| I2 | Every ID is unique within TODO.md |
| I3 | Every task has Scope, Out of Scope, Ref, Validation |
| I4 | TODO.md is ≤ 120 lines |
| I5 | No ID appears in both TODO.md and CHANGELOG.md |
| I6 | The three section headings are present and exact |

Repair automatically only I5 (finish the interrupted drain by removing the task from TODO.md). For any other violation, report it, change nothing, and ask the user how to proceed.

## Git conflicts

- Never resolve by choosing a side wholesale and never use `--ours`/`--theirs` on TODO.md or CHANGELOG.md.
- **CHANGELOG.md**: keep both sides' entries, the union, in `[Unreleased]`. Drop duplicates of the same ID.
- **TODO.md**: keep the union of task blocks. If two blocks share an ID, keep the one already in the base branch and renumber the newer one with the next free number. If that yields two `[/]` items, keep the one whose files are in the working tree and move the other to Ready. If an ID is now in both files, remove it from TODO.md (I5).
- **Source files** in conflict: if inside the active task's Scope, resolve minimally and re-run Validation. Otherwise stop and ask. Never `git reset --hard`, `git checkout .`, `git clean` or force-push.
- Mutual exclusion is per branch or worktree. Two agents on one working tree is unsupported. Use one worktree per agent.

## Hard guardrails

1. No ghost tasks. Every change to TODO.md traces to an explicit user command or to a completed code transition.
2. No tool dependencies. No SQLite, JSON caches, hidden files, MCP servers or SaaS. Markdown plus git only.
3. No task is closed without running its Validation command and seeing it pass.
4. Exactly one active task at any time.
5. CHANGELOG.md is append-only apart from the `[Unreleased]` insertions made by the drain. Never rewrite released sections.
6. Never push, tag, or cut a release. Moving `[Unreleased]` to a version is a human decision.
7. When a rule here conflicts with a user's explicit instruction, state the conflict and ask. Do not silently break the rule.
