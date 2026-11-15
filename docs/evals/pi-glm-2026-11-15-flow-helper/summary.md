# pi + GLM 5.3: a helper script for the lifecycle bookkeeping (2026-11-15)

> Only this summary is published. The evidence of these runs (prompts, session logs, Git state) stays with the maintainer; the run rows are in [the published table](../benchmark/results/results.csv).

FEAT-129 asked whether a script can cut the model calls and tokens of a todo-skills run. Git commands and edits of `TODO.md` and `CHANGELOG.md` were about half of the calls in [the earlier measurement](../token-cost-2026-11-14.md), and wording alone did not reduce them ([TASK-120](../pi-glm-2026-11-14-batched-steps/summary.md)). The candidate is `tools/todo-flow.sh`, an optional script with three commands (`start`, `complete`, `drain`) that make the same branches, commits and backlog lines as the skill text, one call each. `/todo-continue` uses it when the project has `.todo/todo-flow.sh` and works as before without it.

## Result: the targets were not met, and the helper is not merged

The targets were set before the runs: median model calls at least 25% lower, median uncached input plus output tokens at least 30% lower, no fewer PASS outcomes, and no scenario with a higher median call count.

| Median of the runs | Baseline (18 runs) | With the helper (18 runs) | Change |
|---|---|---|---|
| Model calls | 29 | 26 | -10% |
| Input tokens | 1,205,976 | 1,010,855 | -16% |
| Uncached input tokens | 49,413 | 53,415 | +8% |
| Output tokens | 19,783 | 19,332 | -2% |
| Uncached input plus output | 68,750 | 71,915 | +5% |
| Seconds | 287 | 278 | -3% |
| First-attempt PASS | 18 of 18 | 18 of 18 | |
| Final outcome PASS | 18 of 18 | 18 of 18 | |

Model calls fell by 10%, not 25%. Uncached input plus output rose by 5% where the target was a 30% fall. `6-ambiguous` used more calls with the helper (median 12 to 14). Correctness did not change. By the rule set beforehand the current design stays and the change is dropped.

| Scenario | Calls, baseline | Calls, helper | Median | Uncached input plus output, baseline | With the helper | Median |
|---|---|---|---|---|---|---|
| `1-bugfix` | 31, 34, 28 | 26, 21, 24 | 31 to 24 | 67,457, 64,683, 62,162 | 78,042, 58,903, 59,919 | 64,683 to 59,919 |
| `2-api-feature` | 28, 41, 37 | 26, 27, 37 | 37 to 27 | 59,717, 64,124, 70,044 | 61,476, 74,297, 88,924 | 64,124 to 74,297 |
| `3-security-token` | 29, 34, 28 | 22, 21, 32 | 29 to 22 | 74,955, 87,505, 72,513 | 92,600, 79,719, 80,859 | 74,955 to 80,859 |
| `4-multi-module` | 34, 29, 33 | 31, 27, 26 | 33 to 27 | 86,504, 84,086, 82,732 | 69,534, 103,072, 67,955 | 84,086 to 69,534 |
| `5-interrupted` | 35, 28, 29 | 29, 28, 27 | 29 to 28 | 66,787, 89,765, 70,800 | 77,646, 76,790, 66,184 | 70,800 to 76,790 |
| `6-ambiguous` | 15, 12, 7 | 14, 12, 17 | 12 to 14 | 42,160, 35,508, 33,908 | 44,419, 44,852, 58,346 | 35,508 to 44,852 |

All 36 runs passed the hidden tests on the first attempt.

## Setup

- Agent: pi 1.5.2 with `glm-5.3` on z.ai, a fresh session per run, tools `read,powershell,edit,write`. Host: Windows 11 with Git Bash, isolation `provisional`.
- Baseline: the `todo-skills` arm on `main` at `b7274a8`, the text after FEAT-125 to TASK-128. Six scenarios, three runs each.
- Candidate: the variant `tests/benchmark/variants/todo-skills-flow` at commit `55d973e`: the same arm and instructions, plus the helper copied to `.todo/`. The same 18 cells.
- Both batches ran three repetitions side by side on the same machine, about four hours apart.

## Where the calls went (measured locally)

These figures come from the raw session logs, which are not published.

- **The helper did its part.** All 15 runs that reached a node used it: 45 invocations, none refused and none stopped. Calls that only write git or backlog state fell from a median of 10 to 3 per run, and the calls from the first branch to the end fell from 18 to 12.5, 31%.
- **Setup is untouched.** The calls before the first branch (reading the skills, `/todo-init`, `/todo-add`) were a median of 13 in both batches. They are now half of a run, and a script cannot make them.
- **Reading the script costs what the bookkeeping saved.** The skills tell the agent to read a script before running it. The 16 KB helper is about 4,000 tokens of new input. The uncached input and output of the bookkeeping calls fell from about 8,500 to 4,100 tokens per run, so the two cancel.
- **A run that never starts a node only pays.** `6-ambiguous` stops with a question before any branch exists. With the helper present the agent still read it, which is why that scenario got more expensive.
- **The tokens charged at full rate are elsewhere.** Uncached input is mostly the skill text and the agent's own reasoning carried forward, and the output is mostly reasoning during `/todo-init` and `/todo-add`. The bookkeeping calls held about 12% of uncached input plus output in the baseline, so no change to them could reach a 30% cut.

## Pilot

One pilot run of `1-bugfix` on an earlier, 258-line helper took 24 calls. The agent needed two reads for the script and two more calls to check a result the script had just produced. The helper was then cut to 199 lines and made to end every run with the commits it made, the checked-out branch, whether the tree is clean and the `todo/` branches left. The pilot is not in the published table, because it ran a different version of the script.

## Lifecycle trials

One fresh pi run per scenario on the candidate text, with the helper installed (`TRIAL_FLOW_HELPER=1`), unisolated verifier.

| Scenario | Outcome | Assertions | Helper commands the agent ran |
|---|---|---|---|
| `happy-path` | PASS | 12 of 12 | `start`, `complete`, `drain` |
| `leftover-work` | PASS | 13 of 13 | `start`, `complete`, `drain` |
| `refresh-from-base` | PASS | 18 of 18 | `complete` twice, `drain` |
| `team-claim` | PASS | 16 of 16 | `start` twice |
| `blocked-sibling` | PASS | 11 of 11 | `start` |
| `regress-block` | PASS | 11 of 11 | `start` |
| `interrupted-merge` | PASS | 16 of 16 | `complete`, refused (the node was already `[x]`); the agent finished the merge by hand |
| `lanes` | PASS | 16 of 16 | `start`, refused (a linked worktree); the lane work went on by hand |
| `no-git` | PASS | 5 of 5 | `start`, refused (not a git repository); the agent went on in no-git mode |
| `dirty-tree` | PASS | 11 of 11 | none: the skill stopped first |
| `baseline-red` | PASS | 10 of 10 | none: the skill stopped first |
| `happy-path`, helper not installed | PASS | 12 of 12 | none: the same text without `.todo/todo-flow.sh` |

Every refusal left the repository unchanged and the agent then followed the steps of the skill text, which is what the refusal is for.

## What it means

- A helper script removes most bookkeeping calls safely: the same commits, no failed run, no refusal that left a mess. It is worth about three model calls and 16% of the (mostly cached) input of a small task, and nothing in the tokens charged at full rate.
- The bookkeeping was never the larger part of a small run. Half of the calls are setup, and the rest is reading, editing and testing code.
- The saving would be larger on a tree with many nodes, since each node saves about seven calls and the script is read once. No scenario here has more than one or two nodes, so that is an estimate, not a result.
- The helper stays on its branch, unmerged. The rows of both batches are published either way.

## Limits

- One agent and model, one host, isolation `provisional`, three runs per cell. The spread within a cell is wide (`2-api-feature`: 26, 27 and 37 calls with the helper), so a difference of three calls in the overall median is a small effect, not a precise one.
- Claude Code and Codex were not run. An agent that reads files in larger pieces, or that batches git commands on its own, would give other numbers.
- Seconds depend on the load of the machine and of the provider and are not credited to the helper.
- The share of calls and tokens by activity was counted from the raw logs with a script that labels each call by the commands in it; a call that mixes activities is counted once, by its first match.
- Only one candidate was run. A second one was allowed, but no change to the bookkeeping could meet the second target, so the runs were not spent.
