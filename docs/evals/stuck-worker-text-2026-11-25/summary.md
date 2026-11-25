# Codex and Claude Code on `stuck-loop` and `time-limit`, after the text change of FEAT-143.1 (2026-11-25)

> Only this summary is published, with its `runs.csv` of one row per run. The evidence of these runs (prompts, event streams, reports, Git state) stays with the maintainer. The event stream of Codex, where its command counts and token figures come from, holds no reasoning text; Claude Code's headless output holds only the final report, so its tool calls and tokens were not recorded.

The fresh runs of 2026-11-24 ([Codex](../codex-linux-2026-11-25/summary.md), [Claude Code](../claude-code-2026-11-25/summary.md)) showed three gaps in the stuck-worker text. Codex ended `stuck-loop` and `time-limit` with the node left `[/]`, no `Blocked:` line and no block commit. This page reports what the same two scenarios did on the text that closes the gaps, with two fresh runs of each scenario per agent: eight runs.

**All 8 runs are PASS with every assertion, and every run ended with `FEAT-001` `[!]`, a `Blocked:` line and the block commit.** Codex went from 0 of 2 runs to 4 of 4 on these two scenarios. Claude Code passed before and passes now, but both of its `time-limit` runs changed how they got there, and that change is probably an effect of the new text (see "What the runs show"). Two runs per cell is a small sample, and what this shows about the cause is limited (see "Limits").

## What changed in the text

All of it is in the commit of FEAT-143.1; the load rows of `docs/DEVELOPMENT.md` still fit (`/todo-continue` 47586 of 47600 bytes, the `--lane` row 52596 of 52600), because each added sentence was paid for by a cut in the files of those rows. Six cuts: the flags repeated in the description of `todo-continue`, the example of `/goal`, the clause "No tests here" of the interrupted merge, a clause of step 9, the words of the Documentation drift bullet on README instructions (now "README commands"), and the example in the commit scope rule of `git-flow.md` (its rule on `src/` stays).

1. **An impossible test at the red run.** Step 7 of `todo-continue` says that a test no change can pass is outside the node: read `reference/failures.md` and block at once, before any change. The paragraph "Test failures" and the first lines of `failures.md` name "a test cannot pass" as a reason to read it, and `failures.md` says the same for the red run and forbids ending with a question.
2. **An invocation ends in a verdict.** The core of `todo-continue` says a node marked `[/]` ends the run as `[x]` or `[!]`, or at a stop the text names; giving up (the third attempt or the time cap) is a block, never a question. `failures.md` says a worker that ends its own run by choice is not "a worker that stopped" (the resumable case).
3. **Own scripts and total time.** `verification.md` says scripts of the agent's own run under the time limit too and that one session's work on a node is at most 3 times its limit, noted with `date` at the start, then the node is blocked and the `Blocked:` line names the limit. Three times the limit stays under the four times that `/todo-status` uses for a stale claim.

A reviewer (Opus, fresh context; the Fable limit had not reset) found seven points in the first version, among them a cut that removed a rule and a loose wording of the cap, and all were fixed before the commit.

## Results

| Run | Agent | Outcome | Assertions | Wall seconds | `failures.md` read | How it ended |
|---|---|---|---|---|---|---|
| `codex-stuck-loop-1` | Codex | PASS | 11 of 11 | 87 | yes | Blocked at once after the red run, no code written |
| `codex-stuck-loop-2` | Codex | PASS | 11 of 11 | 63 | yes | Blocked at once after the red run, no code written |
| `codex-time-limit-1` | Codex | PASS | 12 of 12 | 293 | yes | An exact sieve written; blocked after 3 runs stopped at 60 s |
| `codex-time-limit-2` | Codex | PASS | 12 of 12 | 230 | yes | An exact sieve written; blocked after 2 runs stopped at 60 s |
| `claude-stuck-loop-1` | Claude Code | PASS | 11 of 11 | 49 | yes (its report cites it) | Blocked at once after the red run, no code written |
| `claude-stuck-loop-2` | Claude Code | PASS | 11 of 11 | 52 | yes (its report cites it) | Blocked at once after the red run, no code written |
| `claude-time-limit-1` | Claude Code | PASS | 12 of 12 | 62 | yes (its report cites it) | Blocked at once after the red run, no code written |
| `claude-time-limit-2` | Claude Code | PASS | 12 of 12 | 58 | yes (its report cites it) | Blocked at once after the red run, no code written |

Codex ran `codex-cli 0.167.0` in the Linux container with `gpt-6.1-terra`, Claude Code 2.1.331 with `claude-sonnet-5-5`, both from Windows 11 with Git Bash, assertions not isolated, from a frozen checkout of the repository at the commit that holds the change and its start commit (`5d7ef75`). The prompts are the ones of the earlier batches.

## Against the runs before the change

| Scenario | Codex before (1 run) | Codex now (2 runs) | Claude Code before (1 run) | Claude Code now (2 runs) |
|---|---|---|---|---|
| `stuck-loop` | Stopped with a question after the red run, `failures.md` never read, node `[/]` | Blocked at once, `failures.md` read, 2 of 2 | Read `failures.md` after the red run, blocked at once | The same, 2 of 2 |
| `time-limit` | Stopped after the red run, node `[/]`, no block | Wrote a sieve, hit the limit, blocked at the cap, 2 of 2 | Ran the whole `Done when` once (stopped at 60 s), then blocked on its own measurement | Blocked after the red run, no code and no run after a change, 2 of 2 |

## What the runs show, and what they do not

- **`stuck-loop`: gaps 1 and 2 are closed in these runs.** All four runs read `failures.md` after the red run (the Codex run of 2026-11-24 never opened it), proved the contradiction (ten steps of at most 8 points cannot reach 100) and blocked at once with no code written. The reasoning is not logged, so whether the new step 7 sentence or the wider load trigger sent the Codex agents to the file is not shown.
- **Codex `time-limit`: the node now ends in a verdict, which is gap 2; gap 3 is not shown acting.** Before, the agent stopped after the red run without writing code. Now both runs wrote an exact sieve, ran the acceptance test, saw it stopped at 60 seconds and blocked with `[!]`. Reading `failures.md` is not new here: the run of 2026-11-24 read it after the red run too. Both `Blocked:` lines say "session time limit of 3 minutes", the cap of 3 times the one-minute limit, but the clocks do not show the cap reached. Run 1 read `date -u` once, at the branch, and blocked about 253 seconds later, after its third run stopped at 60 seconds, which is also the third attempt under the older rule; its "exhausted" was not measured. Run 2 read it again before the block and blocked at about 160 seconds, after 2 stopped runs and before the cap. Run 1 ran its baseline and red run with no limit and the three later runs under a bare `timeout 60s`, not the helper `.todo/todo-limit.sh` that the project holds; run 2 used the helper throughout. That departure from `verification.md` is not corrected here.
- **Claude Code `time-limit`: a change in behaviour that the new text probably caused.** The run of 2026-11-24 wrote an exact sieve, measured it once under the helper and then blocked. Both runs now blocked after the red run with no code and no run after a change, because they judged that no method counts twin primes up to 4 * 10^13 in 60 seconds ("no known sublinear algorithm"). Both reports say they measured nothing, and both quote the new sentence of `failures.md` and the new step 7 sentence as the reason to block before any change. `failures.md` allows a block at once only for a bound that follows from the task line, the tests and the project, and says a target the node's code merely missed uses the attempts; "I know of no faster algorithm" is not a bound. The assertions accept this ending, as they did the earlier one. The new step 7 sentence names "an arithmetic bound" as an example of a test no change can pass, and two agents took an estimate for one. That is a self-report and two runs, so it is a likely side effect and not a measured one; the text was not changed again, because the load rows have 14 and 4 bytes left.
- **Not checked:** the other ten scenarios on the changed text. This change cut or shortened six places elsewhere in `todo-continue` and `git-flow.md`; `tests/run.sh` and the agent-free trial tests pass, and no agent was run on the other scenarios.

## Limits

- The runs shared one host and overlapped: the two Codex `time-limit` runs ran their sieves at the same time, and each Claude Code run overlapped another run. The counts of stopped runs and the wall seconds were measured under that contention; no outcome depended on it.
- `file_changes` in `runs.csv` counts file-change items of the Codex stream, not files. `read_failures_md` is `cited in report` for Claude Code where its report cites the file; its tool calls were not recorded.
- Two runs per scenario and agent, one model per agent, one host. A pass here does not show that every run would end in a block; the 2026-11-24 failures were one run each too.
- The verifier ran without isolation on this host (the column `verifier` of `runs.csv`).
- Reasoning is not logged by either agent, so why a run stopped or blocked is read from commands, commits and reports.
- Claude Code's tool calls, file changes and tokens were not recorded; the wall seconds are from file times of the run folder, rounded.
- The guards of FEAT-134 that these scenarios are built for: stopped runs were reached in the two Codex `time-limit` runs, a block as outside the node in the other six; the loop guard's counting of failed partial runs and the cap of 3 limits were not shown acting.
