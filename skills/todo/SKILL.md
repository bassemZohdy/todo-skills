---
name: todo
description: Core rules for the todo-* skills (todo-init, todo-add, todo-continue, todo-update, todo-status) - the task tree in TODO.md, compact task format, sizes, IDs, git flow with a no-git fallback, invariants, Definition of Done and hard guardrails. Load this before running any todo-* command or when editing TODO.md. Invoked directly as /todo it only prints the command list and a read-only invariant check.
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

Each skill runs only its own command and never chains into another unprompted.

## Git mode

At the start of every command run `git rev-parse --is-inside-work-tree`.

- **Git repo:** git is the version store. Each node of the tree works on its own branch or worktree (see "Git flow").
- **Not a git repo:** warn **once per command**, in one sentence: "This is not a git repository. The todo skills still work, but without branches, worktrees, commits or merges, so there is no isolation and no history. Run `git init` to enable them." Then continue in **no-git mode**: skip every git step, track progress in `State:`, record the files you touched in `State:` for the scope check, and still update markers and drain to CHANGELOG.md. Everything else is unchanged, including verification.

Never tag, force, reset hard or clean, in either mode. **The skills never touch the network:** no fetch, pull or push. Sharing commits is git's job and yours.

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
  - State: attempts 1/3; branch todo/FEAT-002-refresh from main; next: add reuse test
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
| `State:` | Optional. `attempts n/3; [hyp: <one line>;] branch todo/<ID>-<slug> [from <base>]; next: <step>`. Written by todo-continue. Survives a context reset. Items are separated by `; `: `attempts`, `hyp`, `branch`, `no git`, `files`, `docs`, `next`. In no-git mode a root also keeps `files: <paths>; docs: <paths>` rolled up from its completed children (a leaf root keeps its own), written right after its `Done when`/`Links`, until the drain |
| `Blocked:` | On `[!]` tasks, instead of State. `reason → \`command\` error (max 5 lines) → action required`. A manual block by the user has no failing command: write `n/a (manual)` in the middle part |

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
- Next root number = highest root number found anywhere in `TODO.md` **and** `CHANGELOG.md` (including IDs after `Includes:`), plus 1. Next child number = highest existing child number under that parent, plus 1, never reused within the same tree.

| Prefix | Meaning | CHANGELOG heading | Commit type |
|---|---|---|---|
| `FEAT` | New capability | `### Added` | `feat` |
| `FIX` | Bug or regression | `### Fixed` | `fix` |
| `TASK` | Refactor, chore, docs, test, perf, build | `### Changed` | `refactor`, `chore`, `docs`, `test`, `perf` or `build`, whichever fits |

Children use their root's prefix.

## Which node is next

A node is **workable** when all hold: it is `[ ]`; every child is `[x]` (a leaf has none); every `Depends:` ID is satisfied; no ancestor is `[!]`; and, in git mode, its root is not claimed by another branch (see "Tree claim"). A `Depends:` ID is satisfied when it appears in CHANGELOG.md (as an entry ID or after `Includes:`) or is `[x]` in TODO.md.

**Interrupted work comes first (git mode).** Before selecting, scan the branches of the tree you are on (`git branch --list 'todo/<ROOT-ID>[-.]*'`). For each branch that is not merged into its parent's branch (`git branch --no-merged <parent branch> --list 'todo/<ID>-*'`; the parent of `A.1.2` is `A.1`), read its node's marker with `git show <branch>:TODO.md`. `[x]` means the completion stopped before its merge: finish that merge (completion step 4) and nothing else. `[/]` means work is in progress there: switch to that branch and resume it, deepest first. Only when no branch of the tree has pending work does the order below apply.

Order: roots P0 → P1 → P2, then by ID. Within a root, depth-first in document order. A parent whose children are all `[x]` is workable: that is its **integration step**.

## Lifecycle by status

The marker is the status, and each command acts only as that status allows. The rules (the todo-skills repository also has a diagram and the SDLC mapping in `docs/LIFECYCLE.md`):

| Status | `/todo-continue` | `/todo-update` | `/todo-add --parent` |
|---|---|---|---|
| `[ ]` workable | branch, claim, build, verify, complete | `in-progress`, `blocked`, `drop`, edits | allowed |
| `[ ]` waiting | skip, say what it waits for | as above | allowed |
| `[ ]` in a tree claimed by another branch | skip, report the branch | `ready` on the root releases the claim | refused |
| `[/]` | resume from `State:` | `ready` (keeps the branch), `blocked`, edits; no `drop` | refused |
| `[!]` | skip, report `Blocked:` | `ready`, `drop`, edits | refused |
| `[x]` | never touches | `revert` only | refused |

Order for every node: **ready check → branch → (first node of a tree: tree claim, published to the base branch) → claim (`[/]`) → build → verify → complete (`[x]`) → merge into parent**. The branch always exists before the status changes. Ancestors keep `[ ]` while a descendant is active.

**Ready check.** Lint passes, the node is workable, its `Ref:` exists, its `Done when` holds a runnable command, the working tree is clean (git mode only; skipped in no-git mode), and the regression baseline is green.

## Git flow

One branch per node, named `todo/<ID>-<slug>` (slug: drop the words a, an, the, to, of, and, for, with from the title, keep at most 4 of the rest, lowercase letters, digits and hyphens only, punctuation dropped; the dots in a child ID stay).

- **Branch chain.** A root branches from the base branch (`main`, `master`, `trunk` or `develop`, whichever exists) and a child from its parent's branch. When the first leaf of a tree is claimed, create every missing ancestor branch top-down, each from the previous one, then the leaf's. Record the base in the root's `State:` (`from main`). Ancestors get `State: branch <name>[ from <base>]; next: build children` (no attempts) in the first leaf's claim commit, and keep it until they complete or drain; their own claim then writes the full State.
- **Tree claim (so no one runs the same tree twice).** When the first node of a tree is claimed (the root has no `branch` item in its `State:`), right after creating the root branch make a claim commit on it that changes only the backlog files: the root gets `State: branch todo/<ID>-<slug> from <base>; next: build children` (a leaf root: `next: start <ID>`), and any pending backlog edits (new tasks) go in with it. Commit it as `chore(backlog): claim <ROOT-ID> on <branch>`. Then **advance the base branch to that commit by fast-forward** (it is the only commit ahead, so it cannot conflict): run `git merge --ff-only <root branch>` in the worktree where the base branch is checked out (`git worktree list`), or `git switch <base>` first if you are in the only worktree, then return to the root branch. If the fast-forward fails because the base moved, **re-read the root's claim in the base's `TODO.md` first**. If another branch has claimed this tree meanwhile, or the rebase conflicts on `TODO.md`, abort: switch to the base, `git branch -D` the new root branch (it holds only your unpublished claim commit; the one forced delete the skills make), report who claimed it, and stop. Otherwise rebase the root branch (it holds only the claim commit) onto the base and retry. The base branch now shows the tree as claimed, with the branch name. Only the root is published; the `[/]` marker and descendants' `State:` stay on the tree's branches.
  - **Read claims from the base branch.** A tree branch only knows its own claim, so when selecting or reporting, take every root's claim from `git show <base>:TODO.md` in addition to the current file. A root is **claimed** when its `State:` there names a branch. Its tree is workable only when the branch you are on is one of its branches (`todo/<ROOT-ID>-…` or `todo/<ROOT-ID>.…`). A root missing from the base's TODO.md is not claimed. From any other branch skip the tree and report `claimed by <branch>`; if that branch no longer exists in this clone (local or remote-tracking refs you already have), call the claim stale and tell the user to release it with `/todo-update <ROOT-ID> --status ready`. To resume your own tree, `git switch` to its branch first.
  - **Sharing claims is git's job.** The claim is a local commit on the base branch. The skills never fetch, pull or push, so how a claim reaches other clones (pushing the base branch, a pull request, the team's usual flow) is left to git and your process. Two clones that claim the same tree meet as an ordinary merge conflict on the root's `State:` line, resolved by the git-conflict rules. A protected base branch that cannot take the claim directly is a team-process choice: carry the claim by whatever means the team already uses.
- **Claim on the new branch.** Create and switch to the branch first, then set `[/]` and write `State:` there, and commit `chore(backlog): start <ID>`. If nothing changed since the last commit (re-claim after `ready`), skip the commit. `--worktree` uses `git worktree add ../<repo>.todo/<ID>` instead of switching.
- **Clean tree.** `TODO.md` and `CHANGELOG.md` changes do not count as dirty: they travel to the new branch and are committed by the claim commit. Generated files (`__pycache__`, `*.pyc`, `dist/`, `build/`, `target/`, `node_modules/`, `*.log`) do not count either and are never staged. If any are tracked, report it once and suggest a task to untrack them. Any other change makes the tree dirty: stop and ask.
- **Staging.** Add explicit paths only: the files the node changed, `TODO.md` and `CHANGELOG.md`. Never `git add -A` or `git add .`.
- **Merging.** A verified node is committed on its branch and merged `--no-ff` into its **parent's** branch (local only), then its branch is deleted with `git branch -d`. The marker was already `[x]` in that commit.
- **Refresh from the base before the root lands.** Once a root's integration step passes, and before the drain, bring the base branch's new commits into the root branch: `git merge <base>` (a merge, never a rebase, so history stays intact; local only). Resolve conflicts by the rules in "Git conflicts". If the merge brought anything in (it did not say "Already up to date"), re-run the root's `Done when` and the **full regression** on the merged result; it must pass, otherwise block the root. This checks what will actually land on the base branch, not a stale copy.
- **Root.** A verified root is drained (below). Its branch is merged into the base branch **only with `--merge`**; otherwise print the exact `git switch <base> && git merge --no-ff <branch>` for the user. Then `git branch -d` it. Apart from the tree claim, the merge of a verified root and a user-requested release, nothing reaches the base branch, and the skills never make other commits on it.
- Backlog edits made by `/todo-add`, `/todo-update` and `/todo-init` stay uncommitted until the next claim commit carries them. `TODO.md` lives on the branch where the work happens and reaches the base branch at the root merge, so add new **roots** while on the base branch (so every branch starts from the same backlog). Children (`--parent`) and `--from` follow-ups may be added on the tree's own branches. After a merge you stay on the parent's branch; say which branch is checked out in the report.
- Revert a bad merge with `git revert -m 1 <merge>` and `/todo-update <ID> --status revert`.

## CHANGELOG entry (written only by a root drain)

Inserted at the top of the matching `###` list under `## [Unreleased]`. Create the heading if missing, keeping the Keep a Changelog order (Added, Changed, Deprecated, Removed, Fixed, Security):

```markdown
- **FEAT-002** (feat): Add token refresh to the auth service. Ref: docs/auth.md#refresh. Validated: `npm test -- auth`. Includes: FEAT-002.1, FEAT-002.1.1, FEAT-002.2.
```

One entry per root, whatever the tree size. When the root has descendants, `Includes:` is last and lists every descendant ID, so Depends and the ID counter still see them. A leaf root has no `Includes:`. `Docs: updated docs/x.md.` goes before `Includes:` and lists README.md and `docs/` files changed by the whole tree: in git mode take them from `git diff --name-only <base>...<root branch>`, in no-git mode from the `docs:` items in the root's `State:`. If the root had `From:`, add `From: FIX-001.`

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

**Lint script.** If `scripts/todo-lint.sh` exists in this skill's folder (`../todo/scripts/todo-lint.sh` relative to a command skill), run `bash <that path>` from the repository root. It is read-only, needs only bash, awk and grep, and checks I1-I10 deterministically. Its result wins over your own reading. If the script is absent, check by reading the files.

Repair automatically only I5 (finish an interrupted drain by deleting the listed IDs from TODO.md). For any other violation, report it, change nothing, and ask the user how to proceed.

## Verification protocol

A node closes only through this protocol. `todo-continue` runs it.

1. **Red.** Write the tests for the node before the code. `FIX` and `FEAT` leaves must fail for the expected reason: an assertion about the new behavior, or a missing-symbol error (`ImportError`, `NameError`, `AttributeError`) when the missing symbol is the new thing under test. A syntax error or an import failure of something unrelated is not the expected reason. `TASK` refactors get characterization tests that pass before and after.
2. **Green.** Implement only what the task line says.
3. **Refactor.** Clean up with the tests green. No behavior change.
4. **Done when, in full.** Run its commands exactly as written, not narrowed.
5. **Regression.** Run the node's `regression:` command, or the project's full suite when none is given, and compare with the baseline taken before coding: no fewer passing tests, none deleted or skipped. The baseline must be green before work starts, otherwise the node is blocked as "baseline red".
6. **No cheating.** No deleted, skipped or weakened tests, and a run that executes zero tests does not count.
7. **Parents (integration step).** When every child is `[x]`, run the parent's `Done when` and the regression. If the children's tests already cover the combined behavior, the step is verify-only and writes no new test. Otherwise add one test that exercises the children together; it may pass on its first run, because the children are already built. Parents add no feature code.
8. **Roots.** The root's integration step and its drain happen in the same invocation, and the full regression suite is the last thing that runs.

Test levels: leaf = unit tests for its `Done when`; parent = integration; root = full regression. Put the task ID in new test names or comments so tests trace back to the task.

An attempt is a verification run that fails **after** you started implementing. The first red run is not an attempt. Three attempts block the node.

## Writing a Done when

- Criteria first (what a reader can check), then at least one command in backticks that is a **runnable shell command**. Not code, not prose, not an expression.
- It must run tests that exercise the behavior. Presence checks (`grep`, `ls`, `test -f`) alone are weak and the lint warns (W1). Pair them with a test.
- Target a test id or file path, not a name filter. Runners differ on what happens when nothing matches: a name filter (`-k`, `-run`, `--filter`, `-t`) can exit 0 with zero tests on some versions, which the lint warns about (W2). Prefer `python3 -m unittest tests.test_calc.CalcTest.test_multiply`, `pytest tests/test_x.py::test_y`, `go test ./pkg -run '^TestX$' -v` and check the output shows it ran, or a path-targeted command that errors when the file or id is missing.
- Add `regression:` only when the project's full suite is the wrong guard.

## Definition of Done (optional, project-wide)

If README.md, CONTRIBUTING.md or a file in `docs/` has a heading `Definition of Done`, the checklist under it applies to every node in addition to its `Done when`. Items that are commands run under the same safety rules. Items that are statements are verified by inspection and reported one by one. A missing item blocks completion.

## Git conflicts

- Never resolve by choosing a side wholesale and never use `--ours`/`--theirs` on TODO.md or CHANGELOG.md.
- **CHANGELOG.md**: keep both sides' entries (the union) in `[Unreleased]`. Drop duplicates of the same ID.
- **TODO.md**: keep the union of task blocks. If two roots share an ID, keep the one already in the base branch and renumber the newer root and its whole subtree with the next free number. **Rewrite every `Depends:` and `From:` that pointed into the renumbered tree, and state the old and new IDs in the commit message.** If that yields two `[/]` tasks, keep the one whose files are in the working tree and set the other to `[ ]`. If an ID is now in both files, remove it from TODO.md (I5).
- **Source files** in conflict: if inside the active node's scope, resolve minimally and re-run its Done when. Otherwise stop and ask.
- Mutual exclusion is per branch or worktree. Two agents on one working tree is unsupported. Use one worktree per agent.

## Validation command safety

`Done when` text can be influenced by docs and pull requests. Run a command only if it is a test, lint, typecheck or build command. Refuse and block on anything that deletes files, uses `sudo`, pipes downloads into a shell, pushes or publishes, deploys, touches paths outside the repo, or reads credentials. `manual-confirm` (only ever added by the user) closes only after the user says yes in chat.

## Hard guardrails

1. No ghost tasks. Every change to TODO.md traces to an explicit user command or to a completed code transition.
2. No required tooling. No SQLite, JSON caches, hidden files, MCP servers or SaaS. Markdown plus git only; git itself is optional. The lint script and hook are optional, read-only conveniences.
3. No node is closed without running its Done when command and its regression run and seeing both pass.
4. At most one active task at any time.
5. CHANGELOG.md is append-only apart from the `[Unreleased]` insertions made by a root drain. Never rewrite released sections.
6. Never tag, cut a release, fetch, pull or push. Moving `[Unreleased]` to a version is a human decision.
7. The base branch receives only tree claims (fast-forward), user-requested releases and the merge of a verified root. Nothing else reaches it before its root is verified.
8. When a rule here conflicts with a user's explicit instruction, state the conflict and ask. Do not silently break the rule.
