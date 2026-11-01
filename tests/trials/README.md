# Agent trials

Repeatable scenarios for the skills. `setup.sh` builds a scratch project in a new directory and puts it into a starting state with plain git commands. A fresh agent then follows the skills from that state, and `assert.sh` checks what it left behind. Neither script deletes anything.

```bash
bash tests/trials/setup.sh /tmp/trial-a interrupted-merge
# give the agent the prompt below, with /tmp/trial-a as its only working folder
bash tests/trials/assert.sh /tmp/trial-a interrupted-merge
```

Common instructions for the agent: work only inside the scratch folder, read the skills in `.claude/skills/<name>/SKILL.md`, follow them literally, never push, never use `git add -A`, and report every ambiguity with the quoted text.

| Scenario | Starting state | Prompt | Expected |
|---|---|---|---|
| `interrupted-merge` | Claimed tree FEAT-001 with two children. FEAT-001.1 is `[x]` on its own branch and was never merged. HEAD is on the root branch | Run `/todo-continue`. Stop after one invocation | The pending merge is finished (`--no-ff`, branch deleted) and nothing else is started |
| `refresh-from-base` | Leaf root FEAT-001 is `[/]` with its implementation and test uncommitted. Meanwhile main gained another tree's work | Run `/todo-continue` (no `--merge`) | Verifies, merges main into the root branch, reruns the full suite on the result, drains, commits, prints the merge commands |
| `claimed-elsewhere` | Main shows FEAT-001 claimed by a branch; FEAT-002 is free. HEAD on main | Run `/todo-continue`; stop right after the claim | FEAT-001 is skipped and its claimant reported; FEAT-002 gets a branch and a claim published to main |
