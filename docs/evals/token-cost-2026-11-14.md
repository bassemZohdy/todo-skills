# Token cost of a todo-skills run (2026-11-14)

What the published benchmark rows say about tokens, and where a todo-skills run spends them. The table below is generated: `python3 tests/benchmark/tokens.py docs/evals/benchmark/results/results.csv` prints it, and `tests/run.sh` fails when this page and that output differ. Everything after the table that is marked *measured locally* came from raw session logs that are not published (see [the rule](README.md)); those numbers cannot be recomputed from this repository.

Scope: pi with GLM 5.3 on six small tasks, isolation `provisional`, 17 to 20 runs per row (three per scenario). No other agent has run the benchmark. No money figure is given: pricing for this model was not looked up, and no cost is computed here.

## Published rows

<!-- tokens:begin -->
| Date | Arm | Runs | Input tokens (median) | Uncached input (median) | Cached share of input | Output tokens (median) | Model calls (median) | Seconds (median) |
|---|---|---|---|---|---|---|---|---|
| 2026-11-12 | lean-baseline | 18 | 123,952 | 5,889 | 95% | 3,721 | 13 | 75 |
| 2026-11-12 | no-methodology | 18 | 41,237 | 2,769 | 92% | 1,689 | 6 | 26 |
| 2026-11-12 | todo-skills | 20 | 1,039,495 | 47,417 | 95% | 18,269 | 29 | 310 |
| 2026-11-13 | todo-skills | 17 | 1,034,971 | 52,929 | 94% | 18,644 | 31 | 402 |
| 2026-11-14 | todo-skills | 18 | 1,072,291 | 52,187 | 95% | 18,149 | 31 | 292 |
<!-- tokens:end -->

Input tokens include the cached part, so the uncached input of a run is the difference. The three todo-skills rows are different versions of the skill text, and the 2026-11-13 and 2026-11-14 rows ran only that arm. The 2026-11-14 row is [the batched-steps test](pi-glm-2026-11-14-batched-steps/summary.md): the same median model calls as the row before it.

## Reading it

- **The 25 times is real, and mostly cache.** todo-skills reads 1.04M input tokens against 41K for no methodology (25 times), but 95% of that is cached input. The uncached input is 47K against 2.8K (17 times) and the output is 18.3K against 1.7K (11 times). Output and uncached input are the parts a provider normally charges at full rate, so the cost ratio depends on the price of each part and is not 25 times.
- **The lean baseline is 8 times cheaper.** It reads 124K input tokens (uncached 5.9K) and writes 3.7K, in 13 calls instead of 29. It also does much less: no backlog, no branches, no drain.
- **A benchmark cell pays for setup that a project pays once.** The todo-skills arm starts from an empty repository and runs todo-init and todo-add before it fixes anything. In a project that already has a backlog, only the per-task part recurs.
- **Outcomes differ little.** Final outcome PASS: lean-baseline 15 of 18, no-methodology 16 of 18, todo-skills 15 of 20 (two of the five misses were INFRA_ERROR) and, on the later text, 17 of 17. With three runs per cell the benchmark does not separate the arms on correctness, so this page does not claim that more tokens bought more correctness.

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
- **What a fix could save.** If the git and backlog-file calls shrank to four per node, the logs predict 37% to 50% fewer input tokens in five of the six runs. That is an upper estimate: some of those calls read state and cannot be removed. TASK-120 tested the cheapest fix, wording that allows chained commands, on 18 fresh runs: the median stayed at 31 calls, so wording alone did not capture it ([summary](pi-glm-2026-11-14-batched-steps/summary.md)).

## Limits

One agent and model, provisional isolation, small samples, and todo-skills rows from two versions of the skills. The locally measured part is six runs. The benchmark counts tokens the CLI reports, which is not a bill.
