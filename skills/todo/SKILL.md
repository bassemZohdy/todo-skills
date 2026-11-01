---
name: todo
description: Core rules for the todo-* skills (todo-init, todo-add, todo-continue, todo-update, todo-status, todo-release) - the task tree in TODO.md, compact task format, sizes, IDs, git flow with a no-git fallback, invariants, Definition of Done and hard guardrails. Load this before running any todo-* command or when editing TODO.md. Invoked directly as /todo it only prints the command list and a read-only invariant check.
---

# todo (core)

The repository is a closed-loop state machine built from files that already exist. Nothing else stores state.

| Layer | File(s) | Role | Write policy |
|---|---|---|---|
| Requirements | `README.md`, `docs/*.md` | Ground truth: contracts, specs, setup, long plans | Read-mostly. Edited only under "Documentation drift" in `todo-continue` |
| Active queue | `TODO.md` | One task tree. A tracker of work items, not a place for design | Edited only by the todo-* skills |
| Validation | Source code + test suites | Ground truth for "done" | Changed only for the task at hand |
| Archive | `CHANGELOG.md` | Permanent, append-only (Keep a Changelog + Conventional Commits) | Only `## [Unreleased]` is touched, only by a root drain |
| Version store | git | Branch or worktree per task. Nothing reaches the base branch unverified | See "Git mode" |

Use native file tools (Read/Edit/Write) for all Markdown edits. Use the shell only for `git`, Validation commands and the optional lint script.

## Direct use

`/todo` with no further command is read-only: list the commands below, run the invariant check on `TODO.md` if it exists, and report the result. Change nothing.

| Command | Skill | Purpose |
|---|---|---|
| `/todo-init` | `todo-init` | Bootstrap files, detect test runner and git, report status, migrate the old format |
| `/todo-add` | `todo-add` | Add a task, or break a request into a tree |
| `/todo-continue` | `todo-continue` | Execute the next task node, verify it, merge it into its parent |
| `/todo-update` | `todo-update` | Manual state and field changes |
| `/todo-status` | `todo-status` | Read-only tree, history and search |
| `/todo-release` | `todo-release` | Turn `[Unreleased]` into a version after the user confirms it |

Each skill runs only its own command and never chains into another unprompted.

## Git mode

At the start of every command run `git rev-parse --is-inside-work-tree`.

- **Git repo:** git is the version store. Each node of the tree works on its own branch or worktree (see `reference/git-flow.md`).
- **Not a git repo:** warn **once per command**, in one sentence: "This is not a git repository. The todo skills still work, but without branches, worktrees, commits or merges, so there is no isolation and no history. Run `git init` to enable them." Then continue in **no-git mode**: skip every git step, track progress in `State:`, record the files you touched in `State:` for the scope check, and still update markers and drain to CHANGELOG.md. Everything else is unchanged, including verification.

Never tag, force-push, reset hard or clean, in either mode. The one forced local deletion is `git branch -D` of your own unpublished claim branch after a lost race (`reference/git-flow.md`). **The skills never touch the network:** no fetch, pull or push. Sharing commits is git's job and yours.

## TODO.md schema

```markdown
# Active Backlog

## 🌳 Task Tree
```

Exactly this heading, then exactly one section. There are no In Progress, Ready or Blocked sections: the marker on each task carries that state.

### Task

A task is **2 to 4 lines**: what to do, how it is validated, and optional links and state.

```markdown
- [ ] **FEAT-002** · P1 · XL · Add token refresh to the auth service
  - Done when: old token rejected after refresh; `npm test -- auth`; regression: `npm test`
  - Links: Ref: docs/auth.md#refresh · Depends: TASK-001 · From: FIX-001
  - State: attempts 1/3; branch todo/FEAT-002-add-token-refresh-auth from main; next: add reuse test
  - [ ] **FEAT-002.1** · L · Refresh endpoint
    - Done when: endpoint covered by an integration test; `npm test -- auth/refresh`
    - [ ] **FEAT-002.1.1** · S · Token store interface
      - Done when: store round-trips a token; `npm test -- auth/store`
```

| Part | Rule |
|---|---|
| Header | `- [m] **ID** · [P0-P2, roots only ·] SIZE · what to do, one sentence` |
| `Done when:` | **Required.** The criteria, then at least one exact command in backticks. Optional `regression: \`cmd\``. Without it the regression command is the project's full suite |
| `Links:` | Optional. `Ref: <path#anchor>`, `Depends: <IDs>`, `From: <ID>`, separated by ` · ` |
| `State:` | Optional. `attempts n/3; [baseline <n> passing|none;] [hyp: <one line>;] branch todo/<ID>-<slug> [from <base>]; next: <step>`. Each item at most once, in this order; a later claim **replaces** the earlier State line, it never adds to it. Written by todo-continue. Survives a context reset. Items are separated by `; `: `attempts`, `baseline`, `hyp`, `branch`, `no git`, `files`, `docs`, `next`. In no-git mode a root also keeps `files: <paths>; docs: <paths>` rolled up from its completed children (a leaf root keeps its own), written right after its `Done when`/`Links`, until the drain |
| `Blocked:` | On `[!]` tasks, instead of State. `reason → \`command\` error (max 5 lines) → action required`. A manual block by the user has no failing command: write `n/a (manual)` in the middle part |

Layout: one blank line between `## 🌳 Task Tree` and the first task, no blank lines between tasks, and no placeholder text in an empty tree (the heading alone is valid). A drain removes the subtree and its lines only, leaving no extra blank line.

Only these four fields exist. A task never has both State and Blocked. Anything longer than 4 lines is design prose and belongs in `docs/` (link it with `Ref:`, for example `docs/plans/FEAT-002-refresh.md`). If a task needs a longer description, the task is too big: split it.

Markers: `[ ]` open, `[/]` active (at most one in the file), `[!]` blocked, `[x]` verified and merged into its parent, waiting for its root to drain.

### Tree, levels and sizes

- Indentation is the tree: a node at level L has its header indented `2L` spaces and its fields `2L+2`. Maximum 3 levels (indent 0, 2, 4).
- Whole tree in this one file. Planning depth is the number of levels; size is the classification.

| Size | Meaning | Where |
|---|---|---|
| `S` | One change, at most 2 files | Leaf |
| `M` | One context window of work, at most 5 files | Leaf |
| `L` | Has children, all leaves | Parent |
| `XL` | Has grandchildren | Parent |

A leaf is never `L` or `XL`; a parent is never `S` or `M`. Adding or dropping children recomputes the parent's size. Roots carry the priority; children inherit it.

## IDs

- Roots: `<PREFIX>-<NNN>`, one global sequence shared by all prefixes, zero-padded to 3 digits. Children append `.n` to the parent: `FEAT-002.1`, `FEAT-002.1.2`. The number of dots equals the level.
- Next root number = highest root number among FEAT-, FIX- and TASK- IDs found anywhere in `TODO.md` **and** `CHANGELOG.md` (including IDs after `Includes:`; other patterns such as `CVE-2023-1` or `GH-123` are ignored), plus 1. Next child number = highest existing child number under that parent, plus 1, never reused within the same tree.

| Prefix | Meaning | CHANGELOG heading | Commit type |
|---|---|---|---|
| `FEAT` | New capability | `### Added` | `feat` |
| `FIX` | Bug or regression | `### Fixed` | `fix` |
| `TASK` | Refactor, chore, docs, test, perf, build | `### Changed` | `refactor`, `chore`, `docs`, `test`, `perf` or `build`, whichever fits |

Children use their root's prefix.

## Which node is next

A node is **workable** when all hold: it is `[ ]`; every child is `[x]` (a leaf has none); every `Depends:` ID is satisfied; no ancestor is `[!]`; and, in git mode, its root is not claimed by another branch. A root is **claimed** when its `State:` in the base branch's `TODO.md` (`git show <base>:TODO.md`) names a branch; its tree is workable only from a branch of that family (`todo/<ROOT-ID>-…` or `todo/<ROOT-ID>.…`). Details in `reference/git-flow.md`. A `Depends:` ID is satisfied when it appears in CHANGELOG.md (as an entry ID or after `Includes:`) or is `[x]` in TODO.md.

**Interrupted work comes first (git mode).** Before selecting, scan the branches of the tree you are on (`git branch --list 'todo/<ROOT-ID>[-.]*'`). Skip the scan on the base branch: it has no current tree, and claimed trees are resumed by switching to their branch. For each branch that is not merged into its parent's branch (`git branch --no-merged <parent branch> --list 'todo/<ID>-*'`; the parent of `A.1.2` is `A.1`), read its node's marker with `git show <branch>:TODO.md`. `[x]` means the completion stopped before its merge: finish that merge (completion step 4) and nothing else. `[/]` means work is in progress there: switch to that branch and resume it, deepest first. Only when no branch of the tree has pending work does the order below apply.

Order: roots P0 → P1 → P2, then by ID. Within a root, depth-first in document order. A parent whose children are all `[x]` is workable: that is its **integration step**.

## Lifecycle by status

The marker is the status, and each command acts only as that status allows. The rules (the todo-skills repository also has a diagram and the SDLC mapping in `docs/LIFECYCLE.md`):

| Status | `/todo-continue` | `/todo-update` | `/todo-add --parent` |
|---|---|---|---|
| `[ ]` workable | branch, claim, build, verify, complete | `in-progress`, `blocked`, `drop`, edits | allowed |
| `[ ]` waiting | skip, say what it waits for | `blocked`, `drop`, edits (`in-progress` is refused) | allowed |
| `[ ]` in a tree claimed by another branch | skip, report the branch | `ready` on the root releases the claim | refused |
| `[/]` | resume from `State:` | `ready` (keeps the branch), `blocked`, edits; no `drop` | refused |
| `[!]` | skip, report `Blocked:` | `ready`, `drop`, edits | refused |
| `[x]` | never touches | `revert` only | refused |

Order for every node: **ready check → branch → (first node of a tree: tree claim, published to the base branch) → claim (`[/]`) → build → verify → complete (`[x]`) → merge into parent**. The branch always exists before the status changes. Ancestors keep `[ ]` while a descendant is active.

**Ready check.** Lint passes, the node is workable, its `Ref:` exists, its `Done when` holds a runnable command, the working tree is clean (git mode only; untracked files, backlog files and generated files do not count; skipped in no-git mode), and the regression baseline is green.

## CHANGELOG entry (written only by a root drain)

Inserted as the first `- ` item of the matching `###` list under `## [Unreleased]` (after the blank line that follows the heading, if any), newest first, with no blank line between entries. An existing `## Unreleased`, `## [unreleased]` or similar heading counts as the Unreleased section; never add a second one. Create the heading if missing, keeping the Keep a Changelog order (Added, Changed, Deprecated, Removed, Fixed, Security):

```markdown
- **FEAT-002** (feat): Add token refresh to the auth service. Ref: docs/auth.md#refresh. Validated: `npm test -- auth`. Includes: FEAT-002.1, FEAT-002.1.1, FEAT-002.2.
```

A root whose title starts with `BREAKING: ` is written with a `!` after the type (`(feat!)`) and the prefix removed from the text; its commit subject is `<type>(<scope>)!: <title>`. One entry per root, whatever the tree size. A hand-written changelog is left as it is: entries without an ID stay where they are and the new entry goes above them; `/todo-release` moves them with the rest of `[Unreleased]`. When the root has descendants, `Includes:` is last and lists every descendant ID, so Depends and the ID counter still see them. A leaf root has no `Includes:`. `Docs: updated docs/x.md.` goes before `Includes:` and lists README.md and `docs/` files changed by the whole tree: in git mode take them from `git diff --name-only <base>...<root branch>`, in no-git mode from the `docs:` items in the root's `State:`. If the root had `From:`, add `From: FIX-001.`

## Fallbacks

When git, a script, a subagent tool, a test command or the base branch is missing or refuses, the skills degrade instead of stopping; `docs/FALLBACKS.md` lists each case and what it costs.

## Reference files

Loaded only when a command needs them, from this skill's `reference/` folder (`../todo/reference/` from a command skill):

| File | Contents | Loaded by |
|---|---|---|
| `reference/git-flow.md` | Branch chain, tree claim, claim reading, staging, merging, refresh from base, git-conflict rules | `/todo-continue`, `/todo-update --status in-progress` and `--status ready` |
| `reference/verification.md` | Verification protocol, Writing a Done when, Definition of Done, command safety | `/todo-continue`, `/todo-add` |

## Invariants (every todo-* skill checks these first)

| # | Invariant |
|---|---|
| I1 | At most one `[/]` task, and a `[/]` parent has no open children |
| I2 | Every ID is unique in TODO.md |
| I3 | Each task has a non-vacuous `Done when` with a backticked command, at most 4 lines, only the four fields, no State together with Blocked, a Blocked line (reason → command error → action) on every `[!]`, a priority on roots only, a valid size and a non-empty title |
| I4 | TODO.md is at most 120 lines |
| I5 | No ID appears in both TODO.md and CHANGELOG.md (IDs after `Includes:` count) |
| I6 | The file is exactly `# Active Backlog` plus one `## … Task Tree` section, no other headings |
| I7 | Every ID in `Depends:` or `From:` exists in TODO.md or CHANGELOG.md |
| I8 | Tree integrity: child ID = parent ID + `.n`, dots equal level, depth at most 3, even indent with no jumps, no `[x]` root, no `[x]` node with open children, leaves are S or M, parents are L or XL to match their depth |
| I9 | No dependency cycles, counting the implicit "parent waits for its children" edges |
| I10 | No forbidden command in `Done when`: `sudo`, `rm -r`/`-f`, `curl`/`wget` piped into a shell, `git push`, `git reset --hard`, `git clean`, `chmod -R`, `mkfs`, `dd if=` |

**Gate script.** `scripts/todo-gate.sh <ID> [--regression cmd] [--baseline n]` runs a node's `Done when` and regression commands, fails on a non-zero exit, on a run that executed no tests and on a count below the baseline. `/todo-continue` uses it for the verify step; its result wins over your own reading.

**Lint script.** (`TODO_LINT_STRICT=1` makes the unfamiliar-runner warning W3 a failure, for teams that want an allowlist only.) If `scripts/todo-lint.sh` exists in this skill's folder (`../todo/scripts/todo-lint.sh` relative to a command skill), run `bash <that path>` from the repository root. It is read-only, needs only bash, awk and grep, and checks I1-I10 deterministically. Its result wins over your own reading. If the script is absent, check by reading the files.

Repair automatically only I5 (finish an interrupted drain by deleting the listed IDs from TODO.md). For any other violation, report it, change nothing, and ask the user how to proceed.

## Hard guardrails

1. No ghost tasks. Every change to TODO.md traces to an explicit user command or to a completed code transition.
2. No required tooling. No SQLite, JSON caches, hidden files, MCP servers or SaaS. Markdown plus git only; git itself is optional. The lint script and hook are optional, read-only conveniences.
3. No node is closed without running its Done when command and its regression run and seeing both pass.
4. At most one `[/]` task in a file. The base branch never holds one (`[/]` lives on tree branches), so a hotfix started from the base branch is allowed while another tree is in progress on its own branch.
5. CHANGELOG.md is append-only apart from the `[Unreleased]` insertions made by a root drain and the confirmed `/todo-release`. Never rewrite released sections.
6. Never tag, cut a release, fetch, pull or push. Moving `[Unreleased]` to a version happens only through `/todo-release`, after the user confirms the version.
7. The base branch receives only tree claims (fast-forward), the claim release commit of `/todo-update --status ready`, the confirmed release commit of `/todo-release` and the merge of a verified root. Nothing else reaches it before its root is verified.
8. When a rule here conflicts with a user's explicit instruction, state the conflict and ask. Do not silently break the rule.
