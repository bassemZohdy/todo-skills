---
name: todo-add
description: Add work to the TODO.md task tree. Use for /todo-add <description> [--priority P0|P1|P2] [--ref <docs-path>] [--type feat|fix|task] [--from <ID>] [--parent <ID>] [--lane <name>] [--clarify]. Sizes the request, breaks it into a tree until every leaf is S or M, writes each node as a 2-4 line task with an exact Done when command, and inserts it. Never starts work.
argument-hint: <description> [--priority P0|P1|P2] [--ref <docs-path>] [--type feat|fix|task] [--from <ID>] [--parent <ID>] [--lane <name>] [--clarify]
---

# /todo-add

First load the `todo` core skill (tree format, sizes, IDs, invariants, guardrails) and read `reference/verification.md` from its folder ("Writing a Done when"). If the core is not available as a skill, read `../todo/SKILL.md` and `../todo/reference/verification.md`.

Defaults: priority `P1`. Unless `--type` is given, the type is the first rule that matches the description: (1) its first word, or the word after a leading "add", is tests, docs, refactor, rename or chore → `TASK`; (2) fix as the first word, or bug, crash, crashes, regression or broken anywhere → `FIX`; (3) add, implement or support as the first word, or new anywhere → `FEAT`; (4) otherwise `TASK`. With `--parent`, the type is the parent's prefix, and `--priority`, `--lane` and `--type` are refused (children inherit them). Show the chosen prefix in the result.

## Steps

1. **Git mode and invariants.** Check git; in a non-git folder print the one-time warning (core, "Git mode") and continue. Run the invariant check.
2. Resolve `--ref`. If the path does not exist, say so and ask. Anchors (`#section`) are allowed. If none is given and a doc in `docs/` clearly governs the work, propose it. Otherwise omit `Ref`. Never invent a path.
3. Resolve `--from <ID>`. It must exist in TODO.md or CHANGELOG.md, otherwise ask. It becomes `From:` (provenance only).
4. Resolve `--parent <ID>`. It must be a `[ ]` node in TODO.md with at most one dot in its ID (a child of a level-2 node would exceed 3 levels), in a tree that is not claimed by another branch (core lifecycle table). The new node becomes its last child, and every ancestor's size is recomputed (core "Tree, levels and sizes"). Without `--parent` the new task is a root. `--lane <name>` (roots only; lowercase, digits, dashes) adds `Lane: <name>` to its `Links:`; children inherit their root's lane.
5. **Clarify.** Ask **one message of at most 3 short questions** when the behavior, the target module or the verification command cannot be derived from the description and the repo. With `--clarify`, always run one such round first. Wait for the answers. Never guess to avoid asking.
6. **Check it is not already done.** Search the code and tests for the behavior (names, a quick `grep`; run the targeted test if one exists). If it appears to exist already, say so and ask before adding anything.
7. **Size and break down.**
   - Estimate the work: `S` at most 2 files, `M` one context window and at most 5 files. Anything bigger is a parent.
   - Break a parent into children until every leaf is `S` or `M`, with at most 3 levels. Parents are `L` (children are leaves) or `XL` (grandchildren). Order the children as the work will run; add `Depends:` between siblings only when the order is not obvious.
   - Each node gets a one-sentence "what to do" and a `Done when:` written by the rules in `reference/verification.md`, "Writing a Done when": criteria, `; `, then a runnable command that targets a test id or path, not a name filter. If the test does not exist yet, name the file or id the node will create. Add `regression: \`cmd\`` only when the project's full suite is not the right guard. Never write `manual`, `n/a`, a vacuous command, or code or prose in backticks: write identifiers and calls bare (calc.power(2, 3) returns 8) and put only the runnable command in backticks.
   - Containers get their own `Done when`: the integration test or, when the children's tests already cover it, the regression command. A parent's `Done when` may pass at baseline; only leaves must start red.
   - If an existing test already covers the criterion, the task is not new work: ask instead of naming that test.
   - **Definition of Ready.** Do not write a node that fails the ready check you can already do: the `Ref` exists, `Depends` IDs exist, the size fits, and the command's test target is named.
   - Optional `Depends:` only for prerequisites the user named or that the breakdown requires. Each ID must exist.
   - If the request needs long design, requirements or a plan (more than 6 nodes, or detail that does not fit in 4 lines), offer to write it to `docs/plans/<ROOT-ID>-<slug>.md` and link it with `Ref:`. Create that file only if the user agrees.
8. **Fit.** The result must stay within 120 lines in total. If it would not fit, add only the root and its first level: a first-level node that still needs children keeps `L` or `XL` with `State: next: decompose` (core), and `/todo-continue` breaks it down when it becomes workable. Say so in your reply and offer the plan file. If even that does not fit, refuse and suggest finishing or dropping something. Do not trim existing tasks.
9. **Confirm.** For more than one node, show the proposed tree (IDs, sizes, one-line titles) and wait for confirmation before writing. Add only what the user confirms. A single new leaf needs no confirmation.
10. Assign IDs (core ID rules: one global sequence across FEAT, FIX and TASK, never reused) and insert. Do not commit; the next claim commit carries the backlog edit. Place new roots ordered P0 → P1 → P2 and by ascending ID within a priority; children go at the end of their parent's children. Suggest adding new roots while on the base branch. Re-run the lint script.
11. Reply with the inserted tree and its position. Do not start work.

Nothing enters TODO.md unless this command created it from the user's request.
