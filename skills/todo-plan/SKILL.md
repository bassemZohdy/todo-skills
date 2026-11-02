---
name: todo-plan
description: Plan or re-plan the work in the TODO.md task tree. Use for /todo-plan [<goal>] [--revise [<reason>]]. Turns a goal into a plan doc (docs/plans/PROJECT.md) and a proposed tree with lanes, or revises the plan at any time when it no longer fits. Only open [ ] nodes are changed; started or finished work is never touched. Shows the change and waits for confirmation. Never starts work.
argument-hint: [<goal>] [--revise [<reason>]]
---

# /todo-plan

First load the `todo` core skill (tree format, sizes, IDs, lanes, invariants), and read `../todo-add/SKILL.md` and `../todo/reference/verification.md` for how nodes are sized and written. If the core is not a skill, read `../todo/SKILL.md`.

Never starts work and never touches code. Without `--revise` it plans; with it, it re-plans. Check git (core "Git mode"). In git mode read claims from `git show <base>:TODO.md`: the nodes of a claimed tree may be changed only from that tree's branch; anywhere else, list them as locked and leave them unchanged. Dates are `date +%F`. Show every proposal in full before asking for confirmation.

## Plan (default)

1. Run the invariant check. Read README.md, `docs/`, `TODO.md`, `CHANGELOG.md`, and `docs/plans/PROJECT.md` if it exists.
2. **Ask once**, at most 3 short questions, only for what the repo does not answer: the goal and its done-state, what is out of scope, and which parts can run in parallel (independent tracks). Skip any that are answered.
3. Draft the plan doc `docs/plans/PROJECT.md` (not written yet; ask first before creating `docs/` if it is absent; if the doc exists, propose edits to it instead of a new draft). Keep it short, sections as `##` headings in this order:
   - **Goal**, **Scope**, **Out of scope**.
   - **Lanes**: one line each, `<name>: <what it covers>; independent of <lanes>`. A lane is a track one agent can work alone. Use `main` when there is only one.
   - **Decisions** and **Open questions**.
   - **Revisions**: empty until the first revise.
4. Propose the tree with the `/todo-add` rules (sizes, `Done when`, 3 levels; if it would pass 120 lines, propose roots and first levels only, with `next: decompose` where a node still needs children): each root gets `Ref: docs/plans/PROJECT.md` (with a section anchor when one fits) and, unless its lane is `main`, a `Lane:` in `Links:`. Order roots so independent lanes do not `Depends:` on each other. Show IDs, sizes, lanes and one-line titles.
5. **Wait for confirmation.** Then write the plan doc and the tree, only what the user confirms. Lint. Do not commit; the next tree claim commits them (core "Backlog files").

## Revise (`--revise`)

Use when the user thinks the plan is not proper, at any time, even mid-tree.

1. Run the invariant check. Read the plan doc and the whole tree. Take the reason from the argument, or ask one question: "what is wrong with the plan?".
2. Only `[ ]` nodes change. `[/]`, `[x]` and `[!]` nodes, and anything drained to CHANGELOG, are never edited. If the change needs an active node to change, say so and offer `/todo-update <ID> --status ready` first.
3. Propose the change as a diff: nodes added, dropped, split, merged, resized, re-ordered or moved to another lane, and plan-doc lines changed. IDs are kept; new IDs follow the core rules; a dropped node is deleted from `TODO.md` and its ID is never reused (the Revisions line names it, which the ID rule counts). A plan-doc section the change needs (for example **Out of scope** for dropped work) is created if missing, at its place in the Plan step 3 order; other missing sections are left alone. A dropped node with finished descendants is not dropped; say why. Every `Depends:` or `From:` on a dropped ID is removed or re-pointed in the same diff (I7).
4. **Wait for confirmation.** Apply, append a bullet to **Revisions** in the plan doc (`- <date +%F> · <the user's reason, verbatim> · <what changed, naming every added, dropped or moved ID>`), lint, and report the new tree. Do not commit, as in Plan step 5. The plan doc and `TODO.md` must agree afterwards.
