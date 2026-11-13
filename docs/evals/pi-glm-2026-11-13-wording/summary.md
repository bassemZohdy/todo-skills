# pi + GLM 5.3: FIX-114 and FIX-115 reruns (2026-11-13)

The first agent runs of the plan stop, the breakdown of a node and a blocked node (TASK-113, [the load-cut batch](../pi-glm-2026-11-13-load-cut/summary.md)) and the 31 trial reports on the cut text raised wording gaps. FIX-114 and FIX-115 closed them; fresh pi agents reran the scenarios each change touches. Same agent, model and host as the batches before it: pi 1.5.2, `glm-5.3`, Windows 11 with Git Bash, unisolated verifier. One run per scenario and text.

| Text | Change | Scenarios | Result |
|---|---|---|---|
| T6 | FIX-114, first wording | `plan-stop`, `decompose`, `regress-block` | 3 PASS |
| T7 | FIX-114, final text (the always-loaded `--plan` line and failure paragraph no longer promise what the reference files take back) | `plan-stop`, `regress-block` | 2 PASS |
| T8 | FIX-115, six sentences reworded | `interrupted-merge`, `java-interrupted`, `ts-interrupted`, `ci-github`, `ci-local`, `monorepo`, `release`, `release-ask`, `happy-path`, `refresh-from-base`, `no-git`, `multi-module` | 12 PASS |

The two clauses removed from FIX-115 after T8 (a stray colon in the breaking-change example and "and so fixes that name") changed no meaning and were checked by `bash tests/run.sh` only.

## What the reports said

FIX-114, from the load-cut batch: both agents on `plan-stop` asked whether the first `--plan` run also asks for approval and what makes a plan "proposed"; both on `decompose` asked what becomes of `next: decompose` and whether the children are committed; both on `regress-block` asked whether a failure caused by the node's own required change is "outside the node". On T6 and T7 none of the five reports asks those four questions again; the `regress-block` report on T7 still sets the attempt count next to the new outside-the-node rule and resolves it the intended way (blocked at once, attempts unused). Two new remarks came from the final text and were fixed in it: the always-loaded `--plan` line said "stop for approval" and the failure stub said "at most 3 attempts" while the reference files said otherwise.

FIX-115, topics in the ambiguity sections of the T5 trial reports and on T8:

| Topic | T5 reports | T8 reports |
|---|---|---|
| "fixes the name" for the test ID | 5 | 1, calls the clause convoluted (reworded afterwards) |
| "switch to the parent's branch" when it is checked out | 2 | 0 as a conflict; 1 asks which branch is "the parent's" for a child created from the root branch |
| Which `State:` items a run updates, and whether `next:` advances | 3 | 1, asks whether a clean run should still advance `next:` (unchanged on purpose: "need not") |
| A `Tests:` inside a sentence | 3 | 0 (both `/todo-init` agents applied the new wording) |
| Whether an empty tree alone starts the planning questions | 2 | 0 |
| The breaking-change marker | 2 | 1, the stray colon (removed afterwards) |

## Evidence integrity

A subset of each run, as in the batches before: report, assertion log and Git state. The 17 raw session logs (about 0.7 MB compressed) stay outside the repository (TASK-085); `SESSIONS.sha256` and `runs.csv` list their checksums. The full archive was scanned for the values of every environment variable whose name contains KEY, TOKEN, SECRET or PASSWORD, for the Windows profile name and for mail addresses at the common providers; the profile name in paths was replaced by `<user>` (67 files) and nothing else was found. `SHA256SUMS` covers the files as archived.

## Not done

- One run per scenario and text; no Claude Code or Codex run (TASK-112).
- `decompose` was not rerun on the final FIX-114 text (T7): only the always-loaded lines changed after T6, and neither concerns the breakdown.
- Of the FIX-115 sentences, the unchanged-on-purpose `next:` rule still draws a question from one agent.
