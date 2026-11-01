---
name: todo
description: Core rules for the todo-* skills (todo-init, todo-plan, todo-add, todo-continue, todo-update, todo-status, todo-report, todo-release) - the task tree in TODO.md, compact task format, sizes, IDs, git flow with a no-git fallback, invariants, Definition of Done and hard guardrails. Load this before running any todo-* command or when editing a TODO.md in the `# Active Backlog` task-tree format. Invoked directly as /todo it only prints the command list and a read-only invariant check.
---

# todo (core)

The repository is a closed-loop state machine built from files that already exist. Nothing else stores state.

| Layer | File(s) | Role | Write policy |
|---|---|---|---|
| Requirements | `README.md`, `docs/*.md` | Ground truth: contracts, specs, setup, long plans | Read-mostly. Edited under "Documentation drift" in `todo-continue`; plan docs (`docs/plans/`) by `todo-init`/`todo-plan`/`todo-add`; `docs/status.html` by `todo-report` |
| Active queue | `TODO.md` | One task tree. A tracker of work items, not a place for design | Edited only by the todo-* skills |
| Validation | Source code + test suites | Ground truth for "done" | Changed only for the task at hand |
| Archive | `CHANGELOG.md` | Permanent, append-only (Keep a Changelog + Conventional Commits) | Only `## [Unreleased]` (and, on release, the link lines at the end) is touched, by a root drain and the confirmed `/todo-release`; `todo-init` creates the file |
| Checks (optional) | `.todo/check.sh`, `.todo/todo-lint.sh`, CI job | Lint + tests, run by CI, a pre-push hook and `/todo-continue` | Written by `/todo-init --ci` on a yes; committed by the user |
| Version store | git | Branch or worktree per task. Nothing reaches the base branch unverified | See "Git mode" |

Use native file tools (Read/Edit/Write) for Markdown edits. Use the shell only for `git`, test and `Done when` commands, the optional scripts, and the few file commands a skill names (`cp`, `chmod`, `date`, `grep`).

## Direct use

`/todo` alone is read-only: list the commands, run the invariant check on `TODO.md` if it exists, report. Change nothing.

| Command | Purpose |
|---|---|
| `/todo-init` | Bootstrap files, detect test command and git, optional pre-planning and CI setup, migrate the old format |
| `/todo-plan` | Plan the work into lanes and a tree; revise the plan at any time |
| `/todo-add` | Add a task, or break a request into a tree |
| `/todo-continue` | Execute the next task node, verify it, merge it into its parent |
| `/todo-update` | Manual state and field changes |
| `/todo-status` | Read-only tree, lanes, history and search |
| `/todo-report` | Write an interactive HTML status page to `docs/status.html` |
| `/todo-release` | Turn `[Unreleased]` into a version after the user confirms it |

Each skill runs only its own command and never chains into another unprompted.

## Git mode

At the start of every command run `git rev-parse --is-inside-work-tree`.

- **Git repo:** each node works on its own branch or worktree (`reference/git-flow.md`).
- **Not a git repo:** warn **once per command**: "This is not a git repository. The todo skills still work, but without branches, worktrees, commits or merges, so there is no isolation and no history. Run `git init` to enable them." Then use **no-git mode**: skip every git step, track progress in `State:` (including `files:` touched), still update markers and drain to CHANGELOG.md. Verification is unchanged.

Never tag, force-push, reset hard or clean. The one forced branch delete is a lost tree claim (`reference/git-flow.md`). **The skills never touch the network:** no fetch, pull or push. Sharing commits is git's job and yours.

## TODO.md schema

```markdown
# Active Backlog

## 🌳 Task Tree
```

Exactly this heading and one section. No In Progress, Ready or Blocked sections: the marker on each task is its state. An empty tree is just the heading.

A task is **2 to 4 lines**: what to do, how it is validated, optional links and state.

```markdown
- [ ] **FEAT-002** · P1 · XL · Add token refresh to the auth service
  - Done when: old token rejected after refresh; `npm test -- auth`; regression: `npm test`
  - Links: Ref: docs/auth.md#refresh · Depends: TASK-001 · From: FIX-001
  - State: attempts 1/3; baseline 42 passing; branch todo/FEAT-002-add-token-refresh-auth from main; next: add reuse test
  - [ ] **FEAT-002.1** · L · Refresh endpoint
    - Done when: endpoint covered by an integration test; `npm test -- auth/refresh`
    - [ ] **FEAT-002.1.1** · S · Token store interface
      - Done when: store round-trips a token; `npm test -- auth/store`
```

| Part | Rule |
|---|---|
| Header | `- [m] **ID** · [P0-P2, roots only ·] SIZE · what to do, one sentence` |
| `Done when:` | **Required.** Criteria, then at least one exact command in backticks. Optional `regression: \`cmd\``; without it the regression is the project's full suite |
| `Links:` | Optional. `Ref: <path#anchor>`, `Depends: <IDs>`, `From: <ID>`, `Lane: <name>` (roots only), separated by ` · ` |
| `State:` | Optional, written by todo-continue, survives a context reset. Items separated by `; `, each at most once, in this order: `attempts n/3`, `baseline <n> passing` (or `none`), `hyp: <one line>`, `branch todo/<ID>-<slug> [from <base>]`, `no git`, `files: <paths>`, `docs: <paths>`, `next: <step>`. A later claim **replaces** the whole line. In no-git mode a root keeps `files:` and `docs:` rolled up from its finished children until the drain |
| `Blocked:` | On `[!]` tasks, instead of State: `reason → command in backticks, error (at most 5 lines joined with " / ") → action required`. A manual block writes `n/a (manual)` in the middle |

Only these four fields exist; a task never has both State and Blocked. More than 4 lines is design prose and belongs in `docs/` (link it with `Ref:`). If a task needs more, split it.

Markers: `[ ]` open, `[/]` active (at most one in the file), `[!]` blocked, `[x]` verified and merged into its parent, waiting for its root to drain.

### Tree, levels and sizes

A node at level L has its header indented `2L` spaces and its fields `2L+2`. Maximum 3 levels.

| Size | Meaning | Where |
|---|---|---|
| `S` | One change, at most 2 files | Leaf |
| `M` | One context window, at most 5 files | Leaf |
| `L` | Has children, all leaves | Parent |
| `XL` | Has grandchildren | Parent |

A leaf is never `L`/`XL`; a parent never `S`/`M`; adding or dropping children recomputes the parent's size. Roots carry the priority; children inherit it.

## IDs

- Roots `<PREFIX>-<NNN>`, one global sequence, 3 digits. Children append `.n`: `FEAT-002.1`, `FEAT-002.1.2`. Dots equal the level.
- Next root number = highest FEAT-/FIX-/TASK- number found in `TODO.md`, `CHANGELOG.md` (including IDs after `Includes:`) **and** `docs/plans/*.md`, plus 1. Next child number = highest existing child under that parent plus 1.

| Prefix | Meaning | CHANGELOG heading | Commit type |
|---|---|---|---|
| `FEAT` | New capability | `### Added` | `feat` |
| `FIX` | Bug or regression | `### Fixed` | `fix` |
| `TASK` | Refactor, chore, docs, test, perf, build | `### Changed` | whichever fits |

Children use their root's prefix.

## Which node is next

A node is **workable** when: it is `[ ]`; every child is `[x]`; every `Depends:` ID is satisfied (in CHANGELOG.md as an entry ID or after `Includes:`, or `[x]` in TODO.md); no ancestor is `[!]`; and, in git mode, its root is not claimed by another branch. A root is **claimed** when its `State:` in the base branch's `TODO.md` (`git show <base>:TODO.md`) names a branch; its tree is workable only from a branch of that family (`reference/git-flow.md`).

**Interrupted work comes first (git mode).** On a tree branch, check that tree's unmerged branches (`git branch --no-merged <parent branch, or the base for a root> --list 'todo/<ID>-*' 'todo/<ID>.*'`). A node that is `[x]` there stopped before its merge: finish the merge, lint, run the parent's regression, and do nothing else (`/todo-continue` step 2). A node that is `[/]` is resumed, deepest first. Skip this on the base branch.

### Lanes

A lane is a named track of root trees that one agent context works alone, in order. `Lane: <name>` (lowercase, digits, dashes) on a root puts its whole tree in that lane; children inherit it and a root without it is in lane `main`. Lanes are context, not tasks: a lane may hold one task or many, lanes run in parallel with each other (`/todo-continue --all-lanes`) and roots inside a lane run in sequence. Cross-lane order is only expressed with `Depends:`. Lane names are listed in the plan doc `docs/plans/PROJECT.md` when one exists.

Order: roots P0 → P1 → P2, then by ID (with `--lane` only that lane's roots); within a root, depth-first in document order. A parent whose children are all `[x]` is workable: that is its **integration step**.

## Lifecycle by status

The marker is the status, and each command acts only as that status allows (diagram and SDLC mapping in `docs/LIFECYCLE.md`).

| Status | `/todo-continue` | `/todo-update` | `/todo-add --parent` |
|---|---|---|---|
| `[ ]` workable | branch, claim, build, review, verify, complete | `in-progress`, `blocked`, `drop`, edits | allowed |
| `[ ]` waiting | skip, say what it waits for | `blocked`, `drop`, edits | allowed |
| `[ ]` in a tree claimed by another branch | skip, report the branch | `ready` on the root releases the claim | refused |
| `[/]` | resume from `State:` | `ready`, `blocked`, edits; no `drop` | refused |
| `[!]` | skip, report `Blocked:` | `ready`, `drop`, edits | refused |
| `[x]` | never touches | `revert` only | refused |

Order for every node: **ready check → branch → (first node of a tree: tree claim published to the base) → claim `[/]` → build → review → verify → complete `[x]` → merge into parent**. The branch exists before the status changes. Ancestors stay `[ ]` while a descendant is active.

**Ready check.** Lint passes, the node is workable, its `Ref:` (if any) exists, its `Done when` has a runnable command, the tree is clean (git mode), and the regression baseline is green.

## CHANGELOG entry (written only by a root drain)

Inserted as the first `- ` item of the matching `###` list under `## [Unreleased]`, newest first, no blank line between entries. Create the heading if missing, in Keep a Changelog order (Added, Changed, Deprecated, Removed, Fixed, Security):

```markdown
- **FEAT-002** (feat): Add token refresh to the auth service. Ref: docs/auth.md#refresh. Validated: `npm test -- auth`. Includes: FEAT-002.1, FEAT-002.1.1.
```

One entry per root. With descendants, `Includes:` is last and lists every descendant ID; a leaf root has none. `Docs: updated docs/x.md.` (before `Includes:`) lists README/`docs/` files the tree changed: from `git diff --name-only <base>...<root branch>`, or the `docs:` items in no-git mode. If the root had `From:`, add `From: FIX-001.`

## Reference files

Loaded only when a command needs them, from `reference/` (`../todo/reference/` from a command skill):

| File | Contents | Loaded by |
|---|---|---|
| `reference/git-flow.md` | Branches, tree claim, staging, merging, refresh from base, conflicts | `/todo-continue`, `/todo-update --status in-progress` or `ready` |
| `reference/verification.md` | Verification protocol, writing a Done when, Definition of Done, command safety | `/todo-continue`, `/todo-add` |
| `reference/lanes.md` | Lane runs: coordinator, lane agents, merging lanes | `/todo-continue --lane` or `--all-lanes` |
| `reference/ci.md` | `.todo/check.sh` (lint + tests), CI job per provider, local pre-push fallback | `/todo-init --ci` |

## Invariants (every todo-* skill checks these first)

| # | Invariant |
|---|---|
| I1 | At most one `[/]` task, and a `[/]` parent has no open children |
| I2 | Every ID is unique in TODO.md |
| I3 | Each task has a non-vacuous `Done when` with a backticked command, at most 4 lines, only the four fields, no State together with Blocked, a Blocked line on every `[!]`, a priority on roots only, a valid size and a title |
| I4 | TODO.md is at most 120 lines |
| I5 | No ID appears in both TODO.md and CHANGELOG.md (IDs after `Includes:` count) |
| I6 | The file is exactly `# Active Backlog` plus one `## … Task Tree` section |
| I7 | Every ID in `Depends:` or `From:` exists in TODO.md or CHANGELOG.md |
| I8 | Tree integrity: child ID = parent ID + `.n`, depth at most 3, even indent, no `[x]` root, no `[x]` node with open children, leaves S or M, parents L or XL |
| I9 | No dependency cycles, counting "parent waits for its children" |
| I10 | No forbidden command in `Done when`: `sudo`, `rm -r`/`-f`, download piped into a shell, `git push`, `git reset --hard`, `git clean`, `chmod -R`, `mkfs`, `dd if=`, `eval`, `sh -c`/`bash -c`, `python -c`, `node -e`, `find -delete`, publish or upload commands (`npm`/`yarn`/`pnpm publish`, `cargo publish`, `twine`, `gem push`), `git -C … push`, `.ssh`/`.aws` credentials |

**Lint script.** If `scripts/todo-lint.sh` exists in this skill's folder (`../todo/scripts/` from a command skill), run `bash <path>` from the repository root. It is read-only, needs bash, awk, grep, sed and tr, checks I1-I10 and prints non-failing `WARN` lines for weak `Done when` commands. Its failures win over your own reading; a pass does not replace judging a command's safety (`reference/verification.md`). Without the script, check by reading.

Repair automatically only I5 (finish an interrupted drain by deleting the listed IDs from TODO.md). For any other violation, report it, change nothing, and ask.

## Hard guardrails

1. No ghost tasks. Every change to TODO.md traces to a user command or a completed code transition.
2. No required tooling. Markdown plus git only; git itself is optional. The lint script and hook are optional and read-only.
3. No node is closed without running its `Done when` and its regression and seeing both pass.
4. At most one `[/]` task in a file. (`[/]` lives on tree branches, so a hotfix started from the base can run while another tree is in progress.)
5. CHANGELOG.md is append-only apart from `[Unreleased]` insertions by a root drain and the confirmed `/todo-release`. Never rewrite released sections.
6. Never tag, fetch, pull or push. `[Unreleased]` becomes a version only through `/todo-release`, after the user confirms.
7. The base branch receives only tree claims (fast-forward), claim releases, the confirmed release commit and the merge of a verified root.
8. When a rule here conflicts with an explicit user instruction, state the conflict and ask.
