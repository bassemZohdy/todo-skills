# pi + GLM 5.3: second reading, fixes and reruns (2026-11-13)

> Only this summary is published. The evidence of these runs (prompts, session logs, Git state, checksums) stays with the maintainer; paths below that point into it no longer exist in the repository.

The 2026-11-12 batch ([summary](../pi-glm-2026-11-12/summary.md)) fixed eight wording gaps and left the rest of its 33 trial reports unread in detail. This batch read every ambiguity section of those reports, changed the skill text in four pull requests, and reran fresh [pi](https://github.com/badlogic/pi-mono) agents on each version of the new text. Same setup as the day before: pi 1.5.2, provider `zai`, model `glm-5.3`, default thinking level, Windows 11 with Git Bash, Node 24, Java 25, the same isolation flags, the same prompts (`tests/trials/prompt.sh`).

**What this is not.** One model family, one host, one run per scenario and text version. The trial assertions ran **unisolated** (`TRIAL_WINDOWS_ISOLATION=0`), so these results are not equal to the isolated Windows batches. No Claude Code or Codex run was made on the new text. The reruns show that the new text does not break the lifecycle and that the reported ambiguities changed; they are not a controlled A/B test.

## What changed in the repository

| Change | Pull request | In short |
|---|---|---|
| FIX-098 | 35 | About 50 small wording edits in the nine skills and five reference files, each for a gap seen in more than one report or a contradiction. One behaviour change: the bare-claim check diffs with three dots |
| FIX-099 | 36 | The optional reviews qualify a root for "public interface" only when it changes an existing one, not when it adds one (issue 31) |
| FEAT-100 | 37 | A node adopts uncommitted work when the request or the task line states it is that node's unfinished work (issue 30); trial scenarios `leftover-work` and `dirty-tree` |
| FIX-102 | 38 | A parent's integration step gets the start (`[/]`, `State:`, start commit) like any node |
| TASK-101 | this one | Trial scratch repos keep LF line endings, fixture branch names follow the slug rule, this evidence |

## Skill text versions

The text changed between batches because each batch's reports were read before the next one. Every result names its version. T1 to T3 were working commits that were squashed into the pull requests; T3 is the text that pull requests 35 to 37 merged, T4 is `main` after pull request 38.

| | Text | Runs |
|---|---|---|
| T1 | `main` at `e912f63` + the first wording of FIX-098, FIX-099 and FEAT-100 | 31 trial scenarios; 8 benchmark cells |
| T2 | T1 + round two: the drift and review rules say that they differ on additions, leftover work needs more than a touched file and keeps red-first, `Checked:` examples, the `from` branch, the CHANGELOG heading, `todo-status` totals, the conflict rule ("already published"). Fixture branches renamed | 17 trial scenarios; 3 benchmark cells |
| T3 | T2 + round three: one report at the end of an interrupted merge and where that bullet applies, the early-stop report, an empty tree, one run when `Done when` and the regression are the same command, `Red:` for a missing-symbol error | 9 trial scenarios |
| T4 | T3 + the FIX-102 sentence | 4 trial runs (`ts-lifecycle` and `java-lifecycle`, twice each) |

## Trial results

`runs.csv` has one row per run (outcome, exit codes, tool calls, pi version, verifier mode, checksums of the prompt and of the session log); `runs/<text>-<scenario>/` holds the agent's report, the assertion log and the Git state.

| Text | Scenarios | Result |
|---|---|---|
| T1 | all 31 (the 29 of the day before, `leftover-work`, `dirty-tree`) | 31 PASS |
| T2 | `leftover-work`, `dirty-tree`, `interrupted-merge`, `refresh-from-base`, `claimed-elsewhere`, `race-claim-conflict`, `race-claim-benign`, `blocked-sibling`, `happy-path`, `no-git`, `monorepo`, `status-readonly`, `team-claim`, `ts-baseline-red`, `ts-interrupted`, `java-lifecycle`, `update-block` | 17 PASS |
| T3 | `java-lifecycle`, `ts-lifecycle`, `lanes`, `multi-module`, `interrupted-merge`, `java-interrupted`, `java-baseline-red`, `baseline-red`, `happy-path` | 9 PASS |
| T4 | `ts-lifecycle` and `java-lifecycle`, two runs each | 4 PASS; all four made the root's start commit (`chore(backlog): start FEAT-001`) |

`lanes` and `multi-module` ran sequentially again (pi has no subagent tool). `blocked-sibling`, the one failure of the day before, passed on T1 and T2 with LF scratch repos; the CRLF rewrite that caused it did not come up again in any report.

**The two new scenarios.** `leftover-work` (an unfinished `subtract` on main, and a request that says so) passed on T1 and T2: the agent carried the change into the node, wrote the missing test red first, finished and merged. `dirty-tree` (an unexplained edit in the file the task names) passed on T1 and T2: the agent stopped at the ready check and offered commit, stash or `--worktree`. The T1 report called the leftover-work wording "the pivotal judgment of this run" because the edit was in the file the task names; T2 says that a touched file is not enough, and its report applied that sentence.

## Benchmark, `todo-skills` arm only

`benchmark/T1` and `benchmark/T2` hold `results.csv` and, per cell, the report, the verifier log and the usage. Isolation is `provisional`, as before. The other two arms were not rerun.

| Scenario | 2026-11-12 | T1 | T2 |
|---|---|---|---|
| 1-bugfix | 3/3 | 1/1 | |
| 2-api-feature | 3/3 | 1/1 | |
| 3-security-token | 3/3 | 1/1 | |
| 4-multi-module | 3/3 | 1/1 | |
| 5-interrupted | **0/3** | **3/3** | **3/3** |
| 6-ambiguous | 3/3 | 1/1 | |

- **`5-interrupted` is the one cell that changed, by design:** the requirement says the uncommitted change is the interrupted session's work to finish, which is what the leftover-work rule asks for. Its cost went up with it, from a median of 341k input tokens (a stop at the ready check) to 1,138k (T1) and 951k (T2): the node is now built.
- **The other cells are one run each** and only show nothing broke. `6-ambiguous` still stopped and asked.
- **The review reference was loaded in 1 of 8 T1 cells** (`3-security-token`, which qualifies); on 2026-11-12 it was loaded in 8 of 15 passing cells, because an added function qualified a root.

## What the reports say now

Counted in the ambiguity sections of the reports: by reading for 2026-11-12 and T1, by pattern match and then reading the matches for T2 and T3.

| Topic | 2026-11-12 (33 reports) | T1 (31) | T2 (17) | T3 (9) |
|---|---|---|---|---|
| Where the baseline runs for a node whose branch does not exist yet | 12 | 0 | 0 | 0 |
| "The active node" before a node is selected | 4 | 0 | 0 | 0 |
| "If the core is not a skill" | 4 | 0 | 0 | 0 |
| `State:` to "replace" on a node that has none | 3 | 0 | 0 | 0 |
| I5 against a `From:` reference to a drained ID | 2 | 0 | 0 | 0 |
| CRLF defeated an exact-match edit of `TODO.md` | 2 | 0 | 0 | 0 |
| Whether an added function qualifies a root for the root review, and what "offer" means without a user | 8, resolved in three ways | 0 | 0 | 0 |
| The drift rule counts an added interface and the review rule does not | n/a | 7, all resolved the same way | 3 | 2 |
| Fixture branch names that do not follow the slug rule | 3 | 2 | 0 | 0 |

The second-to-last row is the cost of FIX-099: two rules about a "public interface" now differ on purpose, and agents notice. All of them applied each rule where it stands (run the drift search, do not offer the review); from T2 on the text says so itself, and one of the three T2 reports lists it under "not counted as ambiguities".

## Cost: where the tokens of the skills arm go

The 2026-11-12 summary measured about 25 times the control's input tokens and left open how much of that is skill text. Measured here from pi's session logs of the 15 passing `todo-skills` cells of that day:

- The skill files are read **once** per run: a median of 68k characters (about 17k tokens) for `todo-init`, `todo-add`, `todo-continue`, the core, `git-flow.md` and `verification.md`. All other tool results together are a median of 22k characters.
- A run makes a median of **29 model calls** (all 18 cells; the control arm 6, `lean-baseline` 13.5). The context is about 6k tokens at the first call and about 49k at the last; the input total is that context re-sent on every call (95% served from cache).
- So the multiplier is about five times the calls of the control arm at about five times the input per call (a median of 34k tokens per call against 7k). The skill text is about half of that 34k, so both levers count: what is read, and how many calls a node takes.

**Decision record** (asked for by `tests/benchmark/README.md` once real results exist; proposals only, nothing here is implemented):

1. On these six small tasks `lean-baseline` matched `todo-skills` on hidden-test outcomes (15/18 each on 2026-11-12, before FEAT-100) at about an eighth of the input tokens. What the hidden tests do not measure (a green history, traceability, a drained changelog, resumability) is what the extra calls buy.
2. Candidates for an optional "light" path for a `low` leaf root, to be decided by the maintainer and tested with trials before any change: fold the start commit into the claim commit (one commit and one status round fewer), skip the refresh when the base has not moved since the claim, and let `todo-init` and `todo-add` share one read of the core in a single session.
3. Not candidates: the baseline, red-first, the `Done when` plus regression gate and the drain. They are what the trials assert.

## Seen, not changed

One or two reports each, every one resolved correctly by the agent: `next: read docs` is written at the start even when a node has no docs and then looks stale (several reports on T2 and T3, all followed the new sentence in step 9); what "the next workable node" is after a red-baseline stop; the format of a failing test id when a runner prints two forms; the commit scope for a Java package; where `/todo-status` counts "roots open"; the `Tests:` offer when a README names the command without a `Tests:` marker; the wording of the CHANGELOG heading rule added in T2 ("also between it and its first entry" reads oddly; both agents produced the intended layout); "expect conflicts for every root after the first" in `lanes.md`, which did not happen for the first refresh.

## Harness changes

- `tests/trials/setup.sh` sets `core.autocrlf false` in every scratch repository (and in the `team-claim` peer clone). On Git for Windows the first branch switch used to rewrite `TODO.md` with CRLF. The selftest fails a setup that leaves it on.
- Fixture branches are named by the slug rule (`todo/FEAT-001-add-subtract-multiply-calc`, `todo/FEAT-001.1-add-subtract-test`, `todo/FEAT-001-add-subtract-function-calc`). Three reports of the day before and two on T1 had pointed out that the old names contradicted the rule the agent was following.
- `leftover-work` and `dirty-tree` are in `setup.sh`, `prompt.sh`, `assert.sh` and the selftest (an untouched setup fails both).

## Evidence integrity

This folder holds a subset of each run: the report, the assertion log and the Git state per trial run, the report, verifier log and usage per benchmark cell, and the two result tables. The raw pi session logs (72 files, about 3 MB compressed) are **not** in the repository, because TASK-085 is about what an install clones; `SESSIONS.sha256` lists their checksums and `runs.csv` repeats them per run, so a copy published later can be checked. Before anything was copied, the full archive was scanned for the values of every environment variable whose name contains KEY, TOKEN, SECRET or PASSWORD, for the Windows profile name and for mail addresses at the common providers; the profile name in paths was replaced by `<user>` (254 files) and no secret or mail address was found. `SHA256SUMS` covers the files as archived, after that replacement.

## Not done

- No second model and no second host; no Claude Code or Codex run on the new text.
- No isolated verifier (same reason as the day before).
- One run per scenario and text version, except the two lifecycle scenarios on T4 and `5-interrupted`.
- The other two benchmark arms were not rerun, so the 2026-11-12 totals are not updated.
- The light path of the decision record is a proposal; nothing was measured for it.

## Closed without being done

Three backlog tasks that cite this summary were removed from `TODO.md` on 2026-11-13 without being implemented. The claim commit of TASK-112 gave short reasons; these are the accurate ones. Each can be put back with `/todo-add`.

- **TASK-109** (start a node with no `Ref` on `next: build`): dropped on the recommendation of the maintainer's assistant; the owner was told and asked for the remaining tasks to be completed, which is not an explicit yes. The seven reports that found `next: read docs` stale all followed the sentence added to step 9 by FIX-098, and "no governing doc" cannot be known at step 5, so the rule as written would have changed nothing in the fixtures (they have a README).
- **FEAT-111** (fold the start commit into the claim commit, skip the refresh): as written it would put `[/]` on the base through the claim's fast-forward. A sound variant, no separate start commit for a `low` leaf root, would save about 2 of the 28 model calls of a run, but resume and interrupted-work detection read the `[/]`, `baseline` and `next:` that the start commit writes, and about ten trial scenarios use that commit as their stop point or assert it. The saving was judged too small for that change; it was not tried.
- **TASK-085** (slim what an install clones): `/plugin marketplace add` does clone the whole repository, so the premise holds. The cost is small: a shallow clone of the public repository takes about 3 seconds and checks out 24 MB in 3,049 files, 2,796 of them under `docs/evals`. Moving them to another branch would touch eight trial tests and the documentation links for that; the history keeps the objects either way. Not done; the owner never picked a target.
