# The plan stop and breaking a node down

Read on demand from `/todo-continue`: "Plan" with `--plan` or `next: plan proposed` (step 6), "Decompose" for a node whose `State:` says `next: decompose` (step 2). Part of the `todo` core skill.

## Plan

If a plan was proposed, show it (the body of the newest commit whose subject is exactly `chore(backlog): plan <ID>`; none or no git: print a new one) and ask "approve the plan? (yes / change: …)": yes sets `next: build` and goes on with step 7; a change is committed the same way (`--allow-empty` if `TODO.md` is unchanged) and stops. Otherwise print a plan of at most 10 lines (files, approach, risks), set `next: plan proposed`, commit it as `chore(backlog): plan <ID>` with the plan as the body, and **stop**.

## Decompose

A node with `next: decompose` is broken down, not built:

1. Work on the base for an unclaimed tree (as `/todo-continue` step 3, "Where to start"), otherwise on the tree's branch.
2. Split it with steps 7-8 of the `todo-add` skill (`../todo-add/SKILL.md` from the `/todo-continue` folder) and `reference/done-when.md`. If the result would pass 120 lines: write nothing, say so, stop.
3. Show the children and write them after the user confirms (on a `todo/` branch commit `chore(backlog): decompose <ID>`). Then stop.
