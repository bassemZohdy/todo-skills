---
name: todo-plan
description: Plan or re-plan the work in the TODO.md task tree. Use for /todo-plan [<goal>] [--revise [<reason>]]. Turns a goal into a proposed tree with lanes inside TODO.md (a plan doc only for a complex goal), or revises the plan at any time when it no longer fits. Only open [ ] nodes are changed; started or finished work is never touched. Shows the change and waits for confirmation. Never starts work.
argument-hint: "[<goal>] [--revise [<reason>]]"
---

# /todo-plan

First load the `todo` core skill (tree format, scope rule and complexity, IDs, lanes, invariants), and read `../todo-add/SKILL.md` and `../todo/reference/done-when.md` for how nodes are split, rated and written. If you cannot load a skill by name, read `../todo/SKILL.md`.

Never starts work and never touches code. Without `--revise` it plans; with it, it re-plans. Check git (core "Git mode"). In git mode read claims from `git show <base>:TODO.md`: the nodes of a claimed tree may be changed only from that tree's branch; anywhere else, list them as locked and leave them unchanged. Dates are `date +%F`. New roots, and changes to unclaimed trees, are written only on the base: on a `todo/` branch, show the proposal but refuse to write it and name the base. Show every proposal in full before asking for confirmation.

## Plan (default)

1. Run the invariant check. Read README.md, `docs/`, `TODO.md`, `CHANGELOG.md`, and `docs/plans/PROJECT.md` if it exists.
2. **Ask once**, at most 3 short questions, only for what the repo does not answer: the goal and its done-state, what is out of scope, and which parts can run in parallel (independent tracks). Skip any that are answered. When the goal is still unclear, read `../todo/reference/clarify.md` and apply its checklist and stop triggers.
3. **Plan inline.** The plan is the Lanes section and the tree in `TODO.md`: draft one lane line for each lane the tree uses, `- <name>: <what it covers>` (add `; independent of <lanes>` when it helps; `main` needs no line, and a single-track plan adds none), and write no plan doc and no `Ref:` for it. **Complex goal** (more than 6 nodes in total, a `high` root, or the user asks): also offer one doc per root, `docs/plans/<ROOT-ID>-<slug>.md` (core ID rules) with `##` sections Goal, Scope, Out of scope, Decisions and Open questions, linked by that root's `Ref:`; ask first before creating `docs/` if it is absent. An existing `docs/plans/PROJECT.md` is read, and edits to it are proposed instead of a new draft.
4. With an existing tree, propose only new roots (and children under open `[ ]` roots in unclaimed trees); changes to existing nodes go through `--revise`. Propose the tree with the `/todo-add` rules (scope, complexity, `Done when`, 3 levels; if it would pass 120 lines, propose roots and first levels only, with `next: decompose` where a node still needs children): a root gets a `Ref:` only to its own plan doc, or to the section of an existing `docs/plans/PROJECT.md` that governs it, and, unless its lane is `main`, a `Lane:` in `Links:`. A lane not declared in the `## 🛤️ Lanes` section of `TODO.md` gets its line there from the Lanes you drafted, in the same confirmation (the section is created above the Task Tree when the file has none; `main` needs no line). Order roots so independent lanes do not `Depends:` on each other. Show IDs, complexity, lanes and one-line titles.
   If an RTM exists (`../todo/reference/rtm.md`: `docs/RTM.md`, else README `## RTM`), link roots that implement a listed requirement with `Ref: <rtm path>#<Req>` and show the RTM row changes with the tree; with no RTM, skip this and do not offer one more than once.
5. **Wait for confirmation.** Then write the lane lines, the tree and any plan doc the user accepted, only what the user confirms. Lint. Do not commit; the next tree claim commits them (core "Backlog files").

## Revise (`--revise`)

Use when the user thinks the plan is not proper, at any time, even mid-tree.

1. Run the invariant check. Read the whole tree and its plan docs (`docs/plans/PROJECT.md`, any doc a root's `Ref:` names). Take the reason from the argument, or ask one question: "what is wrong with the plan?".
2. Only `[ ]` nodes change. `[/]`, `[x]` and `[!]` nodes, and anything drained to CHANGELOG, are never edited. If the change needs an active node to change, say so and offer `/todo-update <ID> --status ready` first.
3. Propose the change as a diff: nodes added, dropped, split, merged, re-rated, re-ordered or moved to another lane, and lane lines and plan-doc lines (when a doc exists) changed. IDs are kept; new IDs follow the core rules; a dropped node is deleted from `TODO.md` and its ID is never reused (the Revisions line names it, which the ID rule counts). A plan-doc section the change needs (**Out of scope** for dropped work) is created if missing in an existing doc, after the last of Goal and Scope that exists (else first), as one bullet per dropped item (ID, title, reason); other missing sections are left alone. A node with any descendant that is not `[ ]` is not dropped, merged or moved; say why. Every `Depends:` or `From:` on a dropped ID is removed or re-pointed in the same diff (I7).
4. **Wait for confirmation.** Apply and lint. With a plan doc (the changed root's own, else `PROJECT.md`), append a bullet to its **Revisions** (`- <date +%F> · <the user's reason, verbatim> · <what changed, naming every added, dropped or moved ID>`). Without one, a drop offers to create `docs/plans/PROJECT.md` holding only `## Revisions` and that line (ask first when `docs/` is missing; say that without it a dropped ID could be reused); otherwise a revise creates no plan doc. Report the new tree. Do not commit, as in Plan step 5. A plan doc and `TODO.md` must agree afterwards. With an RTM, remove a dropped ID from its Tasks cell in the same diff and keep the IDs of moved or re-rated nodes unchanged.

## Independent design review (optional, never a required stage)

For a `high` root, or one that touches security, data migration or concurrency or changes an existing public interface (adding one does not count), offer once a design review before the first build node starts; read `../todo/reference/review.md` ("Design review") only then. Never ask for it on other roots and never block a plan on it.
