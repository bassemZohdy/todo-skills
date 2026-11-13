# Agent benchmark

The benchmark measures whether a methodology pays for itself. It runs the same six requirements under each of three
methodology "arms" and compares verified outcomes, tokens, turns and time. The harness doesn't depend on any arm, and
it has been run with one real agent so far (pi with GLM 5.3, [results](../pi-glm-2026-11-12/summary.md#benchmark-first-real-run-of-docsevalsbenchmark)); [`results/results.csv`](results/results.csv) holds those runs
(see "Published results" and "Status").

## Layout

| Path | What it is |
|---|---|
| `scenarios/<id>/requirement.md` | The requirement text. Every arm receives exactly this text. |
| `scenarios/<id>/repo/` | The starting repository: Python standard library and `unittest`, with a few passing tests. |
| `scenarios/<id>/prepare.sh` | Optional. The controller runs it after the start commit. Scenario 5 uses it to leave an interrupted session behind. |
| `hidden/<id>/accept.sh`, `hidden/<id>/test_accept.py`, `hidden/lib.sh` | Hidden acceptance tests. The verifier runs them; they never enter the agent's repository. |
| `arms/<name>/arm.md`, `arms/<name>/setup.sh` | A methodology: instructions placed before the requirement, plus an optional setup script run before the start commit. |
| `agents/codex.sh`, `agents/claude.sh`, `agents/pi.sh` | Adapters. Each starts one fresh agent process with `<repo> <prompt-file> <report-file>`. |
| `run.sh` | Runner: one run of one arm on one scenario. |
| `verify.sh` | Trusted verifier. |
| `usage.sh` | Reads token usage from the CLI's own output. |
| `summarize.sh` | Statistics per arm and scenario. |
| `publish.sh` | Publishes the runs of a table into `results/results.csv` and checks every published row against its evidence. |
| `results/results.csv`, `results/sources.csv` | The published real runs, and for each the table it came from and the hash `run.sh` recorded. |

### Scenarios

| # | Scenario | What PASS requires (hidden checks) |
|---|---|---|
| 1 | `1-bugfix`: double discount | Correct totals, the agent's tests pass, and at least one of its tests fails on the original code (a real regression test). |
| 2 | `2-api-feature`: `GET /items/<id>` | 200, 404 and 400 cases, `GET /items` unchanged, and the agent's tests pass and grew. |
| 3 | `3-security-token`: token `verify()` | Valid, expired, tampered, wrong-secret and malformed tokens each handled; `compare_digest`; the agent's tests fail against a verifier that accepts anything (negative tests exist). |
| 4 | `4-multi-module`: `inventory` + `orders` | All-or-nothing reservation through both packages, and the agent's tests pass and grew. |
| 5 | `5-interrupted`: an unfinished `slugify` | A WIP commit plus an uncommitted change; the function is finished and the WIP commit is still on a branch. |
| 6 | `6-ambiguous`: "give loyal customers a discount" | Nothing under `billing/` changed on any branch or in the tree, and the final report asks what "loyal" means. The report check (a question mark plus the word "loyal") is a heuristic. |

### Arms

| Arm | What it is |
|---|---|
| `todo-skills` | The skills of this repository, installed by `setup.sh`. The agent works through todo-init, todo-add and todo-continue. |
| `lean-baseline` | A single-prompt method, rewritten from a summary of a third-party prompt ([its README](arms/lean-baseline/README.md)). |
| `no-methodology` | The control: the requirement and nothing else. |

To add a methodology, create a folder with an `arm.md` (and a `setup.sh` if the arm needs one) anywhere and pass its path.
Nothing in another methodology's repository needs to change.

## Running it

From the repository root, on a disposable machine. The verifier runs code the agent wrote; `BENCH_VERIFY_WRAP` can wrap
it in a sandbox. Use a logged-in agent CLI:

```bash
export BENCH_AGENT=docs/evals/benchmark/agents/codex.sh BENCH_MODEL=<model>    # or agents/claude.sh
export BENCH_HIDDEN=/path/outside/the/agents/reach/hidden                    # a copy of docs/evals/benchmark/hidden
for rep in 1 2 3; do
  for arm in todo-skills lean-baseline no-methodology; do
    for s in 1-bugfix 2-api-feature 3-security-token 4-multi-module 5-interrupted 6-ambiguous; do
      bash docs/evals/benchmark/run.sh docs/evals/benchmark/arms/$arm $s ~/bench-runs
    done
  done
done
bash docs/evals/benchmark/summarize.sh ~/bench-runs/results.csv
```

Keep `~/bench-runs` outside the agent's writable area and outside the temporary folder (see
`tests/trials/codex-exec.sh` for why). To publish results, see "Published results" below. Never write rows by hand.

## What each run records

For every run, `<runs>/<arm>/<scenario>/<run-id>/` holds:

- `versions.txt`: the agent CLI and model version, the harness commit, git, bash, Python and the OS.
- `start-sha.txt` and `repo.bundle`: the start commit, and the whole repository afterwards.
- `hidden.sha256`: the hidden tests and verifier, hashed before the agent starts.
- `attempt-<n>/`, one folder per agent invocation: `prompt.txt` (the exact prompt), `session.log`, `report.txt` (the final message), `agent-exit.txt`, `duration.txt`, `usage.txt`, `diff.patch` (everything the agent changed, committed or not), `verifier.log`, `verifier-exit.txt` and `outcome.txt`.
- `first-outcome.txt` and `outcome.txt`: the first attempt and the final result, kept apart.
- `SHA256SUMS`: every evidence file except the live `repo/` folder, which `repo.bundle` covers.

It also appends one row to `<runs>/results.csv`. The columns are: run id, date, arm, scenario, agent, agent version,
model, isolation, first and final outcome, attempts, agent and verifier exit codes, duration, input/output/cached tokens,
LLM calls, subagent calls, the SHA-256 of the run's `SHA256SUMS`, and the evidence folder.

- **Tokens** come only from the CLI's own usage output (`usage.sh` documents the fields per CLI). Otherwise the value is `unavailable`. Nothing is estimated.
- **LLM calls** are the turns the CLI reports: Codex `turn.completed` events, Claude Code `num_turns`. They are not raw API requests. Subagent calls are Claude Code's `subagent_stats.spawned`, and `unavailable` for Codex.
- **Cost** isn't recorded. If you compute one from the token columns, label it "computed from published pricing" and give the price date.

## Outcomes and integrity

| Outcome | When |
|---|---|
| PASS / FAIL | The verifier's hidden checks passed or failed. |
| INFRA_ERROR | The agent CLI exited non-zero or timed out, the verifier couldn't run, or the hidden tests or verifier changed during the run (compared against `hidden.sha256`). |
| UNVERIFIED | The agent produced no report and no output, so there was nothing to score. |

- The verifier scores a copy of the agent's repository, so edited visible tests and planted test files don't count.
- Changing the hidden tests or the verifier is caught by the hash comparison. The result is INFRA_ERROR, never PASS.
- A retry (`BENCH_ATTEMPTS`) runs only after a FAIL and is a new process. The first attempt's outcome stays in `first_outcome`.

**Isolation.** A run is labelled `provisional` unless `BENCH_ISOLATION=isolated` is set, and you set that only when the agent
provably can't read `BENCH_HIDDEN`, this folder or the runs folder, nor write outside its repository. On native Windows,
Codex's unelevated sandbox can't deny reads, so Windows Codex runs are provisional. Note that
`tests/trials/benchmark-solutions/` holds reference solutions for the self-test; an isolated run must deny reads of the
whole harness repository.

## Protocol

- At least **3 fresh-context repetitions** per arm and scenario. Each run is a new agent process in a new repository.
- Report the **median, mean and spread** (`summarize.sh`), the first-attempt and final PASS counts, and the outcomes. Make no claim of a significant difference from samples this small.
- Report INFRA_ERROR and UNVERIFIED runs; never drop them. An arm whose runs are mostly INFRA_ERROR measures the environment, not the method.
- **Decision record.** When real results exist and `lean-baseline` matches `todo-skills` on verified outcomes at materially lower tokens, write that down in `docs/evals/` and *propose* which todo-skills steps could become optional. Don't implement that from the benchmark alone.

## Published results

`results/results.csv` holds real runs only, and `tests/trials/test-benchmark-harness.sh` fails when a row's evidence is missing or changed, or when an arm and a scenario have no scored row.

```bash
bash docs/evals/benchmark/publish.sh add <runs>/results.csv <evidence root>   # every run of the table, or none
bash docs/evals/benchmark/publish.sh check --coverage
```

- **Evidence.** A run's full evidence folder holds the agent's session and a bundle of its repository, which can name the host and the user. What is committed is a reviewed subset (the report, the verifier log, the usage), kept in the dated folder of its batch under `docs/evals/`. `<evidence root>` is that folder, written relative to `results/`. Copying a whole runs folder here is possible too, but check it for secrets and personal data first.
- **Hashes.** A published row is the run's own row with `evidence_dir` pointing at the published folder and `evidence_sha256` computed from that folder's file listing, so a published file that changes or goes missing fails the check. The hash `run.sh` recorded for the complete run is kept in `results/sources.csv` with the table the row came from.
- **What is in it now** (67 rows, all pi with GLM 5.3, isolation `provisional`): the 56 rows of 2026-11-12 (three arms, three runs per cell, two of them INFRA_ERROR) and the 11 rows of 2026-11-13 (`todo-skills` arm only, on the revised skill text). The `todo-skills` rows therefore mix two versions of the skills: `5-interrupted` is 0 of 3 on the first and 6 of 6 on the second. Summarize a source table, not the published one, when comparing arms.

## Status

The harness is tested with a stub agent: `bash tests/trials/test-benchmark-harness.sh` (CI runs it). The first real run
was made on 2026-11-12 with pi and GLM 5.3 (`agents/pi.sh`, 3 runs per cell, isolation `provisional`; every cell is in
`docs/evals/pi-glm-2026-11-12/benchmark/results.csv`). On 2026-11-13 only the `todo-skills` arm was rerun, on the text with the leftover-work rule (FEAT-100): `5-interrupted`, which it had failed 3 of 3, passed 6 of 6; the decision record asked for above is in `docs/evals/pi-glm-2026-11-13/summary.md`. No Claude Code or Codex run has been made. In this repository's Windows environment, Codex's unelevated sandbox blocks the `.git` writes the
todo-skills arm needs (TASK-045: 6 of 8 lifecycle runs INFRA_ERROR), and a full protocol is 54 or more agent runs, which is
the maintainer's cost to choose. See [the update review](../update-review.md), Ruling 3.
