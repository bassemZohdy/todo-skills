# Planning and lanes

How work gets into the tree before anyone builds it, how the plan changes later, and how independent parts run in parallel. The rules the model follows are in [`plugin/skills/todo-plan/SKILL.md`](../plugin/skills/todo-plan/SKILL.md), [`plugin/skills/todo-add/SKILL.md`](../plugin/skills/todo-add/SKILL.md) and [`plugin/skills/todo/reference/lanes.md`](../plugin/skills/todo/reference/lanes.md).

## Three ways in

| Command | Use it for |
|---|---|
| `/todo-add "<description>"` | One task, or one request broken into a tree. Asks up to 3 questions when unclear |
| `/todo-plan "<goal>"` | A goal that needs a plan: writes `docs/plans/PROJECT.md` and proposes roots in lanes |
| `/todo-init --plan` | The first session on a project: up to 3 questions, the answers saved as `docs/plans/PROJECT.md`, then `/todo-plan` for the tree |

None of them starts work, and none commits: their edits are backlog files that the next tree claim commits ([FILES.md](FILES.md#backlog-files-and-when-they-are-committed)). New roots are written only on the base branch.

## Splitting a request

- **Scope rule:** every leaf is one change that fits one context window and touches at most 5 files. Bigger work becomes a parent with children, at most 3 levels deep, ordered as the work will run. `Depends:` between siblings only when the order is not obvious.
- **Complexity** is rated per node (`mid` when unsure); a parent by its integration step.
- **Done when** for every node, leaves and containers alike ([VERIFICATION.md](VERIFICATION.md#writing-a-done-when)).
- **Definition of Ready:** a node is not written unless its `Ref:` exists, its `Depends:` IDs exist, it fits the scope rule, and its command names a test target.
- **Fit:** `TODO.md` stays within 120 lines. If a tree would not fit, only the root and first level are written, with `State: next: decompose` on nodes that still need children; `/todo-continue` breaks them down when they become workable. Existing tasks are never trimmed to make room.
- **Long designs** (more than 6 nodes, or detail that does not fit 4 lines) go into `docs/plans/<ROOT-ID>-<slug>.md`, linked with `Ref:`, on your yes.

## The plan doc

`docs/plans/PROJECT.md`, short, with these `##` sections in order:

```markdown
## Goal
## Scope
## Out of scope
## Lanes
api: the HTTP endpoints; independent of web
web: the dashboard; independent of api
## Decisions
## Open questions
## Revisions
- 2026-11-08 · the dashboard is out of scope · dropped FEAT-003
```

Each lane line reads `<name>: <what it covers>; independent of <lanes>`. With only one track, the lane is `main`. Revisions stays empty until the first re-plan. The skills ask before creating `docs/`, and propose edits to an existing plan doc instead of a new draft.

`/todo-plan` gives each root `Ref: docs/plans/PROJECT.md` (with a section anchor when one fits) and a `Lane:` unless its lane is `main`, and orders roots so that independent lanes do not depend on each other. With an existing tree it proposes only new roots, and children under open roots of unclaimed trees. With an [RTM](REFERENCE.md#requirements-traceability-optional), roots that implement a listed requirement link to its row, and the row changes are shown with the tree.

## Re-planning

`/todo-plan --revise "<what is wrong>"` works at any time, even mid-tree.

- Only open `[ ]` nodes change. `[/]`, `[x]`, `[!]` nodes and drained work are never edited; if the change needs an active node, the agent offers `/todo-update <ID> --status ready` first.
- A node with any descendant that is not `[ ]` is never dropped, merged or moved.
- The change is shown as a diff: nodes added, dropped, split, merged, re-rated, re-ordered or moved to another lane, and plan-doc lines changed.
- IDs are kept. A dropped ID is never reused (the Revisions line names it, and the ID rule counts it), and every `Depends:` or `From:` on it is removed or re-pointed in the same diff.
- On your yes the change is applied, `- <date> · <your reason, verbatim> · <what changed>` is appended under Revisions, and the lint runs. The plan doc and `TODO.md` must agree afterwards.

Dropping a single node is also possible with `/todo-update <ID> --status drop --note "<reason>"`, which logs it under Revisions the same way.

## Design review (optional)

For a `high` root, or one that touches security, data migration, concurrency or a public interface, `/todo-plan` offers once a review before the first build node starts. You can also ask for one ("review this plan", `--review`, or a line under Open questions). It is never required and never blocks the plan.

- **Fresh-context reviewer:** a new subagent gets only the plan doc, the root and its children as written in `TODO.md`, and the `Ref` path. It reads and comments; it never edits files or runs tests. Without a subagent tool, the agent offers a review in a new session from the same files.
- **External tool:** a design-review skill or tool the project already uses runs on the same inputs instead. This repository neither bundles nor requires one.
- Accepted findings go through `--revise`; declined or open ones are recorded under Open questions.

## Root review (optional)

For the same kind of root, `/todo-continue` asks once, after the root is refreshed from the base and before its last gate and drain, whether to review the whole root. A fresh-context reviewer (or a new session, without a subagent tool) gets the whole root diff (`git diff <base>...<root branch>`), the plan doc and the root's `Ref`, and returns spec compliance and quality findings. Valid findings inside the root's task line are fixed on the root branch before the drain, after which `Done when` and the regression run again. Findings outside it become `/todo-add --from <ROOT-ID>` suggestions. Declined findings go under the plan doc's Open questions. It is never required and never offered for other roots. Both reviews are described in `plugin/skills/todo/reference/review.md`.

## Lanes

A **lane** is a named track of root trees that one agent context works alone, in order. `Lane: <name>` (a lowercase letter, then lowercase letters, digits or dashes) goes in a root's `Links:`; children inherit it, and a root without it is in lane `main`. A lane can hold one root or many. Order across lanes is expressed only with `Depends:`; work that depends on another lane's open node is not workable, and that lane stops there.

| Run | What happens |
|---|---|
| `/todo-continue` | All lanes are one queue; one node per invocation |
| `/todo-continue --lane <name>` | Only that lane's roots, in order. `--lane main` selects roots without a lane |
| `/todo-continue --all-lanes` | The main thread becomes the **coordinator** and starts one subagent per lane, all at once |
| `/todo-continue --all-lanes --seq` | The same, one lane after another |

Without a subagent tool, `--all-lanes` says so and the coordinator works each lane itself, one after another, in each lane's worktree.

### What the coordinator does

0. **Unfinished lane work first.** Every root claimed on the base whose branch exists here is finished before anything new is claimed: a root at `next: drain` goes to step 4, anything else is resumed in its worktree.
1. Runs the ready check and baseline for the first workable node of every lane. A red baseline stops the run.
2. For each lane root in turn, from the base: root branch, tree claim, fast-forward of the base, so each later claim starts from a base that already holds the earlier ones. Then one worktree per root at `../<repo>.todo/<ROOT-ID>`. The main checkout stays on the base for the whole run.
3. Starts one subagent per lane (with a `Models:` line, on the model for the highest complexity in that lane's root). Each gets only its root ID and worktree, the baseline count, the `Ref` paths, the skill files to read, and the rules: stay inside the task lines; never edit another lane's nodes, a `Done when` or the base; never merge to the base, drain or push. It works its root depth-first, including the root's integration step, commits everything, and **stops before the drain**, leaving the root `[/]` with `next: drain`.
4. **Trusts no summary.** For each finished root, one at a time: refresh from the base in its worktree (the coordinator resolves the `TODO.md`/`CHANGELOG.md` conflicts that every root after the first will have), rerun `Done when` and the regression against the base's current pass count, drain it there, and with `--merge` merge it into the base, remove the worktree and delete the branch; otherwise print those commands. A real conflict or a red result stops the run.
5. Reports per lane: finished, blocked, still open, merge commands, and each lane's next workable root.

Lanes only pay off when their trees touch different files. If the refresh from the base shows they do not, the coordinator says so and suggests one lane. Whether lane subagents actually ran at the same time has not been independently verified in the recorded trials ([agent-compatibility.md](agent-compatibility.md)).
