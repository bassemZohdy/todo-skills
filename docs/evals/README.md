# Evaluations

Only results are published here. A test run produces two things: the results (what ran, on which agent and platform, which scenarios passed or failed, and why) and the evidence behind them (prompts, session logs, Git state, checksums). The results are in this folder. The evidence is not, because it can name the host and the user and it is large; it stays with whoever ran the batch.

## What is here

| Path | What it holds |
|---|---|
| `<agent>-<date>/summary.md` | One summary per batch: what ran, the verdicts, the failures and their causes, and the limits of the run. It starts with a note that only the summary is published. |
| `<agent>-<date>/runs.csv` | One row per run, for the batches that have a table. |
| `benchmark/results/results.csv` | The published rows of the agent benchmark in [tests/benchmark](../../tests/benchmark/README.md). `evidence_sha256` identifies the evidence of a run, which only its holder can show. |
| `*.md` at this level | Write-ups of single findings and reviews, such as [the update review](update-review.md). |

## What that means for a reader

A published result is reported, not reproducible from this repository: nobody else can recompute it from the logs. Treat a result as the maintainer's record. To check a claim, run the harness again ([docs/trials.md](../trials.md), [tests/trials/README.md](../../tests/trials/README.md)). The evidence published before this rule is still in the Git history of this repository, before the commit titled "docs(evals): publish results only and remove the per-run evidence".

## Adding a batch

1. Run the batch with the harness, into a folder outside the repository.
2. Write `docs/evals/<agent>-<date>/summary.md`, starting with the line "Only this summary is published." from an existing summary. Add `runs.csv` if the batch has a table; for benchmark rows use `bash tests/benchmark/publish.sh add`.
3. Keep the evidence where it ran. Do not copy prompts, logs or Git bundles here.
4. `bash tests/run.sh` fails on any file here that is not Markdown or CSV, on a broken link, and on a summary without the note.
