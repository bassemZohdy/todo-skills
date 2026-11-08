# Lane assignment: FEAT-002

Worktree: `/runs/multi-module/repo.todo/FEAT-002`  
Baseline: `mvn -B test`, 2 passing, 0 skipped.  
Ref paths: none.

Read first (including Command safety): `.claude/skills/todo-continue/SKILL.md`, `.claude/skills/todo/SKILL.md`, `.claude/skills/todo/reference/verification.md`, and `.claude/skills/todo/reference/git-flow.md`, relative to your worktree.

Work only inside your worktree; switch child branches there. Skip step 3 (the coordinator's baseline holds) and the tree claim in step 4 (already done). Run steps 1, 2, 4–9 and step 10 items 1–3 for each node of this one root depth-first, including a parent root's own integration step. Commit everything. Stop before the root's drain (step 10 item 4), leaving the root `[/]` with `next: drain` in its State, committed in the leaf root's node commit or the parent root's integration commit, never a separate commit.

Stay inside the task lines; never edit another lane's nodes, `Done when`, or the base branch; never merge to base, drain, or push. Return a summary per node with ID, commands and results, and commit.

Trial constraints: use only this worktree; do not read or write outside the repository and its todo worktrees. Use an absolute `cd` in every shell call. Never fetch, tag, use `git add -A` or `git add .`, or modify or remove git hooks. If git needs an identity, use `git -c user.email=t@t -c user.name=t`.
