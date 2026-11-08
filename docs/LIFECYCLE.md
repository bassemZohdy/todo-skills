# Task lifecycle

The marker on each task in `TODO.md` is its status. Every command reads the marker first and does only what that status allows. The git branch is created **before** the status changes, and nothing reaches the base branch until a whole tree is verified. "Claim" means the tree claim published on the base branch; marking a node `[/]` is its start.

```text
       ready check           branch first              build + review + verify        complete
 [ ] ──────────────► [ ] ──────────────────► [/] ───────────────────────────► [/] ─────────────► [x] ──► merged into parent
 Ready  workable?    tree claim on the base  In progress   red, green, refactor,    marker, commit,    (root: refreshed from base,
        baseline     (first node), branch,   (start        review, Done when +      merge --no-ff      last gate, drained to
        green        then set [/]            commit)       regression, gates        into parent        CHANGELOG, merged with --merge)
                                                   │ 3 failed attempts / failure outside scope / review or DoD gate
                                                   ▼
                                                  [!] Blocked ── /todo-update <ID> --status ready ──► [ ]
```

## Statuses

| Marker | Status | Meaning |
|---|---|---|
| `[ ]` | Open | Defined, not started. It may still wait for children, dependencies or another branch's claim |
| `[/]` | In progress | Its branch exists and holds its work. At most one in the file |
| `[!]` | Blocked | Stopped with a reason, the failing command and the action a person must take |
| `[x]` | Done | Verified, committed and merged into its parent's branch. A root is never `[x]`: it is drained |

Ancestors of the active node keep `[ ]`. They count as in progress implicitly, and `/todo-status` shows them that way. `[/]`, `[x]` and the children's `State:` live on the tree's branches; the base branch shows only the claim until the root lands.

## The steps

| # | Step | Status | What happens |
|---|---|---|---|
| 1 | **Select** | | Interrupted work first (an unmerged `[x]` branch, an uncommitted drain, a `[/]` node), then the first workable `[ ]` node in order |
| 2 | **Ready check** | `[ ]` | Lint passes, the node is workable, its `Ref:` exists, its `Done when` has a runnable command, the tree is clean, and the regression baseline is green (or `none`, or red for a `FIX` node that targets the failure) |
| 3 | **Tree claim** (first node of a tree) | `[ ]` | Root branch from the base, a claim-only commit (the root's `State:` names the branch, plus pending backlog edits), then the base is fast-forwarded to it. Others now skip the tree |
| 4 | **Branch** | `[ ]` | Missing ancestor branches top-down, then `todo/<ID>-<slug>` for the node |
| 5 | **Start** | `[ ]` → `[/]` | On the node's branch: set `[/]`, write `State:`, commit `chore(backlog): start <ID>` |
| 6 | **Read** | `[/]` | The `Ref:` doc and the governing docs, then only the code the node needs. With `--plan`: a plan, committed, and a stop for your approval |
| 7 | **Build** | `[/]` | Red: tests first, failing for the expected reason. Green: implement only the task line. Refactor with tests green |
| 8 | **Review** | `[/]` | The whole diff against the task line and `Done when`, by a fresh-context reviewer when a subagent tool exists |
| 9 | **Verify** | `[/]` | `Done when` in full, the regression against the baseline, the Definition of Done, the RTM, documentation drift |
| 10 | **Complete** | `[/]` → `[x]` | Set the marker, delete `State:`, lint, commit the node's files |
| 11 | **Merge** | `[x]` | `git merge --no-ff` into the parent's branch, delete the child branch |
| 12 | **Integrate** (parents) | `[ ]` → `[/]` → `[x]` | Once every child is `[x]` the parent is workable: the same steps, with an integration check instead of feature code |
| 13 | **Refresh** (roots) | | Merge the base into the root branch; if anything came in, rerun `Done when` and the full regression |
| 14 | **Last gate** (roots) | | `.todo/check.sh`, when it exists |
| 15 | **Drain** (roots) | tree removed | One CHANGELOG entry with `Includes:`, the subtree deleted from `TODO.md`, commit `chore(backlog): drain <ID>` |
| 16 | **Merge to base** | | Only with `--merge`. Otherwise the local `git merge --no-ff` commands and the push-and-pull-request alternative are printed for you |

`/todo-continue` completes one node per invocation (lane runs excepted): a child stops after its merge into the parent, a root after its drain. Run it again, ideally with a cleared context, for the next node. A session that dies mid-way is recovered by the next `/todo-continue`, which finishes an unmerged `[x]` branch or resumes the `[/]` node first.

Any step that finds a red baseline stops before anything changes. A failure outside the task line, a missing Definition of Done item, review findings still valid after two rounds, or a third failed attempt ends in `[!]` ([VERIFICATION.md](VERIFICATION.md#test-failures-and-blocking)).

## What each command does by status

| Status | `/todo-continue` | `/todo-update` | `/todo-add --parent` | `/todo-status` |
|---|---|---|---|---|
| `[ ]` workable | Claims (first node), branches, starts, builds, verifies, completes | `in-progress`, `blocked`, `drop`, field edits | Allowed | Lists it, marks the next one |
| `[ ]` waiting | Skips and says what it waits for | `blocked`, `drop`, field edits (`in-progress` is refused) | Allowed | Shows what it waits for |
| `[ ]` in a tree claimed by another branch | Skips and reports the branch | `ready` on the root releases the claim | Refused | Shows `claimed by <branch>`, stale if the branch is gone |
| `[/]` | Resumes from `State:` and `git status` | `ready` (abandons, keeps the branch), `blocked`, field edits. No `drop` | Refused | Shows branch, State, changes |
| `[!]` | Skips and reports the `Blocked:` line | `ready`, `drop`, field edits | Refused | Lists reason and action |
| `[x]` | Never touches it | `revert` only | Refused | Counts it in children done/total |

## SDLC practices applied

| Practice | How it shows up |
|---|---|
| Short-lived branches, small changes | Leaves fit one context window (at most 5 files), one branch per node, at most 3 levels, so at most 3 branches are open per tree |
| Visible work in progress, no duplicate work | The tree claim on the base branch names the owning branch |
| Tests pass before anything merges | Nothing merges to the parent without `Done when` and the regression green. Nothing merges to the base before its root is verified, and then only with `--merge` |
| Integrate continuously | Roots merge the latest base in and rerun the full regression before landing, so the tested code is the code that lands |
| Keep the build green | A red baseline blocks new work before it starts; only a `FIX` for the failure may start |
| Definition of Ready | The ready check, repeated by `/todo-add` and `/todo-plan` when they write a task |
| Definition of Done | The project's own `Definition of Done` checklist plus the gates: tests, regression, documentation drift, review |
| Red, green, refactor | The build step. Parents run an integration check instead |
| Test levels | Leaf: its `Done when` tests. Parent: an integration check of its children. Root: the full regression suite and the last gate |
| Lightweight review | The review step (a fresh-context reviewer when possible) and your merge into the base, or a pull request from the root branch |
| Traceability | The ID is in the branch name, the commit body (`Refs:`), the test names and the CHANGELOG entry; optionally an RTM row |
| CI parity | `/todo-init` reports the test command CI runs, and `.todo/check.sh` runs the same lint and tests locally and in CI |
| Release is separate | Only `/todo-release` turns `[Unreleased]` into a version, after you confirm. No skill tags or pushes |
| Hotfix | A `P0` `FIX` root added on the base is picked before claimed trees and gets its own branch ([GIT-FLOW.md](GIT-FLOW.md#starting-resuming-and-recovering)) |

## Without git

The tree claim, branches, commits, merges and the refresh are skipped, after a one-time warning. Statuses, `State:` (with `no git`, `files:` and `docs:`), verification, the gates and the drain are the same. The review reads the files listed in `State: files:`, because there is no diff ([GIT-FLOW.md](GIT-FLOW.md#no-git-mode)).
