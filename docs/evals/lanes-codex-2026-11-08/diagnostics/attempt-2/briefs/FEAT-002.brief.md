# Lane assignment

Root ID: FEAT-002
Worktree: /runs/multi-module/repo.todo/FEAT-002
Baseline: `mvn -B test`, 2 tests passing (1 core, 1 text).
Ref paths: none.

Read first, including Command safety:
- `/runs/multi-module/repo.todo/FEAT-002/.claude/skills/todo-continue/SKILL.md`
- `/runs/multi-module/repo.todo/FEAT-002/.claude/skills/todo/SKILL.md`
- `/runs/multi-module/repo.todo/FEAT-002/.claude/skills/todo/reference/verification.md`
- `/runs/multi-module/repo.todo/FEAT-002/.claude/skills/todo/reference/git-flow.md`

Work only inside this worktree; use an absolute `cd` to it in every shell call. Switch child branches inside the lane worktree. Skip step 3 (the coordinator's baseline holds) and the tree claim in step 4 (already done). Run steps 1, 2, 4–9 and step 10 items 1–3 for each node of this one root depth-first, including the root's own integration step if it is a parent, with everything committed. Stop before the root's drain (step 10 item 4), leaving the root `[/]` with `next: drain` in its `State:`, committed in the leaf root's node commit or the parent root's integration-step commit, never a separate commit.

Stay inside the task lines; never edit another lane's nodes, `Done when`, or the base branch; never merge to base; never drain; never push. Never fetch, tag, use `git add -A` or `git add .`, or modify or remove git hooks. If git needs an identity, use `git -c user.email=t@t -c user.name=t`. Return a summary per node (ID, commands and results, commit).
