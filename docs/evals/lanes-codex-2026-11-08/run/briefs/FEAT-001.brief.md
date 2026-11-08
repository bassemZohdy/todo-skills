# Lane assignment

Root ID: FEAT-001
Worktree: /runs/multi-module/repo.todo/FEAT-001
Baseline: `mvn -B test`, 2 passing, 0 failures or skipped.
Ref paths: none.

Read these first, including Command safety:
- /runs/multi-module/repo.todo/FEAT-001/.claude/skills/todo-continue/SKILL.md
- /runs/multi-module/repo.todo/FEAT-001/.claude/skills/todo/SKILL.md
- /runs/multi-module/repo.todo/FEAT-001/.claude/skills/todo/reference/verification.md
- /runs/multi-module/repo.todo/FEAT-001/.claude/skills/todo/reference/git-flow.md

Work only inside your worktree. Switch child branches inside it. Skip step 3 (the coordinator's baseline holds) and the tree claim in step 4 (already done). Run steps 1, 2, 4–9 and step 10 items 1–3 for each node of this root depth-first, including the root's integration step if it is a parent. Commit everything and stop before the root's drain (step 10 item 4), leaving the root `[/]` with `next: drain` in its `State:`. A leaf root sets it in its node commit, step 10 item 2; a parent root sets it in its integration-step commit; never make a separate commit for it.

Stay inside the task lines; never edit another lane's nodes, `Done when`, or the base branch; never merge to base; never drain; never push. Return a summary per node with ID, commands and results, and commit. Never fetch, tag, use `git add -A` or `git add .`, or modify or remove git hooks. If git needs an identity, use `git -c user.email=t@t -c user.name=t`. Use an absolute `cd` to your worktree in every shell call.
