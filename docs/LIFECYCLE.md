# Task lifecycle

The marker on each task in `TODO.md` is its status. Every command reads the marker first and does only what that status allows. The git branch is created **before** the status changes, and nothing reaches the base branch until a whole tree is verified.

```text
        ready check            branch first          verify                 complete
 [ ] ───────────────► [ ] ───────────────► [/] ───────────────► [/] ───────────────► [x] ──► merged into parent
 Ready   workable?    create branch,      In progress    tests + regression    marker, commit,     (root: drained to
         baseline     switch, then        (claim commit) pass, gates pass      merge --no-ff        CHANGELOG, merged
         green        set [/]                                                  into parent branch   into base on --merge)
                                              │ 3 failed cycles / red baseline / outside scope
                                              ▼
                                             [!] Blocked ── /todo-update --status ready ──► [ ]
```

## Statuses

| Marker | Status | Meaning |
|---|---|---|
| `[ ]` | Ready | Defined, not started. May still wait for children or dependencies |
| `[/]` | In progress | Its branch exists and is checked out. At most one in the file |
| `[!]` | Blocked | Stopped with a reason, the failing command and the action a human must take |
| `[x]` | Done | Verified, committed and merged into its parent's branch. A root is never `[x]`: it is drained |

Ancestors of the active node keep `[ ]`. They count as in progress implicitly, and `/todo-status` shows them that way.

## The steps

| # | Step | Status before → after | What happens |
|---|---|---|---|
| 1 | **Ready check** | `[ ]` | Lint passes, the node is workable, the `Ref:` exists, its `Done when` is a runnable command, the working tree is clean, and the regression baseline is green |
| 2 | **Branch** | `[ ]` | Create `todo/<ID>-<slug>`, creating any missing ancestor branches top-down first (root from the base branch, each child from its parent). Switch to it |
| 3 | **Claim** | `[ ]` → `[/]` | On the new branch set `[/]`, write `State:`, commit `chore(backlog): start <ID>`. The backlog files travel with the branch |
| 4 | **Build** | `[/]` | Red: write the tests, see them fail for the right reason. Green: implement what the task line says. Refactor: clean up with tests green. Update docs |
| 5 | **Verify** | `[/]` | `Done when` in full, then the regression run against the baseline, then the gates |
| 6 | **Complete** | `[/]` → `[x]` | Set the marker, delete `State:`, lint, then commit the node's files |
| 7 | **Merge** | `[x]` | `git merge --no-ff` into the parent's branch, then `git branch -d` the child branch |
| 8 | **Integrate** (parents) | `[ ]` → `[/]` → `[x]` | Once every child is `[x]` the parent is workable. Same steps, but build is a cross-child integration check |
| 9 | **Drain** (roots) | tree removed | One CHANGELOG entry with `Includes:`, subtree deleted from TODO.md, commit |
| 10 | **Merge to base** | | Only with `--merge`. Otherwise the exact commands are printed |

Any step that fails after three cycles, finds a red baseline, or needs something outside the task line ends in `[!]`.

## What each command does by status

| Status | `/todo-continue` | `/todo-update` | `/todo-add --parent` | `/todo-status` |
|---|---|---|---|---|
| `[ ]` workable | Branches, claims, builds, verifies, completes | `in-progress`, `blocked`, `drop`, field edits | Allowed | Lists it, marks the next one |
| `[ ]` waiting | Skips and says what it waits for | Same as above | Allowed | Shows what it waits for |
| `[/]` | Resumes from `State:` and `git status` | `ready` (abandons, keeps the branch), `blocked`, field edits. No `drop` | Refused | Shows branch, State, changes |
| `[!]` | Skips and reports the `Blocked:` line | `ready`, `drop`, field edits | Refused | Lists reason and action |
| `[x]` | Never touches it | `revert` only | Refused | Counts it in children done/total |

## SDLC practices applied

| Practice | How it shows up |
|---|---|
| Short-lived branches, small changes (DORA: hours, few active branches) | Sizes S and M, one branch per node, at most 3 levels, so at most 3 branches are open |
| Tests pass before anything merges (DORA: protected trunk) | Nothing merges to the parent without `Done when` and regression green. Nothing merges to base before its root is verified, and then only on `--merge` |
| Keep the build green, fix or revert at once | A red baseline blocks the node before work starts. Revert a bad merge with `git revert -m 1 <merge>` and `/todo-update <ID> --status revert` |
| Definition of Ready | The ready check above, repeated by `/todo-add` when it writes a task |
| Definition of Done | The project's own `Definition of Done` heading plus the gates: tests, regression, docs drift, self-review, no secrets, no tracked build output, no stray `TODO`/`FIXME` |
| Red, green, refactor | Build step. Containers run an integration check instead |
| Test levels | Leaf: unit tests for its `Done when`. Parent: integration check of its children. Root: the full regression suite |
| Regression testing | The `regression:` command, or the full suite, against a baseline taken before coding |
| Lightweight review | The self-review gate, optional `--isolated` fresh-context review, and the human merge into base. Teams can open a pull request from the root branch instead of merging locally |
| Traceability | The ID is in the branch name, commit body (`Refs:`) and CHANGELOG entry. Put the ID in new test names or comments |
| CI parity | `/todo-init` reports the test command found in CI config, so the regression command matches what CI runs |
| Release is separate | The skills never tag, push or move `[Unreleased]` to a version |
| Hotfix | A `P0` `FIX` root branches from the base branch like any other root |

## Where the backlog lives

`TODO.md` is versioned like code. The claim commit puts the backlog on the node's branch, so the state of a tree (`[/]`, `[x]`, `State:`) lives on that tree's branches and reaches the base branch at the root merge. Add new roots from the base branch; add children and follow-ups on the tree's own branches.

## Without git

Steps 2, 3's commit, 6's commit, 7 and 10 are skipped, and the one-time warning is printed. The status model, `State:`, verification, gates and drain are the same. The self-review gate reads the files listed in `State: files:` against the task line, because there is no diff.
