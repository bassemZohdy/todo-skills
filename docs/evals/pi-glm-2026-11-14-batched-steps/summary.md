# pi + GLM 5.3: batching the lifecycle steps in the skill text (2026-11-14)

> Only this summary is published. The evidence of these runs (prompts, session logs, Git state) stays with the maintainer; the run rows are in [the published table](../benchmark/results/results.csv).

TASK-120 asked whether wording alone can cut the model calls of a node. The git and backlog-file calls were 74 of 162 calls and about 53% of the input tokens in [the earlier measurement](../token-cost-2026-11-14.md). The tested text lets the agent chain the claim, the fast-forward of the base and the switch back into one `&&` command, and tells it not to read `TODO.md` or `CHANGELOG.md` back after an edit the tool reported as applied. Commit subjects and bodies were unchanged. Same agent, model and host as the batches before it: pi 1.5.2, `glm-5.3` (z.ai), Windows 11 with Git Bash, unisolated verifier.

## Result: no effect

The `todo-skills` arm on all six scenarios, three runs each (18 runs), against [the run of 2026-11-13](../pi-glm-2026-11-13-load-cut/summary.md) on the text before the change.

| Median of the runs | 2026-11-13 (17 runs) | Batched steps (18 runs) |
|---|---|---|
| Model calls | 31 | 31 |
| Input tokens | 1,034,971 | 1,072,291 |
| Uncached input tokens | 52,929 | 52,187 |
| Output tokens | 18,644 | 18,149 |
| Final outcome PASS | 17 of 17 | 18 of 18 |

The goal was a median below 31 calls. It is 31. Model calls per run, by scenario:

| Scenario | 2026-11-13 | Batched steps |
|---|---|---|
| 1-bugfix | 29, 26 | 29, 27, 31 |
| 2-api-feature | 31, 35 | 31, 33, 39 |
| 3-security-token | 28, 32 | 32, 30, 27 |
| 4-multi-module | 35, 33 | 46, 43, 38 |
| 5-interrupted | 35, 29, 33, 32, 31, 25, 27 | 33, 30, 31 |
| 6-ambiguous | 16, 9 | 10, 11, 9 |

Most scenarios are within the spread of the earlier runs. 4-multi-module used more calls, not fewer. The seconds fell (402 to 292, median), but this batch ran three repetitions in parallel, so the machine load differed and the change is not credited to the text.

## What it means

- Prose that allows a chained command did not change how the model batches: it still ran the claim, switch and merge steps as separate calls.
- Correctness did not change: 18 of 18 passed on the hidden tests.
- The text change was not merged. It added skill text for no measured gain.
- Shrinking the skill text was checked and dropped (TASK-123): a run reads 62.6 KB of skill files, but a safe cut is about 3.6 KB (6%), about 2% of uncached input, too small for 18 runs to show.
- One lever remains, untried: a helper script for claim and start, which would break the "Markdown only" rule of this project.

## Limits

One agent and model, provisional isolation, three runs per cell. A saving of 2 to 3 calls out of about 30 would not stand out from this spread, so the result is "no saving large enough to show", not "exactly zero".
