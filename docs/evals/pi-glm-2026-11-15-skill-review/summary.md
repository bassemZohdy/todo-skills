# pi + GLM 5.3: the skill text after a review in rounds (2026-11-15)

> Only this summary is published. The evidence of these runs (prompts, session logs, Git state) stays with the maintainer.

TASK-131 and TASK-132 reviewed the text of all nine skills and their reference files in eleven rounds: each round looked for contradictions, stale pointers and gaps, fixed what it found, pinned each fix with a check in `tests/run.sh` and ran the suite. Rounds 1 to 6 worked from reading alone. This batch asks whether fresh agents still follow the changed text, and uses what they report as unclear as the input of rounds 7 to 11. The rule for a change: a sentence is fixed when it is a contradiction, when two or more reports name it, or when the task itself wrote it.

## Setup

- Agent: pi 1.5.2 with `glm-5.3` on z.ai, a fresh session per run, tools `read,powershell,edit,write`.
- Host: Windows 11 with Git Bash, unisolated verifier (`TRIAL_WINDOWS_ISOLATION=0`).
- Skill text: commit `51888b8` (after round 6) for the first batch, `87337a0` (after round 7) for the second, `788ccb7` (after round 8) for the third, `1b9a24b` (after round 10) for the fourth and `8bddde2` (after round 11) for the fifth. Each batch ran from a frozen checkout of its commit.
- One run per scenario and batch, three at a time. Two scenarios were added before the first batch: `no-backlog` and `drained-unmerged`. An untouched setup fails each of them.

## Results

32 of 32 runs passed on the first try (five batches, 15 scenarios). The table lists the first three batches; batch 4 ran `replan`, `interrupted-merge`, `update-block` and `no-git` (16, 15, 10 and 5 assertions, all passing) and batch 5 ran those four and `happy-path`, all passing.

| Scenario | What it checks on the changed text | Batch 1 | Batch 2 | Batch 3 |
|---|---|---|---|---|
| `no-backlog` (new) | Without a `TODO.md`, `/todo-add` writes nothing, says so and names `/todo-init` | PASS, 9 of 9, 8 calls | | |
| `drained-unmerged` (new) | On the branch of a root drained without `--merge`: the report names its merge commands and the run goes on to the next root from `main` | PASS, 15 of 15, 34 calls | PASS, 15 of 15, 42 calls | |
| `happy-path` | One leaf root with `--merge` | PASS, 12 of 12, 27 calls | PASS, 12 of 12, 30 calls | PASS, 12 of 12, 31 calls |
| `no-git` | The lifecycle and the drain without git | PASS, 5 of 5, 26 calls | PASS, 5 of 5, 25 calls | |
| `lanes` | `/todo-continue --all-lanes --merge`, with the coordinator's items renamed | PASS, 16 of 16, 71 calls | | |
| `refresh-from-base` | A resumed root, refreshed from a base that moved, no `--merge` | PASS, 18 of 18, 23 calls | | |
| `monorepo` | `/todo-init`, `/todo-add`, `/todo-continue --merge` in a two-package project | PASS, 17 of 17, 52 calls | | |
| `add-lane` | `/todo-add --lane` with a lane the Lanes section does not declare | PASS, 13 of 13, 15 calls | PASS, 13 of 13, 13 calls | |
| `update-drop` | A drop logs the ID under Revisions | PASS, 11 of 11, 16 calls | | |
| `replan` | `/todo-plan --revise` drops a node and edits the plan doc | PASS, 15 of 15, 17 calls | PASS, 15 of 15, 16 calls | PASS, 15 of 15, 16 calls |
| `report` | `/todo-report` writes only `docs/status.html` | PASS, 10 of 10, 14 calls | | |
| `plan-inline` | `/todo-plan` plans inside `TODO.md` | | PASS, 12 of 12, 16 calls | |
| `interrupted-merge` | A child whose merge into its parent did not happen | | PASS, 16 of 16, 12 calls | PASS, 16 of 16, 14 calls |
| `baseline-red` | A red baseline stops the run before anything changes | | | PASS, 10 of 10, 14 calls |
| `update-block` | A manual block | | | PASS, 10 of 10, 12 calls |

Calls are the agent's tool calls.

## What the agents reported as unclear, and what changed

Each agent lists the ambiguities it met. None blocked a run. A sentence was changed when it was a contradiction, when two or more reports named it, or when it was one this task had written.

After batch 1 (round 7), ten sentences:

- Two reports each: the `low` complexity example was phrased for fixes ("whose fix the task line states"); a root's marker between its verify and its drain was only implied; "the tree" in the interrupted-merge check had no referent before a node is selected.
- Two sentences that rounds 1 and 3 had written: the drained, unmerged root shared a bullet with the interrupted drain, and "item 1" under item 4 of step 10 could be read as item 10.1.
- The core listed `reference/lanes.md` under "a lane flag", so an agent running `/todo-add --lane` read a file that only `/todo-continue` needs.
- A single new leaf needs no confirmation, but a lane line it adds does; `/todo-add` did not say which rule wins.
- `/todo-add` ended with "Nothing enters TODO.md unless this command created it", which one agent read as a possible licence to create the file.
- Where **Out of scope** goes in a plan doc that has no **Scope** section.
- Which plan docs get a path line on the status page.

Three of these were listed as open follow-ups in the [2026-11-14 batch](../pi-glm-2026-11-14-lanes-inline-planning/summary.md).

After batch 2 (round 8), four sentences. No agent raised a round 7 sentence the same way again.

- "the lint's W3 warning" named W3 without saying what it is.
- The rule for where a test carries its task ID put the exception last.
- "only when it is clean", before a root merges into the base, could mean either checkout (second report).
- "a revise creates no plan doc" stood apart from its one exception (both `replan` runs).

After batch 4 (round 10), four sentences that two or more reports had named and the earlier rounds had not changed: "Run the invariant check first" in `/todo-update` ("first" had no anchor), the check that finds an interrupted merge in `/todo-continue` (now named by its core section), where a created **Out of scope** section goes and what it holds, and the blank lines of a created CHANGELOG heading against "no blank line between entries".

After batch 5 (round 11), three more that batch 4 named twice or more: how `/todo-update` blocks a node that has no `State:`, which plan doc a dropped root's Revisions line goes to, and where the baseline of a no-git run is taken.

Batch 5 raised nothing that met the rule and changes behaviour, which ended the rounds.

After batch 3 (round 9), one phrase: "the branch named after `from`" meant the branch name that follows the word `from` in `State:`. Nothing else in that batch was a defect of the text.

## Reported more than once and left as it is

- Adding a public interface counts for documentation drift and does not count for the optional root review. Three reports called the two rules easy to confuse. Each agent applied both correctly, because the text of each rule names the other.
- A run with no failed cycle need not advance `next:` in `State:`. Three reports asked whether it should. It is deliberate: `next:` only tells a later session where to resume.
- "With a subagent tool" and "if the host has a goal command" depend on the host. pi has neither, and every agent took the stated fallback.
- The two steps numbered 2 and 2b in `/todo-add`. Renumbering would break the step numbers other files point at.
- The format of a bullet in a created **Out of scope** section and of the other free-text lines (separators, wording of the reason). Any wording is valid, and each agent chose one.
- Git-mode-only items in a no-git run (the merge commands in 10.4.4, `Checked:` lines, the interrupted-merge and interrupted-drain cases). Every no-git agent read them as not applying, which is right.
- Hosts and shells: `bash -c` on Windows under PowerShell, "a subagent tool", "a goal command". Each agent used the stated fallback.
- Whether a lone `Red:` line means a red baseline or the red test of step 7 (one report); the text says "leaves that started red", which is the second.

## Limits

- One run per scenario and batch, one agent, one host: the results show that a fresh agent can follow the text, not how often.
- Claude Code and Codex were not run on this text.
- Rounds 10 and 11 were checked by four and five runs, not by a rerun of every scenario.
- Nothing ran `/todo-init --ci`, so the action versions that round 3 updated in `reference/ci.md` were checked only against this repository's own workflows and the actions' release pages, not by an agent.
- No scenario has a root with its own plan doc, so the status page with a per-root plan doc was checked only by `tests/run.sh`, and a drop or a revise that writes into such a doc was not exercised by an agent.
- `--worktree`, a design review and a root review were not reached by any run.
- The prompts tell the agent that confirmations were given in advance, so no run shows an agent waiting for a yes.
