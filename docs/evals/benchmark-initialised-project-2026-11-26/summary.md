# Benchmark of an initialised project and a multi-node requirement: pi + GLM 5.3 (2026-11-26)

> Only this summary is published. The evidence of these runs (prompts, session logs, Git state) stays with the maintainer; the run rows are in [the published table](../benchmark/results/results.csv).

TASK-139 added two things to [the agent benchmark](../../../tests/benchmark/README.md): the variant `todo-skills-existing`, which is the `todo-skills` arm in a project whose backlog `/todo-init` has already set up (the agent starts at `todo-add`), and the scenario `7-text-helpers`, one requirement for four independent functions that `todo-add` splits into several nodes. The aim was to separate three costs that every earlier cell mixed: the setup of a backlog, the cost of one task and the cost of one node. This page reports a batch of fresh pi agents (`glm-5.3`) on both. Everything here is results only. The block under "Figures" is generated from the published rows by `tests/benchmark/setup_cost.py` with the options in its begin marker, and `tests/run.sh` fails when the block and the script's output differ.

## Result

- **Setup cost: small, and not separable from the spread in five of the six scenarios.** The median of the per-scenario differences between `todo-skills` and `todo-skills-existing` is USD 0.0398 per run, and the median of the per-scenario shares of the `todo-skills` USD median is 6%, with both signs across the scenarios (two scenarios where `todo-skills` was the cheaper arm, four where it was dearer). In five scenarios the lowest-to-highest USD range of one arm overlaps the range of the other, so a difference there is not seen at three runs per cell. Only `6-ambiguous` shows separate ranges (the two cells ran on different days: `todo-skills` on 2026-11-25, `todo-skills-existing` on 2026-11-26): `todo-skills` 0.2223 to 0.2527, `todo-skills-existing` 0.1164 to 0.1608, where the existing arm used 10 model calls against 11 and cost USD 0.0783 less. On `7-text-helpers` the order is the other way: `todo-skills-existing` was USD 0.1260 dearer per run, inside the spread of its three runs.
- **Cost per task:** the medians of `todo-skills-existing` per scenario are in the first table below, from USD 0.1467 (`6-ambiguous`) to USD 0.8558 (`5-interrupted`); the median of the six is USD 0.6339 per run. `7-text-helpers`, which drains four nodes, cost USD 2.1855 per run, 2.6 to 14.9 times the median of one of the single-task scenarios.
- **Cost per node:** `todo-skills-existing` drained four child nodes (the root is a fifth node and is not counted) in each of its three runs on `7-text-helpers` (a local measurement, see below), so a node cost about a quarter of a run. The figure includes what a run spends once for the whole tree (reading the skills, `todo-add` building the tree, the drain of the root), so it is the average over the run, not the marginal cost of one more node.
- **Correctness separated nothing.** Every published run of the batch passed the hidden tests on its first attempt and none was retried, for every arm, so the batch says what a run cost and not which arm passes more often.

## Figures

<!-- setup-cost:begin --since 2026-11-24 --price input=1.40,cached=0.26,output=4.40 --price-date 2026-11-23 --nodes 20261124T213520Z-513491-31162=4,20261124T233447Z-546016-30517=4,20261124T233736Z-546881-23406=4 -->
Cost per task: the medians of `todo-skills-existing` on the single-task scenarios.

| Scenario | Runs | PASS | Input tokens | Uncached input | Output tokens | Model calls | Seconds | USD per run (computed from published pricing of 2026-11-23) | USD per run, lowest to highest |
|---|---|---|---|---|---|---|---|---|---|
| `1-bugfix` | 3 | 3 | 1,624,431 | 61,767 | 28,569 | 32 | 466 | 0.6386 | 0.5062 to 0.6589 |
| `2-api-feature` | 3 | 3 | 1,565,802 | 58,730 | 26,528 | 34 | 406 | 0.5853 | 0.4877 to 0.6228 |
| `3-security-token` | 3 | 3 | 1,631,859 | 64,736 | 33,794 | 38 | 473 | 0.6291 | 0.5430 to 0.7176 |
| `4-multi-module` | 3 | 3 | 2,254,014 | 71,358 | 37,004 | 45 | 606 | 0.8302 | 0.6273 to 1.1802 |
| `5-interrupted` | 3 | 3 | 2,149,880 | 84,216 | 45,638 | 35 | 709 | 0.8558 | 0.7365 to 0.8998 |
| `6-ambiguous` | 3 | 3 | 169,273 | 34,803 | 11,840 | 10 | 157 | 0.1467 | 0.1164 to 0.1608 |
| Median of the scenario medians | | | 1,628,145 | 63,252 | 31,182 | 35 | 470 | 0.6339 | |

Setup cost: the median of `todo-skills` minus the median of `todo-skills-existing`, same scenario (difference of the rounded medians).

| Scenario | Runs, todo-skills / todo-skills-existing | Input tokens | Uncached input | Output tokens | Model calls | Seconds | USD per run | Share of the todo-skills USD median | USD per run of todo-skills, lowest to highest | USD per run of todo-skills-existing, lowest to highest |
|---|---|---|---|---|---|---|---|---|---|---|
| `1-bugfix` | 3 / 3 | -72,507 | -1,299 | -3,259 | 3 | -94 | -0.0548 | -9% | 0.5365 to 0.6048 | 0.5062 to 0.6589 |
| `2-api-feature` | 3 / 3 | -42 | 685 | -2,563 | 8 | -16 | -0.0115 | -2% | 0.5674 to 1.1242 | 0.4877 to 0.6228 |
| `3-security-token` | 3 / 3 | 124,072 | 9,627 | 1,720 | -2 | 115 | 0.0765 | 11% | 0.6287 to 0.7183 | 0.5430 to 0.7176 |
| `4-multi-module` | 3 / 3 | 481,551 | 7,314 | 2,397 | 9 | 19 | 0.1665 | 17% | 0.9574 to 0.9989 | 0.6273 to 1.1802 |
| `5-interrupted` | 3 / 3 | 107,749 | -4,635 | -4,717 | 4 | -147 | 0.0030 | 0% | 0.6895 to 0.9388 | 0.7365 to 0.8998 |
| `6-ambiguous` | 3 / 3 | 168,141 | 12,307 | 11,315 | 1 | 189 | 0.0783 | 35% | 0.2223 to 0.2527 | 0.1164 to 0.1608 |
| Median of the per-scenario differences | | 115,911 | 4,000 | -422 | 4 | 2 | 0.0398 | 6% | | |
| `7-text-helpers` | 3 / 3 | -623,483 | 6,021 | 4,896 | -7 | 152 | -0.1260 | -6% | 1.6362 to 2.0632 | 1.2067 to 3.1156 |

When the cells ran (UTC dates of the first and last run).

| Scenario | todo-skills | todo-skills-existing |
|---|---|---|
| `1-bugfix` | 2026-11-24 to 2026-11-25 | 2026-11-24 to 2026-11-25 |
| `2-api-feature` | 2026-11-24 to 2026-11-25 | 2026-11-24 to 2026-11-25 |
| `3-security-token` | 2026-11-25 | 2026-11-25 |
| `4-multi-module` | 2026-11-25 | 2026-11-25 to 2026-11-26 |
| `5-interrupted` | 2026-11-25 | 2026-11-26 |
| `6-ambiguous` | 2026-11-25 | 2026-11-26 |
| `7-text-helpers` | 2026-11-24 | 2026-11-24 |

Cost per node: each run of `todo-skills-existing` on `7-text-helpers` divided by the nodes it drained (the node counts are a local measurement, see the text).

| Run | Nodes drained | USD per run | USD per node | Model calls per node | Seconds per node | Uncached input plus output per node |
|---|---|---|---|---|---|---|
| `20261124T213520Z-513491-31162` | 4 | 3.1156 | 0.7789 | 23.8 | 360 | 65,494 |
| `20261124T233447Z-546016-30517` | 4 | 1.2067 | 0.3017 | 16.3 | 149 | 32,235 |
| `20261124T233736Z-546881-23406` | 4 | 2.1855 | 0.5464 | 23.5 | 186 | 39,118 |
| Median | 4 | 2.1855 | 0.5464 | 23.5 | 186 | 39,118 |

The five arms on `7-text-helpers`, medians.

| Arm | Runs | PASS | Input tokens | Uncached input | Output tokens | Model calls | Seconds | USD per run (computed from published pricing of 2026-11-23) | USD per run, lowest to highest | Dates (UTC) |
|---|---|---|---|---|---|---|---|---|---|---|
| `todo-skills` | 3 | 3 | 6,423,613 | 108,861 | 58,528 | 87 | 896 | 2.0595 | 1.6362 to 2.0632 | 2026-11-24 |
| `todo-skills-flow` | 3 | 3 | 3,421,081 | 95,776 | 50,191 | 55 | 633 | 1.2214 | 1.1320 to 1.3427 | 2026-11-24 |
| `todo-skills-existing` | 3 | 3 | 7,047,096 | 102,840 | 53,632 | 94 | 744 | 2.1855 | 1.2067 to 3.1156 | 2026-11-24 |
| `lean-baseline` | 3 | 3 | 2,021,899 | 69,643 | 54,342 | 37 | 662 | 0.8442 | 0.7582 to 1.0505 | 2026-11-24 |
| `no-methodology` | 3 | 3 | 171,071 | 19,519 | 16,601 | 11 | 176 | 0.1398 | 0.0865 to 0.2510 | 2026-11-24 |

Headline figures (medians; USD computed from published pricing of 2026-11-23):

- **Setup cost, scenarios 1 to 6, median of the per-scenario differences:** 4,000 uncached input tokens, -422 output tokens, 4 model calls, 2 seconds, USD 0.0398 per run; the median of the per-scenario shares of the `todo-skills` USD median is 6%.
- **Setup cost on `7-text-helpers`:** USD -0.1260 per run, -6% of the `todo-skills` USD median there.
- **Cost per task, `todo-skills-existing`, median of the scenario medians 1 to 6:** USD 0.6339 per run, 35 model calls, 470 seconds.
- **Cost per node, `todo-skills-existing` on `7-text-helpers`:** USD 0.5464 per node (median of the runs, 4 nodes each), 39,118 uncached input plus output tokens per node; the whole run is USD 2.1855 (median), against USD 0.1398 for `no-methodology` and USD 0.8442 for `lean-baseline` on the same scenario.
<!-- setup-cost:end -->

How to read the block. A cell is the runs of one arm on one scenario, three when complete. Every cell row is a median of its runs: a median of 3 runs is one run's own value, and only the USD figure is rounded (to four decimals). The setup cost of a scenario is the difference of two such medians. The rows named "median of the scenario medians" and "median of the per-scenario differences" are medians of one value per scenario (of 6), not of runs: a median of 6 values is the mean of the two middle values, which are already rounded, and that mean is rounded again. Rounding is half away from zero, so a tie such as -421.5 output tokens is printed as -422. In the cost-per-node table each row is one run, and only its Median row is a median of the 3 runs. The prices are the list prices for GLM 5.3 on z.ai as read on 2026-11-23 at https://docs.z.ai/guides/overview/pricing, in US dollars per one million tokens: input 1.40, cached input 0.26, output 4.40. The USD columns are computed from published pricing, not a bill; whether these runs were billed per token or under a subscription plan is not recorded. The token columns are what the CLI reports (input includes the cached part).

The node counts are a local measurement and are not in the published rows: each of the three `todo-skills-existing` runs on `7-text-helpers` ended with a drain commit whose `Includes:` line names `FEAT-001.1` to `FEAT-001.4`, read from the repository bundle in the run's evidence, which stays with the maintainer. They are passed to the script in the begin marker, and the script refuses a run that has none.

## What ran

- Agent: pi 1.6.0 with `glm-5.3` on z.ai, a fresh session per run, isolation `provisional`, host Windows 11 with Git Bash. The harness commit recorded for every published run is `c2d475f`. Up to three runs were in flight at once.
- Arms: `todo-skills` (`/todo-init`, then `todo-add`, then `todo-continue --merge`), the variant `todo-skills-existing` (the backlog already set up, so no `todo-init`), the variant `todo-skills-flow` (the optional helper script), `lean-baseline` and `no-methodology`. All five ran `7-text-helpers`; `todo-skills` and `todo-skills-existing` also ran `1-bugfix` to `6-ambiguous`.
- Cells: three runs each, 51 runs published, all PASS on the first attempt.
- The rows are in [the published table](../benchmark/results/results.csv). [The token page](../token-cost-2026-11-14.md) and [the cost page](../cost-per-success-2026-11-23.md) were regenerated from it. Their rows are batches of one arm, which mix scenarios of very different size, so this summary is the page to read for cells.

## Runs that are not results

- **Lost to the provider's usage limit.** 66 of the 117 runs in the result tables of the batch ended with the z.ai usage-limit message: 56 within a minute, before any work, and 10 after 130 to 1417 seconds of work (a local count from the evidence). By code: 46 with code 1308 (the 5-hour limit), 20 with code 1310 (the weekly limit) and none with code 1302. Each is an INFRA_ERROR with no scored outcome and is neither published nor counted. The batch was rerun until each cell had three results, which is why the cells ran on different days (inferred; see the dates table).
- **Ten passes (420 jobs) that started no agent.** Ten passes of the queue (42 jobs each) ended at once with `INFRA_ERROR: unknown scenario <id>`, so no agent ran and no row exists. The message names only the scenario; that the checkout the queue ran from had no scenario folders is inferred, not investigated. The passes that produced the published rows ran from a checkout at the harness commit.
- **The first attempt at the batch (eight runs, not published).** Three todo-skills arms ran `7-text-helpers` in it (`todo-skills`, `todo-skills-existing` and `todo-skills-flow`); two of them, `todo-skills` and `todo-skills-existing`, stopped at the confirmation `todo-add` asks for before it writes a tree of several nodes: the final message of one says it must "show the proposed tree and wait for confirmation". Nobody answers in a benchmark run and a stop is a FAIL, so both FAILed having built none of the four functions. The other six runs of that attempt, `todo-skills-flow` among them, passed (why that one did not stop was not looked into). The fix is one sentence in the `arm.md` of the three todo-skills arms (commit `c2d475f`: nobody answers a confirmation, so confirm the plan or tree, decline optional files and go on). Every published run ran with that sentence.
- **The pilot (two runs, not published).** One run each of `todo-skills` and `todo-skills-existing` on `7-text-helpers`, made after the fix and before the batch. `todo-skills` passed. `todo-skills-existing` FAILed on a defect in its own code and not on the harness: the hidden test of `parse_row` failed on a line ending in a lone carriage return, which the requirement keeps in the last field (only one trailing `\n` or `\r\n` is dropped). That reading comes from the verifier line and the requirement text.

## What it means

- A project that has its backlog set up cost a little less to work in on the median of scenarios 1 to 6 (USD 0.04 per run; the median of the per-scenario shares is 6%), but the difference changes sign across the scenarios and lies inside the spread of its cells in five of six. What `todo-skills-existing` saves is only what `/todo-init` reads and writes; both arms still read the skills for `todo-add` and `todo-continue` and make the same branches and commits (inferred from the arm texts and from the commit lists of the runs; the split of calls is not measured here). The one scenario with separate ranges, `6-ambiguous`, is also the cheapest scenario, where a fixed part of a run weighs most (a possible reading, not measured).
- The one four-node requirement (`7-text-helpers`) cost 2.1 to 9.2 times (`todo-skills`) and 2.6 to 14.9 times (`todo-skills-existing`) the median of a single-task scenario of the same arm (the ratio of the `7-text-helpers` median to each of the six single-task medians; see the first table, the setup table and the five-arm table). That is what was observed on one requirement, not a measured law of cost against the number of nodes. On it, `no-methodology` and `lean-baseline` finished at a fraction of the cost of the todo-skills arms, and all arms passed.
- The spread inside a cell is as large as the setup differences: the dearest run of a cell cost up to about 2.6 times the cheapest (`todo-skills-existing` on `7-text-helpers`) and 2.9 times (`no-methodology` on `7-text-helpers`; see the lowest-to-highest columns; no other cell is above 2.0), and in five of the six single-task scenarios the two arms' ranges overlap. Read a median here as one of three draws.

## Limits

- One agent and model (pi with GLM 5.3). Claude Code and Codex did not run this batch, and another agent or model would give other numbers.
- Isolation is `provisional`: the agent was not proven unable to read the hidden tests, the harness folder or the runs folder.
- The runner names the scenario in the prompt (a `Scenario: 7-text-helpers` line), which a real user would not do.
- Three runs per cell. A median of three, and the difference of two such medians, is not a rate: no count here is a rate, and a difference inside the lowest-to-highest range of its cells is not evidence of an effect.
- The cells did not run on one day or under one load. The provider's limits spread them over three days (inferred): from the start of the first run, 2026-11-24 21:35 UTC, to the last published row, 2026-11-26 04:23 UTC, about 31 hours over three UTC dates. Up to three runs ran at once on one machine, and seconds depend on that load and on the provider. The dates table gives the days of each cell, and the two arms of one scenario were not always run on the same day.
- The node counts are a local measurement from the repository bundles of three runs; nobody else can check them. A published row holds only an evidence hash, which only the holder of the evidence can verify.
- Runs lost to the usage limits are excluded, as stated above. 10 lost runs were ended mid-work, so long runs were more exposed; whether that biases the medians is not known.
- The USD figures are the tokens the CLI reports at one provider's list prices on one date, not a bill.
