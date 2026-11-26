# Token cost of a todo-skills run (2026-11-14)

What the published benchmark rows say about tokens, and where a todo-skills run spends them. The table below has one row per batch of an arm and is generated: `python3 tests/benchmark/tokens.py docs/evals/benchmark/results/results.csv` prints it, and `tests/run.sh` fails when this page and that output differ. Everything after the table that is marked *measured locally* came from raw session logs that are not published (see [the rule](README.md)); those numbers cannot be recomputed from this repository.

Scope: pi with GLM 5.3, isolation `provisional`. The rows up to 2026-11-14 are six small tasks, 17 to 20 runs per row (three per scenario). The rows of 2026-11-24 and later are the batch of [the initialised-project benchmark](benchmark-initialised-project-2026-11-26/summary.md): the runs of one arm less than six hours apart, across seven scenarios, so a row there mixes scenarios of very different size (`7-text-helpers` is four functions in one requirement) and says little by itself; the per-cell medians are in that summary. Runs that the provider's usage limit ended are not published and are not in any row. No other agent has run the benchmark. No money figure is given on this page: the cost page and the summary compute one from published pricing, with its date.

## Published rows

<!-- tokens:begin -->
| Date | Arm | Runs | Input tokens (median) | Uncached input (median) | Cached share of input | Output tokens (median) | Model calls (median) | Seconds (median) |
|---|---|---|---|---|---|---|---|---|
| 2026-11-12 | lean-baseline | 18 | 123,952 | 5,889 | 95% | 3,721 | 13 | 75 |
| 2026-11-12 | no-methodology | 18 | 41,237 | 2,769 | 92% | 1,689 | 6 | 26 |
| 2026-11-12 | todo-skills | 20 | 1,039,495 | 47,417 | 95% | 18,269 | 29 | 310 |
| 2026-11-13 | todo-skills | 17 | 1,034,971 | 52,929 | 94% | 18,644 | 31 | 402 |
| 2026-11-14 01h | todo-skills | 18 | 1,072,291 | 52,187 | 95% | 18,149 | 31 | 292 |
| 2026-11-14 22h | todo-skills | 18 | 1,205,976 | 49,413 | 95% | 19,783 | 29 | 287 |
| 2026-11-14 | todo-skills-flow | 18 | 1,010,855 | 53,415 | 94% | 19,332 | 26 | 278 |
| 2026-11-24 | lean-baseline | 3 | 2,021,899 | 69,643 | 96% | 54,342 | 37 | 662 |
| 2026-11-24 | no-methodology | 3 | 171,071 | 19,519 | 91% | 16,601 | 11 | 176 |
| 2026-11-24 | todo-skills | 17 | 1,755,931 | 72,653 | 97% | 35,875 | 38 | 588 |
| 2026-11-24 | todo-skills-existing | 5 | 3,519,573 | 84,565 | 97% | 44,376 | 65 | 597 |
| 2026-11-24 | todo-skills-flow | 3 | 3,421,081 | 95,776 | 97% | 50,191 | 55 | 633 |
| 2026-11-25 | todo-skills | 4 | 1,304,700 | 64,508 | 95% | 32,377 | 25 | 437 |
| 2026-11-25 | todo-skills-existing | 16 | 1,676,295 | 64,425 | 95% | 30,774 | 34 | 451 |
<!-- tokens:end -->

Input tokens include the cached part, so the uncached input of a run is the difference. The todo-skills rows are different versions of the skill text, and the rows of 2026-11-13 and 2026-11-14 ran only that arm and its variant `todo-skills-flow`. The `2026-11-14 01h` row is [the batched-steps test](pi-glm-2026-11-14-batched-steps/summary.md): the same median model calls as the row before it. The `2026-11-14 22h` row and the `todo-skills-flow` row are the baseline and the candidate of [the helper-script test](pi-glm-2026-11-15-flow-helper/summary.md).

## Reading it

- **The 25 times is real, and mostly cache.** todo-skills reads 1.04M input tokens against 41K for no methodology (25 times), but 95% of that is cached input. The uncached input is 47K against 2.8K (17 times) and the output is 18.3K against 1.7K (11 times). Output and uncached input are the parts a provider normally charges at full rate, so the cost ratio depends on the price of each part and is not 25 times.
- **The lean baseline is 8 times cheaper.** It reads 124K input tokens (uncached 5.9K) and writes 3.7K, in 13 calls instead of 29. It also does much less: no backlog, no branches, no drain.
- **A benchmark cell pays for setup that a project pays once.** The todo-skills arm starts from an empty repository and runs todo-init and todo-add before it fixes anything. In a project that already has a backlog, only the per-task part recurs. The batch of 2026-11-24 to 26 compared that difference with the variant `todo-skills-existing`: see [the summary](benchmark-initialised-project-2026-11-26/summary.md).
- **Outcomes differ little.** Final outcome PASS: lean-baseline 15 of 18, no-methodology 16 of 18, todo-skills 15 of 20 (two of the five misses were INFRA_ERROR); every run of every later row ended in PASS (122 of 122 from 2026-11-13 on, the 51 runs of the batch of 2026-11-24 to 26 among them). With three runs per cell the benchmark does not separate the arms on correctness, so this page does not claim that more tokens bought more correctness.

## Where the tokens go (measured locally)

Six runs of the todo-skills arm on 2026-11-13 (one per scenario, the text after TASK-110), read from the raw pi session logs. Counts only; no tool output is quoted.

- **Every model call re-sends the whole context.** One run (the 1-bugfix scenario) made 26 calls; its context grew from about 6K to 42K tokens, an average of about 34K per call. Input tokens are therefore roughly the number of calls times the average context, not the size of the skill text.
- **The skills are resident.** The skill files read in calls 2 to 4 of that run were about 18K tokens, re-sent on about 21 later calls: roughly 40% of that run's input. TASK-110 cut about 1K tokens from them, about 3% of the input, which one run per cell cannot show.
- **Activity, over the six runs** (162 calls, share of input tokens taken by the calls that do it; a call that does two things is left out, so the shares add to less than 100%):

| Activity | Calls | Share of input tokens |
|---|---|---|
| Git commands | 43 | 32% |
| Reading and editing TODO.md and CHANGELOG.md | 31 | 22% |
| Test commands | 24 | 17% |
| Other work (reading and editing code) | 33 | 16% |
| Final message | 6 | 5% |
| Reading skill files | 10 | 3% |

- **The ceremony is the largest part.** Git and the two backlog files are 74 of the 162 calls, about 53% of the input and about 41% of the output tokens.
- **Setup.** The calls before the first branch (reading the init and add skills, writing the backlog) are a median 30% of a run's input (28% to 33% in five runs; the sixth stopped to ask a question after 9 calls).
- **What a fix could save.** If the git and backlog-file calls shrank to four per node, the logs predict 37% to 50% fewer input tokens in five of the six runs. That is an upper estimate: some of those calls read state and cannot be removed. TASK-120 tested the cheapest fix, wording that allows chained commands, on 18 fresh runs: the median stayed at 31 calls, so wording alone did not capture it ([summary](pi-glm-2026-11-14-batched-steps/summary.md)). FEAT-129 then tested a helper script that makes those writes in one call each, on 18 more runs: the calls that only write git or backlog state fell from a median of 10 to 3 per run, but the model calls of a run fell only from 29 to 26 and the uncached input plus output did not fall, because setup is half of a small run and the agent reads the script before it uses it. The helper missed the targets set for it and was merged as an optional script all the same, by the owner's decision ([summary](pi-glm-2026-11-15-flow-helper/summary.md)).

## Limits

One agent and model, provisional isolation, small samples, and todo-skills rows from several versions of the skills (2026-11-12, 2026-11-13, 2026-11-14 and the text of the batch of 2026-11-24 to 26). The locally measured part is six runs. The benchmark counts tokens the CLI reports, which is not a bill.
