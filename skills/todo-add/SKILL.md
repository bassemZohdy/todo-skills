---
name: todo-add
description: Add work to the TODO.md task tree. Use for /todo-add <description> [--priority P0|P1|P2] [--ref <docs-path>] [--type feat|fix|task] [--from <ID>] [--parent <ID>] [--clarify]. Sizes the request, breaks it into a tree until every leaf is S or M, writes each node as a 2-4 line task with an exact Done when command, and inserts it. Never starts work.
argument-hint: <description> [--priority P0|P1|P2] [--ref <docs-path>] [--type feat|fix|task] [--from <ID>] [--parent <ID>] [--clarify]
---

# /todo-add

First load the `todo` core skill (tree format, sizes, IDs, invariants, guardrails). If it is not available as a skill, read `../todo/SKILL.md`.

Defaults: priority `P1`. Type is inferred from the description (bug, crash, regression, broken → `FIX`; add, implement, support, new → `FEAT`; otherwise `TASK`) unless `--type` is given. With `--parent`, the type is the parent's prefix. Show the chosen prefix in the result.

## Steps

1. **Git mode and invariants.** Check git; in a non-git folder print the one-time warning (core, "Git mode") and continue. Run the invariant check.
2. Resolve `--ref`. If the path does not exist, say so and ask. Anchors (`#section`) are allowed. If none is given and a doc in `docs/` clearly governs the work, propose it. Otherwise omit `Ref`. Never invent a path.
3. Resolve `--from <ID>`. It must exist in TODO.md or CHANGELOG.md, otherwise ask. It becomes `From:` (provenance only).
4. Resolve `--parent <ID>`. It must be a `[ ]` node in TODO.md that is not at level 3 (depth limit) and not `[x]`, `[/]` or `[!]`. The new node becomes its last child and the parent's size is recomputed (`L`, or `XL` if the new node gets children of its own). Without `--parent` the new task is a root.
5. **Clarify.** Ask **one message of at most 3 short questions** when the behavior, the target module or the verification command cannot be derived from the description and the repo. With `--clarify`, always run one such round first. Wait for the answers. Never guess to avoid asking.
6. **Size and break down.**
   - Estimate the work: `S` at most 2 files, `M` one context window and at most 5 files. Anything bigger is a parent.
   - Break a parent into children until every leaf is `S` or `M`, with at most 3 levels. Parents are `L` (children are leaves) or `XL` (grandchildren). Order the children as the work will run; add `Depends:` between siblings only when the order is not obvious.
   - Each node gets a one-sentence "what to do" and a `Done when:` that states the criteria and at least one exact, runnable command. Prefer a targeted test (`pytest tests/test_x.py::test_y`). If the test does not exist yet, name the file the node will create. Add `regression: \`cmd\`` only when the project's full suite is not the right guard. Never write `manual`, `n/a` or a vacuous command (`true`, `echo`, `ls`).
   - Containers get their own `Done when` (an integration test of the children together).
   - Optional `Depends:` only for prerequisites the user named or that the breakdown requires. Each ID must exist.
   - If the request needs long design, requirements or a plan (more than 6 nodes, or detail that does not fit in 4 lines), offer to write it to `docs/plans/<ROOT-ID>-<slug>.md` and link it with `Ref:`. Create that file only if the user agrees.
7. **Fit.** The result must stay within 120 lines in total. If it would not fit, add only the root and its first level (marked as such in your reply), say the rest is decomposed lazily when its parent becomes workable, and offer the plan file. If even that does not fit, refuse and suggest finishing or dropping something. Do not trim existing tasks.
8. **Confirm.** For more than one node, show the proposed tree (IDs, sizes, one-line titles) and wait for confirmation before writing. Add only what the user confirms. A single new leaf needs no confirmation.
9. Assign IDs (core ID rules) and insert: new roots ordered P0 → P1 → P2 and by ascending ID within a priority; children at the end of their parent's children. Re-run the lint script.
10. Reply with the inserted tree and its position. Do not start work.

Nothing enters TODO.md unless this command created it from the user's request.
