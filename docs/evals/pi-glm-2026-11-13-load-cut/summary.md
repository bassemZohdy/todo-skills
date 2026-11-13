# pi + GLM 5.3: the load cut of TASK-110 (2026-11-13)

TASK-110 moved the rarely used branches of `/todo-continue` out of the text every run loads and into reference files that are read on demand. This batch checks, with fresh agents, that nothing was lost on the way. Same agent, model and host as the batches before it: pi 1.5.2, `glm-5.3` (z.ai), Windows 11 with Git Bash, unisolated verifier.

## Skill text versions

| | Text | Runs |
|---|---|---|
| TB | `main` at `f8c1f33`, before the cut | 3 trial runs (the three scenarios of TASK-113) |
| T5 | The TASK-110 branch at `419a7fc` | 34 trial runs; 6 benchmark cells |

T1 in the tables below is the first text of [the batch earlier that day](../pi-glm-2026-11-13/summary.md).

## What the cut is

| Command | Bytes loaded before | After | Change |
|---|---|---|---|
| `/todo-continue` | 52,896 | 46,511 | -12% |
| `/todo-continue --lane` | 57,828 | 51,445 | -11% |
| `/todo-add` | 37,275 | 30,387 | -18% |
| `/todo-plan` | 42,798 | 35,887 | -16% |
| `/todo` (the core, loaded by every command) | 23,437 | 21,966 | -6% |

Four reference files are new, each read only when its pointer applies: `failures.md` (a failed verification run, blocking, a `Done when` that cannot run), `plan-step.md` (the `--plan` stop and breaking a node down), `routing.md` (model routing) and `done-when.md` (how to write a `Done when`, loaded by `/todo-add` and `/todo-plan` in place of the whole `verification.md`). `tests/run.sh` pins every pointer and the rules behind it.

## Trial results

| Text | Scenarios | Result |
|---|---|---|
| T5 | The 31 scenarios of the earlier batch | 31 PASS, one fresh run each |
| T5 | `plan-stop`, `decompose`, `regress-block` (new, TASK-113) | 3 PASS |
| TB | `plan-stop`, `decompose`, `regress-block` | 3 PASS |

**Why three new scenarios.** After the 31 runs passed, the session logs showed that no agent had opened `failures.md`, `plan-step.md` or `routing.md`: none of the 31 scenarios reaches a `--plan` stop, a node with `next: decompose` or a failed verification. They could not show whether an agent follows the new pointers. TASK-113 added one scenario for each of the first three paths, and each was run on both texts.

| Scenario | TB | T5 | On T5 the agent read |
|---|---|---|---|
| `plan-stop` | PASS, 12 of 12 assertions | PASS, 12 of 12 | `plan-step.md` |
| `decompose` | PASS, 11 of 11 | PASS, 11 of 11 | `plan-step.md`, then `todo-add` and `done-when.md` |
| `regress-block` | PASS, 11 of 11 | PASS, 11 of 11 | `failures.md` |

In `regress-block` both agents wrote the test red first, made it green, saw the regression fail in the frozen-interface test, left that test alone and blocked the node after one attempt.

## Benchmark, `todo-skills` arm only

One run per scenario on T5: 6 of 6 PASS on the hidden tests (`benchmark/T5/results.csv`). No agent opened `failures.md`, `plan-step.md` or `routing.md`, which is the intent: these six tasks never need them.

## Cost: what the cut changed

Measured from pi's session logs, T1 (8 cells) against T5 (6 cells):

| Scenario | Model calls T1 | T5 | Input tokens T1 | T5 | Skill text read, characters T1 | T5 |
|---|---|---|---|---|---|---|
| 1-bugfix | 29 | 26 | 1,034,998 | 884,831 | 66,955 | 62,735 |
| 2-api-feature | 31 | 35 | 959,923 | 1,350,470 | 67,848 | 63,628 |
| 3-security-token | 28 | 32 | 1,083,725 | 1,472,013 | 69,954 | 66,627 |
| 4-multi-module | 35 | 33 | 1,405,114 | 1,341,185 | 67,848 | 63,628 |
| 5-interrupted (T1: three runs) | 29, 35, 33 | 27 | 1,034,971 to 1,152,403 | 897,461 | 66,955 to 67,901 | 66,627 |
| 6-ambiguous | 16 | 9 | 275,003 | 202,910 | 69,071 | 54,083 |

- **Skill text read per run:** a median of 67,848 characters on T1 and 63,628 on T5, 6% less. It is less than the 12% of the `/todo-continue` row because a benchmark run also loads `todo-init` and `todo-add`, and `todo-add` now reads `done-when.md`, which `/todo-continue` does not load.
- **Input tokens: no saving can be shown.** Four scenarios used fewer input tokens on T5 and two used more; the six-scenario total is 4% higher (6.15M against 5.90M, taking the middle T1 run of `5-interrupted`). The cut is about 4,000 characters, roughly 1,000 tokens, on each of about 30 calls: about 3% of a run. Three runs of one scenario on one text already differ by 11% (`5-interrupted` on T1), and the number of calls moves more than that (28 to 32 in `3-security-token`). One run per cell cannot resolve a 3% effect, and this summary does not claim one.
- The larger lever is unchanged: a run makes about 30 model calls and re-sends its context on each. That is the subject of FEAT-111.

## What the reports say on T5

Topics raised in two or more of the 31 trial reports, counted by reading each ambiguity section. None is about the moved text. Each agent resolved its topic in the way the scenario expects.

| Topic | Reports |
|---|---|
| Step 8, a test carries the ID in a comment "when `Done when` fixes the name": what "fixes" covers | 5 |
| The format of a failing test id against what the runner prints | 3 |
| The red-baseline stop suggests `/todo-add` without `--from`, step 11 words its suggestions with `--from` | 2 |
| `/todo-init`: whether a `Tests:` inside a sentence counts as the `Tests:` line | 3 |
| Step 9: which `State:` items to update during the run, and whether `next:` must advance | 3 |
| Interrupted merge: "switch to the parent's branch" when it is already checked out | 3 |
| `/todo-init` step 8: whether an empty tree alone triggers the planning questions | 2 |
| `/todo-release`: "feat followed by !" does not show the token | 2 |
| `next: read docs` on a node with nothing to read (TASK-109) | 2 |
| The trial prompt's "stop right after the start commit" against guardrail 7 (the prompt, not the skills) | 3 |

The six runs of the new scenarios add three topics on text that no agent had exercised before:

- **Breaking a node down:** nothing says what becomes of `State: next: decompose` afterwards. Both agents deleted the line. (TB and T5)
- **Breaking a node down:** "(on a `todo/` branch commit `chore(backlog): decompose <ID>`)" can be read as an order to commit on a `todo/` branch. The agent left the edit uncommitted on the base, which is what is meant. (Raised on T5; the TB text has the same parenthesis)
- **The plan stop:** "If a plan was proposed" does not say what makes a plan "proposed" (the commit or `next: plan proposed`), and whether the first `--plan` run also asks for approval. Both agents committed the plan and stopped. (TB and T5)
- **A blocked node:** whether a failure that the node's own required change causes is "outside the node" (block at once) or an attempt (up to three). Both agents blocked after one attempt. (TB and T5)

## Evidence integrity

This folder holds a subset of each run, as the folder of the earlier batch does: the report, the assertion log and the Git state per trial run, the report, verifier log and usage per benchmark cell, and the result tables. The raw pi session logs (43 files, 1.8 MB compressed) are not in the repository (TASK-085); `SESSIONS.sha256` lists their checksums and `runs.csv` repeats them per run. Before anything was copied, the full archive was scanned for the values of every environment variable whose name contains KEY, TOKEN, SECRET or PASSWORD, for the Windows profile name and for mail addresses at the common providers; the profile name in paths was replaced by `<user>` (154 files) and no secret or mail address was found. `SHA256SUMS` covers the files as archived, after that replacement.

The six runs of the new scenarios used the harness scripts of TASK-113 as they were committed afterwards (`7db0c18`), copied into two frozen worktrees: one at `main` before the cut (TB) and one at `419a7fc` (T5).

## Not done

- One run per scenario and text. The three new scenarios have two runs each in total, one per text.
- No second model and no second host; no Claude Code or Codex run (TASK-112).
- No isolated verifier.
- `routing.md` was not exercised: no scenario has a `Models:` line.
- "A `Done when` that cannot run" in `failures.md` was not exercised: no scenario has a command that fails before a test runs.
- The other two benchmark arms were not rerun.
