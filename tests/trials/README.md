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
| `race-claim-conflict` | One free root FEAT-001. A hook plays a second session: right after the agent first switches to a `todo/FEAT-001*` branch, main moves to a commit that claims FEAT-001 for `todo/FEAT-001-rival` | Run `/todo-continue`; stop after the claim step | The fast-forward fails, the claim is re-read, the agent deletes its own unpublished root branch, reports the rival and starts nothing. Main still ends at the rival's claim |
| `race-claim-benign` | Same hook, but the commit that lands on main is an unrelated docs change | Run `/todo-continue`; stop after the claim step | The agent rebases its claim-only branch onto the new main and fast-forwards; main keeps the docs commit plus exactly one claim commit |
| `release` | Released 0.1.0 (tagged), `[Unreleased]` holds a feat and a fix, compare links at the bottom | Phase 1: run `/todo-release` and stop at the question (nothing may change). Phase 2: start again and answer "0.2.0, confirmed" | Phase 1 proposes 0.2.0 with a one-line reason and changes no file. Phase 2 writes the dated section, a new empty `[Unreleased]`, updated links, one `chore(release): 0.2.0` commit, and no tag. Assert after phase 2 |
| `monorepo` | Two packages, `make test` as the only documented test entry, a hand-written CHANGELOG without IDs, no `TODO.md`. HEAD on main | Run `/todo-init`, then `/todo-add "add a power function to the api package"`, then `/todo-continue --merge` | The tests command found is `make test`; the human CHANGELOG is kept; a task for packages/api is written with a runnable Done when; the task is built on a branch, verified against the whole `make test` suite, and drained |
