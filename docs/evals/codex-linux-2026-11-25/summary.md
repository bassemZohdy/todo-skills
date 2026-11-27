# Codex (gpt-6.1-terra) in Linux containers: twelve scenarios on the text of the stuck-worker rules (2026-11-24)

> Only this summary is published. The evidence of these runs (prompts, event streams, reports, Git state) stays with the maintainer. The event stream of Codex, where the command counts and token figures below come from, holds no reasoning text and no time per event.

FEAT-134 gave the skills rules against a stuck worker, FEAT-138 added scenarios built to reach them, and the [pi batches of 2026-11-23 and 2026-11-24](../pi-glm-2026-11-23-stuck-worker/summary.md) and the [Claude Code batch of 2026-11-24](../claude-code-2026-11-25/summary.md) ran them. Codex had last run the skill text on [2026-11-14](../codex-linux-2026-11-14/summary.md), at commit `6de470f`: 27 of the 34 scenarios of that day. This page reports twelve fresh Codex runs, one per scenario: the ten scenarios that batch did not have, and `happy-path` and `status-readonly`, which it ran on older text. The skill text changed under every scenario since `6de470f` (19 files of `plugin/skills`), so "added or changed since 2026-11-14" was read as these twelve, the same twelve as the Claude Code batch, so that the two can be set side by side. The other 32 scenarios of the current 44 were not rerun on the current text (see "Limits"). The question for each run: does the agent reach the rule its scenario is built for, and does it then do what the text says? For the six scenarios that are built for no such rule: does it do what the skill's own steps say?

**10 of the 12 runs are PASS with every assertion and 2 are FAIL: `time-limit` (10 of 12 assertions) and `stuck-loop` (9 of 11). Of the three scenarios built so that a finished node fails (`stuck-loop`, `loop-limit`, `time-limit`), one ended blocked at the third failed run after a change, and two ended with no verdict: after one red run and no code written, the agent stopped with the node still `[/]`, no `Blocked:` line and no block commit. For `stuck-loop` the cause is read here as a gap in the skill text and the agent's own choice in about equal parts; for `time-limit` mainly as the agent's choice, with a smaller share of the text. In the worker that is gone and the stale claim, what was decided matched the text in 3 of 3 runs (one departure in how, with no effect), and the other passing runs did what the skills say, with one commit trailer that states a review the stream does not show.** The evidence is thin: it is one run per scenario, so no count below is a rate; one agent family; the event stream holds no reasoning, so why an agent stopped cannot be read; the client's own instructions to the agent are not in the evidence; and the assertions ran unisolated (inferred from the script that ran them).

## The rules, in the words used here

The text is the one that the second pi batch and the Claude Code batch ran on. Each term is defined here once.

- A task is a **node** of the tree in `TODO.md`: `[ ]` open, `[/]` active, `[!]` blocked, `[x]` done. Its **`Done when`** line names the command that must pass before it is closed. The **regression** is the project's own test command. The **red run** is the first run of the node's test before any implementation.
- A **verification run** is a run of the whole `Done when` (every command of it, as written) after a change, once implementing started. When it fails, it is an **attempt**. The node's `State:` line counts attempts as `attempts n/3`, and the third failed attempt blocks the node. The red run is not an attempt, and neither is a rerun that only reproduces a failure or a script of the agent's own.
- The **loop guard** counts the failed partial runs made after a change (one command of `Done when`, one test id, a subset of its tests, the regression alone). Each of the 2nd, 4th and 8th run of a count without progress is an attempt too.
- A failure **outside the node** is one that no change within the task line and the tests the node creates can turn green: tests that contradict each other, a flaky test, an arithmetic bound. The reason must follow from the task line, the tests and the project as they are, "not from the node's own tries": a target that the node's code has only missed so far, judged from measurements of that code, uses the attempts. A failure outside the node blocks at once and uses no attempt.
- The **time limit**: `Done when` and the regression run under a limit (15, 30 or 60 minutes by complexity, or what a `Budget:` line in the README says), through the helper `.todo/todo-limit.sh` where the project has it, else with the tool's timeout set to the limit. A run stopped at the limit (exit 124) is a failed run.
- A **block** replaces the `State:` line by one `Blocked:` line, marks the node `[!]` and is committed as `chore(backlog): block <ID>`. The block commit has no body and holds `TODO.md` and every file the node changed. A blocked root is not finished: nothing is drained or merged, also with `--merge`.
- A **worker that stopped** leaves a node `[/]`: "a session ended, with no verdict written" is the file's own wording, and a crash or a usage limit are its examples. It is resumed, and the stop is not an attempt: the resume starts with an empty commit `chore(backlog): resume <ID>`. If the log shows that commit twice and nothing since, a `low` leaf is blocked with a `Blocked:` line that says it was resumed twice, and a `mid` or `high` leaf is broken down.
- A **stop with no verdict**, in this page, is a run that ends with its node still `[/]`, no `[x]`, no `[!]` and no block commit, by the agent's own choice.
- The **stale mark**: `/todo-status` marks a claim whose branches have had no commit for four times the budget of the tree's complexity, names `git switch` to the branch and `/todo-update <ID> --status ready`, and runs neither.

## Setup

- **Agent.** `codex exec` of codex-cli 0.167.0 in the Docker image `todo-codex-linux:0.167.0`, a fresh session per run, model `gpt-6.1-terra`. Neither the version nor the model is in the event stream. The version is inferred from the image: its build history holds `npm install -g @openai/codex@0.167.0`. The model is read from the runner script kept in the evidence (`-m gpt-6.1-terra`). The host's own Codex CLI is a different, newer version; it did not run the sessions.
- **Flags and profile.** From the runner script: `--ephemeral --ignore-user-config`, a permission profile that makes the project folder `/work` (and its `.git`) writable, the rest of the file system readable, and denies the login folder and the paths of the prompt and the runner, and a setting that turns the network off for the agent's commands. The prompt is read from a file on standard input and the stream is written with `--json`. The Codex client itself has network access. The container ran with `seccomp=unconfined`, as `tests/trials/codex-linux.md` requires, taken from the script that started it. The profile is the provisional one of 2026-11-08 and was not audited again.
- **What the agent had.** Three kinds of item are in the 12 streams: shell commands (117), file changes (27, each naming a path and a kind, not the patch) and agent messages (40, counted from the streams; not in `runs.csv`). All reading went through shell commands (`cat`, `git`, `rg`), and all 27 file writes through file changes; the stream has no item for a subagent, a web call or a tool call of another kind. The client's own instructions are not in the evidence; three reports (`happy-path`, `resume-stopped`, `stuck-loop`) name one of them, not to spawn agents unless asked.
- **Host and verifier.** Windows 11 with Git Bash started the containers and ran the assertions with `tests/trials/assert.sh`, called directly by the script that ran the batch. That script keeps no isolation setting, and no `assert.txt` holds a line of the isolated verifier, so the assertions ran unisolated. The evidence does not name this; it is read from the script and the logs.
- **Text.** `main` at `006d965`, run from a frozen checkout. The skill text is the same as in the second pi batch (commit `40effa3`): `git diff` of `plugin/skills` between the two is empty, and so it is between `006d965` and the branch of this task. The `.claude/skills` folder of each of the 12 projects is identical to `plugin/skills` (CRLF line endings, as in the Windows checkout). The agents were told to read the skills there, as in the earlier Codex batches.
- **Harness.** The project of a run is mounted at `/work`, so the working path does not name the scenario, and its first commit has the subject `init`. The 12 prompts do not name the scenario either, and each is byte for byte what `prompt.sh` of `006d965` prints for `/work` and its scenario. They call the agent "a trial agent testing a set of agent skills". The prompt has five forms, and each asks for the skill's report and for every instruction the agent found unclear: `Run /todo-continue --merge` with "Stop after one invocation" (`happy-path`) or "Stop after one invocation, or earlier if the skill says to stop" (`loop-limit`, `time-limit`, `stuck-loop`, `resume-stopped`, `resumed-twice`); `/todo-continue` without `--merge` and with "Stop after one invocation" (`drained-unmerged`); `/todo-status` with no stop sentence (`status-readonly`, `stale-claim`); `/todo-plan` with a goal of three tasks, the user's confirmation and "do not ask questions" (`plan-inline`); and `/todo-add` with its description and "Do not ask questions", where `add-lane` has the user's confirmation of the lane line and `no-backlog` has the stop sentence with "or earlier". No prompt names a rule. The pi summary's open point that the Codex runners still named the scenario in the working path is closed for these runs.
- **Time and order.** The agent's time limit was 3600 seconds (`timeout 3600` around `docker run`, 12 of 12). By file times the sessions ran on 2026-11-24 between 22:31 and 22:38 UTC: `status-readonly` first and alone, as a smoke test, and the other 11 never more than two at a time. The folder of this summary carries the date of the day it was written.
- **What a run keeps.** The prompt, the runner script, the event stream, the last agent message as `report.txt`, the assertion output and its exit code, the agent's exit code, the seconds, the setup log and an empty `stderr.log`, and the project the agent left. The evidence has no version file. The Git state was read from the projects.
- **Where the numbers come from.** Outcome, exit codes, assertions, branch names, commit lists and `Blocked:` lines were read from the evidence files and the projects. Commands are the completed shell-command items of the stream; a file change is not a command, so the calls an agent made are commands plus file changes. Tokens are the figures of the one `turn.completed` event of each stream: they hold the cached share, and the stream does not say how the calls are summed. *Wall s* is `seconds.txt`: the whole seconds from the start to the end of the `docker run` that held the session, so it includes the container's start and stop and not the assertions. It is not the span of a session log, which is what the Claude Code and pi figures are, and no ranking across agents is made from it. Every number was recomputed from those files for this summary.
- **Labels.** A run is named by its scenario: there is one run each.

## The scenarios

The full rows, with the assertions, are in [tests/trials/README.md](../../../tests/trials/README.md). Doing nothing fails every scenario but `status-readonly`, which only reads.

| Scenario | Start state | What it is built to reach |
|---|---|---|
| `happy-path` | One free leaf root | The whole of `/todo-continue --merge`: claim, start, node commit with its trailers, drain, merge, branch deleted |
| `status-readonly` | Two roots | `/todo-status` reads and changes nothing |
| `loop-limit` | A `mid` root; an acceptance test with a speed target (5 times as fast as a reference sieve) that standard-library Python does not reach | The limit of three attempts and the loop guard |
| `time-limit` | The helper, `Budget: low=1m, mid=1m, high=1m`, and a `mid` root for an exact count of twin primes up to 4 * 10^13 | The time limit through the helper |
| `resume-stopped` | The node's branch checked out, `[/]` with `attempts 1/3`, unfinished work in the tree | The resume commit; the stop is not an attempt |
| `resumed-twice` | As `resume-stopped`, with two empty resume commits and nothing since; a `low` leaf | The block of a node resumed twice |
| `stale-claim` | Three roots; `FEAT-001` (`low`) claimed by a branch whose commits are three days old, `FEAT-002` (`high`) by a fresh one | The stale mark of `/todo-status` |
| `stuck-loop` | An acceptance test that no `ease()` can pass: ten steps of at most 8 points cannot reach 100; a `low` root | The limit of three attempts, or a block at once as outside the node |
| `plan-inline` | An empty backlog with a Lanes section | `/todo-plan` writes the plan into `TODO.md`, with no plan document |
| `add-lane` | One free root, a Lanes section with `main` | `/todo-add --lane math`, with the lane line confirmed |
| `no-backlog` | No `TODO.md` | `/todo-add` stops and suggests `/todo-init` |
| `drained-unmerged` | `FEAT-001` drained on its own unmerged branch, `FEAT-002` open | The run goes on: the merge commands of `FEAT-001` are printed and `FEAT-002` is built on its own branch |

## Results

How to read the table. *Outcome* is `outcome.txt` of the run: PASS needs agent exit 0 and assertion exit 0. All 12 agent exits were 0 and all 12 `stderr.log` files are empty; the assertion exit was 0 in the 10 PASS runs and 1 in the 2 FAIL runs. *Assertions* are the lines of `assert.txt`, passed of all. *Wall s* and *Commands* are defined in "Setup". *Guard reached* is the rule that ended the run, "Not applicable" for a scenario that is built for no rule of the stuck-worker text, and "None" for a run that ended before any rule did. The same rows are in `runs.csv`, with the file changes, the tokens and the checksums of the prompt and the report.

| Run | Outcome | Assertions | Wall s | Commands | Ended | Guard reached |
|---|---|---|---|---|---|---|
| `happy-path` | PASS | 12 of 12 | 80 | 13 | Finished, drained and merged into `main`; branch deleted | Not applicable |
| `status-readonly` | PASS | 8 of 8 | 28 | 4 | Report only; nothing written | Not applicable |
| `loop-limit` | PASS | 11 of 11 | 118 | 17 | Blocked at the third attempt | The attempts limit, by runs of the whole `Done when` |
| `time-limit` | FAIL | 10 of 12 | 57 | 10 | Stopped after the red run, no code written; node left `[/]`, no block | None: stopped with no verdict |
| `resume-stopped` | PASS | 14 of 14 | 67 | 13 | Resumed, finished, drained and merged into `main` | The resume commit |
| `resumed-twice` | PASS | 11 of 11 | 41 | 8 | Blocked, no third resume commit | The resumed-twice block |
| `stale-claim` | PASS | 13 of 13 | 35 | 11 | Reported, nothing changed | The stale mark |
| `stuck-loop` | FAIL | 9 of 11 | 57 | 10 | Stopped after the red run with a question to the user, no code written; node left `[/]`, no block | None: stopped with no verdict |
| `plan-inline` | PASS | 12 of 12 | 33 | 6 | One `low` root written to `TODO.md`, not committed | Not applicable |
| `add-lane` | PASS | 13 of 13 | 30 | 5 | Lane line and root written to `TODO.md`, not committed | Not applicable |
| `no-backlog` | PASS | 9 of 9 | 20 | 4 | Stopped, nothing written, `/todo-init` suggested | Not applicable |
| `drained-unmerged` | PASS | 15 of 15 | 90 | 16 | `FEAT-002` built and drained on its own branch, merge commands printed, nothing merged | Not applicable |

The 12 runs made 117 commands and 27 file changes. Of the 117 commands, 21 exited non-zero (the 21 and their causes are counted from the streams; not in `runs.csv`): 12 are runs of a test that failed (the red runs, a run of a test id that did not exist yet in `happy-path`, the reproduction of the earlier failure in `resume-stopped`, and the 5 failed runs of `loop-limit` after its red run: 3 after a change and 2 reruns) and 9 are a search or a `cat` that found nothing or a file that is not there, two of them `rg: command not found`. Wall seconds run from 20 to 118. The two FAIL runs took 57 seconds and 10 commands each.

## What the runs showed

### 1. Of the three scenarios built so that a finished node fails, one blocked and two stopped with no verdict

None finished its node, none edited the acceptance test, and none wrote a way round it: against `init`, the `time-limit` and `stuck-loop` projects differ in `TODO.md` only (the claim and start edits), and `loop-limit` in `TODO.md` and `calc.py`.

- `loop-limit` blocked at the third attempt (point 2).
- `time-limit` and `stuck-loop` ended in the same shape (the "Failures" section has the accounts): 57 seconds, 10 commands, 2 file changes (the claim and start edits of `TODO.md`), one baseline run, one red run, and then a final message. The node stays `[/]` with `State: attempts 0/3; baseline 1 passing; branch ... from main; next: read docs`, the tree is clean, the claim commit is on `main`, and no `Blocked:` line and no block commit exist. These are the two runs that failed the same two assertions.

### 2. `loop-limit` blocked at the third failed run after a change; what it wrote to `State:` between the runs is not recorded

`loop-limit` ran the whole `Done when` (`python3 -m unittest tests.acceptance_primes`) 6 times: the red run, three failed runs after a change, and two reruns with no change between that it did not count. The three after a change measured the speed at 1.95, 1.39 and 1.38 times the reference against a wanted 5, and the reruns 1.72 and 1.39. It read `failures.md` once, after the first failed run after a change, which is the trigger the file names. It wrote no script of its own, ran the regression once (the baseline) and did not rerun it after the failed `Done when`, which the text allows, and found no way round the test; the code it left is an odd-only `bytearray` sieve whose primes are read out with a regular expression. It blocked at the third failed run after a change. The block commit has no body and holds `TODO.md` and `calc.py`, and the `Blocked:` line is one line with its two arrows, the command in backticks, its error outside them, and the three hypotheses (odd-only sieve, compact wheel candidates, ordered regex extraction) in the reason part. What it wrote to `State:` between the attempts is not recorded: the stream names a `TODO.md` change before each of the second and third implementations, but not what it changed, and the block replaced the line. Whether `attempts 1/3`, `2/3` and a `hyp:` were written as the run went cannot be said.

### 3. A worker that is gone and a stale claim: 3 of 3 matched the text in what was decided, with one departure in how that had no effect

- `resume-stopped`: it read `git status --short --branch`, `git diff --stat` and `failures.md`, and then made one empty commit `chore(backlog): resume FEAT-001`, by path (`--allow-empty -- TODO.md`) and before any test, with `attempts 1/3` unchanged in it. It reproduced the earlier failure once (`8 != 2`) and did not count that run, fixed `subtract`, ran the test and the regression green (2 passing against a baseline of 1), quoted the failure as `Red:` in the node commit, drained and merged. The command the rule names, `git log -2 --format=%s`, ran in the same call as the resume commit, and the decision to resume rested on `git log -5 --oneline`, read one call earlier, which showed no resume commit.
- `resumed-twice`: it read `failures.md`, ran `git log -2 --format=%s` (both subjects were the resume commit), ran no test, made no third resume commit and wrote the `Blocked:` sentence of the text with the two subjects joined by " / ". The block commit has no body and holds `TODO.md`, `calc.py` and the test file as the earlier session left them (the bug `a + b` still in).
- `stale-claim`: only commands that read (11). The report marks `FEAT-001` as stale (last commit three days before the run, "no commit for about 3 days"), names `git switch` to its branch and `/todo-update FEAT-001 --status ready`, and leaves `FEAT-002` (last commit of the minute of setup) unmarked. It does not state the limits (one and four hours).

### 4. The six scenarios that are built for no rule of the stuck-worker text did what the skills say

- `happy-path`: claim on `main`, start, a node commit with `Refs:`, `Red:` and `Reviewed: self, 0 findings fixed`, drain, `Merge FEAT-001 into main`, branch deleted, `main` checked out and clean. The named test did not exist, so it wrote it and used its missing-symbol error as the red run.
- `drained-unmerged`: it switched from the drained branch of `FEAT-001` to `main`, claimed `FEAT-002` from there, built it test first, drained it on its own branch, merged nothing, and printed the merge commands of both roots. Its node commit says `Reviewed: subagent, spec ok quality ok, 0 findings fixed` (see "Failures", row 3).
- `plan-inline`: it showed the proposal, one `low` root `FEAT-001` that covers subtract, multiply and divide with the whole suite as `Done when`, in a message before it wrote it into `TODO.md`, and wrote no plan document and no commit. The README of the scenarios allows one leaf or three.
- `add-lane`: it declared the lane `math` in the Lanes section and wrote `FEAT-002` with `Links: Lane: math`, left `FEAT-001` untouched and committed nothing.
- `no-backlog`: it found no `TODO.md`, wrote nothing and pointed to `/todo-init` without running it.
- `status-readonly`: it read the files, wrote nothing and made no commit.

### 5. Habits the 117 commands show

Counted over all 117 commands, by a search of each command line: none pipes a command into another (so no `Done when` is behind an output filter), none writes a file through the shell (the 27 file writes are file changes), none names a path outside `/work` (a search for `/tmp`, `/root`, `/etc`, `/home`, `~` and `..` finds none), none pushes, fetches or uses `git add -A` or `git add .`, and every one begins with `cd /work`, as the prompt asks. No agent message calls the task a trial, a scenario or constructed, and no command or message names a scenario. The streams hold no reasoning, so this says nothing of what the agents thought.

### 6. The slug rule was followed in 5 of 5 branches the agents made

`todo/FEAT-001-add-subtract-calc-py`, `todo/FEAT-001-add-primes-up-calc` (`primes_up_to` is three words, and both `to` words are dropped), `todo/FEAT-001-add-count-twin-primes`, `todo/FEAT-001-add-ease-calc-py` and `todo/FEAT-002-add-multiply-function-calc`, each recomputed from the root's title by the rule of `git-flow.md`. The other branches in the projects came from the setup.

### 7. The loop guard's count and the helper's stop were not reached

No run made a failed run of a part of `Done when` after a change that the text counts, so no count of the loop guard began; `loop-limit` made its attempts through whole runs. The helper `.todo/todo-limit.sh` ran twice, both in `time-limit` (the baseline and the red run, under one second each by the tests' own times) and printed no stop line, so no run reached exit 124 and the text's counting of a stopped run was not exercised.

### 8. The runs were short and cheap

The runs took 20 to 118 seconds and 4 to 17 commands. The streams report 4,834,092 input tokens in all (4,603,520 of them cached; 86 to 97 percent per run), 19,967 output tokens, and 1,707 reasoning-output tokens (counted from the streams; not in `runs.csv`) although no reasoning item is in any stream. Per run, input runs from 100,374 (`status-readonly`) to 962,152 (`loop-limit`) and output from 498 to 3,725. These are one turn's figures per run, taken from the stream as it reports them.

## Failures

**2 of 12 runs failed: `time-limit` and `stuck-loop`. Neither failure is a crash or a malformed block; each is a stop with no verdict.** A run that does nothing fails these scenarios by design, and so does a run that stops and asks. **Skill** is a defect of the skill text (a sentence that is missing, unclear or wrong), **harness** a gap in the trial harness or its record, **environment** the host (the Linux container, Codex, the client's own instructions), and **agent** a clear sentence that the agent did not follow.

### The two failed runs

Both fail the same pair of assertions (from `assert.txt`; the line for `time-limit` also asks that the `Blocked:` line name the limit):

1. "The node's branch is checked out and FEAT-001 is `[!]` with a `Blocked:` line that names the acceptance test."
2. "The block is committed as `chore(backlog): block FEAT-001` and the tree is clean."

The other 9 and 10 assertions pass in the two runs: the acceptance test, `Done when`, the helper and the `Budget:` line are unchanged, no test is skipped, nothing is drained or merged, and the lint passes.

The offending values, from the projects the agents left:

| | `stuck-loop` | `time-limit` |
|---|---|---|
| Branch checked out | `todo/FEAT-001-add-ease-calc-py` (matches the pattern) | `todo/FEAT-001-add-count-twin-primes` (matches the pattern) |
| Marker of `FEAT-001` | `[/]` | `[/]` |
| `State:` | `attempts 0/3; baseline 1 passing; branch ... from main; next: read docs` | the same shape |
| `Blocked:` line | none | none |
| Commits since `init` | the claim and the start commit; no block commit | the same |
| Working tree | clean | clean |
| Files changed against `init` | `TODO.md` only | `TODO.md` only |
| Runs of the acceptance test | 1, the red run (3 errors, `AttributeError`) | 1, the red run under the helper with 60 seconds (4 errors in 0.006 s) |
| `failures.md` read | never | once, after the red run |

So assertion 1 fails because the node is not `[!]` and has no `Blocked:` line, and assertion 2 fails on the commit subject alone. The branch names, the wording of a `Blocked:` line, an uncommitted file and the tree state play no part.

**`stuck-loop`.** The agent read `todo-continue/SKILL.md`, then the core, `git-flow.md` and `verification.md`, then the project. After the baseline run it said in a message that the acceptance test "exposes a conflict in the requested behavior": its jump limit allows at most 80 points across the range and the endpoints need 100. The arithmetic is right (ten steps of at most 8 points). It then followed the start steps (branch, claim, start commit), made the red run, and stopped. Its report opens "Stopped at step 7", says no implementation was written and the root was not merged, and ends its question with "Please clarify the intended jump limit or endpoint requirement." It never opened `failures.md`, where "outside the node" is defined and where "tests or criteria that contradict each other" is the example that fits.

**`time-limit`.** The agent read the same files, then the README (the `Budget:` line is in its output) and the whole of `.todo/todo-limit.sh`, and ran the baseline and the red run under `bash .todo/todo-limit.sh 60`, as the text asks. It read `failures.md` after the red run, and then ended. Its report says it stopped at step 7 because it "could not complete an exact implementation" and gives "within this invocation" as the bound; it names no rule, no bound and no limit. Its one listed ambiguity is about the shell sentence of the core. Why it stopped is not in the stream, and "within this invocation" may mean the sentence "Complete at most one node per invocation", the agent's own sense of what fits a session, or something in the client's instructions; the stream does not show which.

### What the text says about each ending

A search of `todo-continue/SKILL.md`, the core, `failures.md`, `verification.md` and `git-flow.md` for the words stop and ask finds these named stops of `/todo-continue`, among others that do not bear on these runs (a `State:` that names a branch, a test command that cannot run, a drained unmerged root with `--merge`, the content of `.todo/check.sh`): invariants that fail only on a `[/]` node's `State:` line, an interrupted merge or drain, a `[/]` node's uncommitted changes that do not fit the task line, a tree that is not clean, a red baseline, a `Ref:` path that is missing or a doc that contradicts the task line (step 6), a test that is already passing (step 7), a deviation from the `Ref` doc, and the block rules. Neither ending is one of them. The closest is step 6, which covers a doc and not a test, and step 7's "Already passing". The core's only general rule to ask is guardrail 7, for a rule that conflicts with an explicit user instruction, which is not this case. No sentence says that an invocation must end in `[x]` or `[!]`: "Complete at most one node per invocation" is a ceiling, and the table of the lifecycle by status says what each command does with each marker. And the text has a name for a node left `[/]` with no verdict: a worker that stopped, resumable. So the text has no stop for an agent that sees an impossible test before any change, and no sentence against ending without a verdict.

What the text does give is the load trigger for `failures.md`, which names three cases: the whole `Done when` or the regression failing after a change, Green failing twice on one test, and a `Done when` that cannot run. `stuck-loop` reached none of the three, because the agent found the contradiction before it made a change. That is the gap. Against it, the section "Test failures" of `todo-continue/SKILL.md`, which this agent read first, says that the limits hold from the first run and that a failure outside the node blocks at once, and step 7 says to implement only the task line: the agent had both and made no change and no run after a change.

The three agents on this scenario, one run each for two of them:

- pi (second batch, 6 runs): each made one failed run of the whole `Done when` after implementing started, and blocked at once as outside the node (6 of 6).
- Claude Code (this day, 1 run): it read `failures.md` right after the red run, before any change, and blocked at once with no code written. The Claude Code summary lists that early reading as a departure by the agent (its row 13).
- Codex (1 run): it made no change, so the trigger as written was never reached, and it never opened the file.

The logs show that the two runs which stopped after the red run differ in that one read `failures.md` and blocked and the other did not read it and stopped. They do not show that this is why: what the Codex agent would have done after reading it is not tested.

### Classification

The node asks for each failure to be classified as skill, harness or environment. "Agent" stands here for a clear sentence that the agent did not follow, which is a defect of none of the three. Each failed run against the four, with the class first. "Part" means a share of the cause; the shares are a judgement, not measured.

| Run | Class | Skill | Harness | Environment | Agent | How sure |
|---|---|---|---|---|---|---|
| `stuck-loop` | Skill, in part (about half); not harness; environment not shown; the rest agent | Part, about half: the definition of "outside the node" is loaded only after a failed run that follows a change; step 7 has a stop only for a test that already passes, none for one that cannot pass; no stop is named for a contradiction seen before any change | No: the assertions check the ending that the scenario's row names, and a stop that asks fails them by design | None shown: exit 0, empty stderr, no timeout, every command that mattered ran. Not excluded: the client's own instructions are not in the evidence | Part, about half: it held "at once when the failure is outside the node" and "implement only the task line", proved the contradiction itself, and made no change and no run after a change | Low to medium: the stream holds no reasoning |
| `time-limit` | Skill, in part (about a third); not harness; environment not shown; the rest agent | Part, smaller, about a third: no sentence makes an invocation end in a verdict, a stopped node is by the text's own name a resumable worker that stopped, and doubt about feasibility without an arithmetic bound leaves only the attempts | No: the same assertions, and the helper, the `Budget:` line and the test were as designed | None shown, the same reading: both helper runs ended in milliseconds and nothing was stopped at the limit | Part, the larger, about two thirds: `failures.md` was open in front of it, with the three attempts and the rule on a run stopped at the limit, and it ran no `Done when` after a change, wrote no code and wrote no block | Low to medium |

What a fix would touch, if the owner decides the text is at fault (nothing here is decided): for `stuck-loop`, `todo-continue/SKILL.md` (step 7, next to "Already passing", or the paragraph "Test failures", which holds the load trigger) or the place where `failures.md` defines "outside the node"; for `time-limit`, `failures.md` (the sentences on a time limit and on a node that ends without a verdict) or step 7. If the agent alone is at fault, no text changes, and a second run of each scenario would show whether the stop repeats (it is one run each here). The harness needs no change for either run.

A stop with no verdict is not a dead end in the text: both nodes are `[/]`, so the next `/todo-continue` would resume them (a `low` leaf and a `mid` leaf) and, if the same thing happened twice more, block the `low` one and break down the `mid` one. That was not run.

### The departures and notes, over all 12 runs

The assertions do not check everything a run does, so this table classifies the departures from the text, from the prompt or from the agent's own record that the streams and the Git state show. Not looked for: departures that only the reasoning would show, and a line-by-line comparison of every step of every run with the text.

| # | Departure or note | Runs | Class | Why | How sure |
|---|---|---|---|---|---|
| 1 | The two stops with no verdict | `time-limit`, `stuck-loop` | Skill and agent | The accounts and the classification are above | Low to medium |
| 2 | `failures.md` read before the trigger the file names | `time-limit` (after the red run, before any run after a change) | Agent | Harmless; the file's rule on a run stopped at the limit was in front of the agent | Sure |
| 3 | A node commit says `Reviewed: subagent, spec ok quality ok, 0 findings fixed` | `drained-unmerged` | Agent | The text gives `Reviewed: self, <n> findings fixed` for a review without a subagent. The stream shows no subagent: its items are commands, file changes and messages, and the agent read the diff itself (`git diff`). The report does not mention the review. Whether a subagent could appear in this stream is not known, so "no subagent was used" is not shown; the three reports that name the client's rule not to spawn agents make it unlikely. `happy-path` and `resume-stopped`, in the same client, wrote `Reviewed: self` | Sure of the trailer; medium that no review by a subagent happened |
| 4 | `# FEAT-001` comment added to `test_subtract`, a test the earlier session of the same node left | `resume-stopped` | Not a departure | The text forbids the ID on a test the node did not write. `test_subtract` is the uncommitted earlier work of the same node, which step 2 of `/todo-continue` calls "its earlier work"; the Claude Code run read it so too. No report names the sentence | Medium |
| 5 | The decision to resume rested on `git log -5 --oneline`; the rule's `git log -2 --format=%s` ran in the same call as the resume commit | `resume-stopped` | Agent | No effect: the log showed no resume commit either way | Sure |
| 6 | "The push-and-pull-request alternative" of `git-flow.md` left out of the printed merge commands | `drained-unmerged` | Harness: the prompt and the text disagree | The agent followed the prompt ("never push") and left out text the skill requires; the report names the conflict and says it omitted the alternative. Whether the text should hold in a run that forbids pushing is open | Sure |
| 7 | `Done when` forms: the whole suite (`discover -s tests`), already green, for the three-function plan; a file pattern (`-p test_power.py`) of a file that does not exist yet | `plan-inline`, `add-lane` | Open | `done-when.md` asks for a test id or file path and says a name filter can exit 0 with zero tests. The repository's lint, run on the two `TODO.md` files left in the projects, exits 0 with no warning for either. Not asserted, and no report names it | Medium |
| 8 | The lane line of `add-lane` written with no proposal of it first | `add-lane` | Not a departure | The user's confirmation was in the prompt, as the scenario is built | Sure |
| 9 | A report that names a limit's age but not the limits (`stale-claim`); the hint "if this is your work" kept for `FEAT-002` and the worktree alternative left out | `stale-claim` | Not a departure | `todo-status` asks for `stale: no commit for <age>` and the two commands; the report's own ambiguity list names the hint | Medium |
| 10 | `rg` ended with "command not found" twice, as the third command of `stuck-loop` and the eleventh of `resume-stopped`, while 14 other `rg` commands in 9 runs of the same image ran | `stuck-loop`, `resume-stopped` | Environment, not explained | The cause is not visible in the streams. No ending depended on it | Sure of the facts |
| 11 | No tool timeout set to the limit where there is no helper | `happy-path`, `loop-limit`, `resume-stopped`, `stuck-loop`, `drained-unmerged` | Environment | Two reports (`drained-unmerged`, `stuck-loop`) say the command tool has a yield time and no timeout setting; the stream records no tool settings. Every test run took at most 0.084 s | Medium |
| 12 | The record of a run: no version file, the version and the model read from the image and the runner script, the client's own instructions absent | all 12 | Harness | The stream names neither version nor model | Sure |

Rows that Claude Code's table has and that do not occur here: a block commit with a `Co-Authored-By` line (0 of the 21 commits the agents made carry one; counted from the commit lists of the runs, not in `runs.csv`), a rewrite of line endings (no line that an agent added, committed or left in the working tree, ends in a carriage return, in any of the 12 projects), files written through the shell, a `Done when` behind an output filter, and a write outside the project folder. Section "Compared with" sets the two side by side.

## Compared with the second pi batch, with Claude Code of the same day and with this agent on 2026-11-14

Only differences that the numbers show. A Codex cell here is one run, and a pi cell is three to six; a rate cannot be made from one run, and a cause is named only where a log shows it.

Against the second pi batch (27 results, `glm-5.3` and `glm-5.3-flash`, the same text), cells as that summary states them:

| | Pi, second batch | These 12 Codex runs |
|---|---|---|
| `loop-limit` | 6 runs: 5 blocked when the attempts ran out (4 at the third failed run, 1 at the fourth), 1 finished by a way round the test | 1 run: blocked at the third attempt |
| `time-limit` | 6 runs: 2 blocked at the third attempt, 2 blocked as outside the node, 2 finished by a way round the test | 1 run: stopped with no verdict |
| `stuck-loop` | 6 of 6 blocked as outside the node, after one failed run of the whole `Done when` | 1 run: no run after a change; stopped with no verdict |
| `resume-stopped`, `resumed-twice`, `stale-claim` | 9 of 9 matched the text in what was decided | 3 of 3 matched the text in what was decided |
| Slug of the branches for a title with an identifier (`loop-limit`, `time-limit`) | 10 of 12 follow it | 2 of 2 follow it |
| Block commit with a body, in the three scenarios that cannot turn green | 0 of 15 | 0 of 1 |
| Acceptance test edited | 0 of 18 | 0 of 3 |
| A run that finished a node that its scenario is built to block (`loop-limit`, `time-limit`) | 3 of 12 runs | 0 of 2 runs |
| The agent calls the task a constructed test | 17 of 18, from the reasoning | Not comparable: the reasoning is not in the stream. No message, command or report of the 12 says so |
| Points reported as unclear per `/todo-continue` report | 139 in 24 reports | 9 in 7 reports (see below) |

The two stops with no verdict have no counterpart in the pi second batch, where every run on a task that cannot turn green ended in a block or a finished node. Pi's agents did not stop there, and Codex's two did; the number of runs does not show why.

Against Claude Code on the same day (`claude -p`, Claude Code 2.1.331, Sonnet 5.5, the same twelve scenarios on the same text, one run each), the ends, and the calls each agent made (Claude Code's tool calls, which include reads and edits; Codex's commands plus file changes, because its reads are commands and its edits are file changes):

| Scenario | Claude Code | Codex | Calls: Claude / Codex |
|---|---|---|---|
| `happy-path` | Finished, drained, merged | Same | 18 / 18 |
| `status-readonly` | Report only | Same | 3 / 4 |
| `loop-limit` | Blocked at the third attempt, after 5 runs of the whole `Done when` (the red run, 3 failed after a change, 1 repeat) | Blocked at the third attempt, after 6 (the red run, 3 failed after a change, 2 repeats) | 24 / 25 |
| `time-limit` | Blocked at once, after one run the helper stopped at 60 s; its reason rests on its own measurement | Stopped after the red run, no verdict | 14 / 12 |
| `resume-stopped` | Resumed, finished, merged | Same | 15 / 15 |
| `resumed-twice` | Blocked; the block commit has a `Co-Authored-By` line | Blocked; no body | 9 / 9 |
| `stale-claim` | `FEAT-001` marked stale | Same | 4 / 11 |
| `stuck-loop` | Blocked at once after the red run, no code written | Stopped after the red run, no verdict | 17 / 12 |
| `plan-inline` | One `mid` root with three children | One `low` root | 8 / 7 |
| `add-lane` | Lane line and root written | Same | 8 / 6 |
| `no-backlog` | Stopped, `/todo-init` suggested | Same | 2 / 4 |
| `drained-unmerged` | `FEAT-002` built, merge commands of `FEAT-001` printed; a test file committed with mixed line endings | `FEAT-002` built, merge commands of both roots printed; a node commit that says `Reviewed: subagent` | 13 / 21 |

Counts over the same scenarios on each side, as that summary states them:

- A `Done when` behind an output filter, over the six scenarios that ran one (`happy-path`, `loop-limit`, `time-limit`, `resume-stopped`, `stuck-loop`, `drained-unmerged`): Claude Code 6 of 6, Codex 0 of 6.
- A file written through the shell, over the nine scenarios in which an agent wrote a file (`happy-path`, `loop-limit`, `time-limit`, `resume-stopped`, `resumed-twice`, `stuck-loop`, `plan-inline`, `add-lane`, `drained-unmerged`): Claude Code 7 of 9 (9 of 9 tried one), Codex 0 of 9. Codex has a file-change item for edits, and Claude Code's `Edit` and `Write` tools were open to it too; the logs do not show why one agent used the shell and the other did not.
- Branches the agents made, the same five scenarios on both sides: the slug rule was followed in 5 of 5 and 5 of 5, with the same five names.
- Blocks, the two scenarios blocked on both sides (`loop-limit`, `resumed-twice`): a body on the block commit in 1 of 2 for Claude Code (the host's attribution line) and 0 of 2 for Codex. The runs of the two agents had different instructions from their hosts, so this is not a difference of the skill text.
- Reported as unclear, the same twelve scenarios: Claude Code 99 points in 12 reports, Codex 16 in 12 (4 reports say "none"). Both counts are the items listed under the ambiguity heading of each report. The numbers do not show why.
- Wall seconds are not compared (the spans differ, see "Setup"); the calls are set side by side above as counts only, not ranked, because a call is not the same thing on the two agents.

Against this agent's batch of 2026-11-14 (Codex CLI 0.167.0 in the same image, `gpt-6.1-terra`, text of commit `6de470f`, 34 scenarios of which 27 ran, one run each): the two scenarios in both batches are `happy-path` and `status-readonly`, and both passed in both batches (one run each). That batch's 3 failures were assertion wording against an agent that followed the skill; here the 2 failures are runs with no verdict, which no wording of an assertion explains. That summary lists no ambiguities the agents reported, so no topic can be compared, and it gives no per-run times or commands.

## What the agents reported as unclear

Each report ends with the instructions the agent found unclear. The 12 reports list 16 points (counted by hand from the reports, not in `runs.csv`), counted as the items under the ambiguity heading of each report; 4 reports (`loop-limit`, `resumed-twice`, `add-lane`, `status-readonly`) say none and 8 list items. The 7 reports on `/todo-continue` list 9 of them (5 lists, 2 "none"). A report that lists a point and says the text settled it is counted too. No report says that a point stopped its run, and neither report of a stopped run names the sentence it stopped at. Counts are runs, one run once per topic; with one run per scenario, a topic that two runs name may be two scenarios and two reasons. "Pi" is the second batch's list of the 24 `/todo-continue` reports (139 points), or its notes on `/todo-status`; "Claude Code" is the list of the 12 reports of the Claude Code summary.

Named by two or more of the 12 runs, most runs first:

| Topic | Runs | In the pi and Claude Code lists |
|---|---|---|
| A fresh-context subagent reviewer against the client's rule not to spawn agents ("With a subagent tool, a fresh-context reviewer does both in one call") | 3 (`happy-path`, `resume-stopped`, `stuck-loop`) | Pi: "Review without a subagent tool", 2 of 24, where the agent had no such tool and both said the text settled it; not in the Claude Code list |
| "Else set your tool's timeout to the limit" when the command tool has a yield time and no timeout | 2 (`drained-unmerged`, `stuck-loop`) | Pi: the time limit's value and unit, 2 of 24, which is a nearby topic, not this one; not in the Claude Code list |
| The core's "state the conflict and ask" against the prompt's "do not ask questions" | 2 (`no-backlog`, `plan-inline`) | Not in pi (it ran neither command); Claude Code: "Confirmation rules of `/todo-add` and `/todo-plan`", 2, a nearby topic |
| The core's "use the shell only for `git`, test and `Done when` commands ..." against the client's tools (it gives no way to read the skill files) in `stuck-loop`, and against the prompt's "cd there with an absolute path in every shell call" in `time-limit` | 2 (two different clashes) | Not as this sentence; Claude Code's most-named topic is Windows tooling slips, 8 |

Named once: the red-test sentence when the test does not exist yet (`happy-path`), the push-and-pull-request alternative against "never push" (`drained-unmerged`), "show every proposal in full before asking for confirmation" and "wait for confirmation" against a confirmation already given (`plan-inline`), "read `docs/`" when there is none (`plan-inline`), the core's "suggests `/todo-init` and stops" against "stop after one invocation" (`no-backlog`), the core's hint "if this is your work" against "do not add suggestions" (`stale-claim`), and what "Recently drained" prints when there is no version section (`stale-claim`; the pi lists name it in all three `/todo-status` reports of both batches).

Named in pi by many reports and by none of these 12: what `--merge` does for a root that blocks (14 of 24 in pi), which failed runs are attempts (7), outside the node against a target only missed so far (5), the form of the `Blocked:` line (6), the block commit (5) and "the regression never runs the acceptance test" (12). The run that read `failures.md` after its red run and then ended with no verdict (`time-limit`) lists only the shell sentence; the one run that reached the blocking rules after a failed run, `loop-limit`, lists nothing at all. Nothing was changed for any of these points in this task.

## Open after this batch

What a later task would settle:

- **The stop with no verdict.** Two nodes were left `[/]` by the agent's own choice. Whether the text should name a stop for a test that cannot pass before any change, say where `failures.md` is loaded, or say that an invocation ends in a verdict is a decision for the owner. A later batch, [after the text change of FEAT-143.1](../stuck-worker-text-2026-11-25/summary.md), ran both scenarios again: 4 of 4 Codex runs ended blocked there. A second run of each scenario on this text would have shown whether the stop repeats, and a run in which `failures.md` is read first would test the one difference the logs show.
- **What `loop-limit` wrote to `State:`.** Whether `attempts 1/3`, `2/3` and a `hyp:` were written as the run went is not recorded; the stream names the file change and not its content. A later batch that keeps the working tree between commits, or the diff of each file change, could show it.
- **A `Reviewed:` trailer that states a subagent.** The harness checks that a node commit has a trailer, not which one. Whether Codex's stream shows a subagent at all is unknown; a run in which a subagent is used and one in which it is not would settle that.
- **The client's own instructions.** They reach the agent and are not in the evidence; three reports quote one. Their effect on a stop cannot be read.
- **The `Done when` forms of `plan-inline` and `add-lane`.** Both passed the lint and the assertions; whether a whole-suite command and a file pattern for a file that does not exist yet meet `done-when.md` is not checked by either.
- **The tool timeout where there is no helper.** The Codex command tool has none to set, and every test run took under a second, so the rule is untested here for a test that runs longer than a tool allows.
- **`rg: command not found`** in 2 of the 16 commands that used it, with the same image; unexplained.
- **The time limit's exit 124.** Neither Codex run that used the helper came near the limit.
- **The loop guard's count.** It has still never been reached by an agent: 0 of 12 here, and none in the pi and Claude Code batches. The suite is the only check of what an agent does at its 2nd, 4th or 8th run.
- **The scenarios not rerun.** See "Limits".

## Limits

- One run per scenario, so no count is a rate: what these runs did is not how often an agent does it. Both failures are one run each; neither was repeated.
- One agent family and one model, in Linux containers, started from one Windows host with Git Bash, with an unisolated verifier. Nothing is shown for macOS, for other models or for a Codex of another version. The version of Codex that ran is inferred from the image.
- The evidence is the event stream, the last message, the assertion output and the Git state. The stream has no reasoning text and no time per event, so what an agent suspected or weighed, and how the time was spent, cannot be read or compared with pi's or Claude Code's. Its token figures are one turn's totals.
- The client's own instructions and the exact tools it offered are not in the evidence. The profile and the container boundary are the provisional ones of 2026-11-08, and no network setting was tested.
- The prompt calls the agent a trial agent. The working path no longer names the scenario.
- The 32 scenarios other than these twelve were not rerun on the current text, which is 44 scenarios in all. Of them, 25 ran with Codex on 2026-11-14 on older text (22 passed and 3 failed there: `baseline-red`, `interrupted-merge`, `race-claim-conflict`, `race-claim-benign`, `refresh-from-base`, `claimed-elsewhere`, `release-ask`, `release`, `replan`, `ci-github`, `ci-local`, `no-git`, `update-block`, `update-drop`, `report`, `blocked-sibling`, `leftover-work`, `plan-stop`, `decompose`, `regress-block`, `ts-baseline-red` and `ts-interrupted` passed; `add-fix`, `monorepo` and `dirty-tree` failed one assertion each), and 7 did not run then (`team-claim`, `java-lifecycle`, `java-baseline-red`, `java-interrupted`, `ts-lifecycle`, `multi-module` and `lanes`). Nothing is shown for any of the 32 on the current text, and the start states of the older scenarios changed since (the first commit of a scratch project is now `init`, and the common head of the start backlogs has a Lanes section). Of the ten scenarios of this batch that the 2026-11-14 batch did not have, six belong to the stuck-worker rules and four do not (`plan-inline`, `add-lane`, `no-backlog`, `drained-unmerged`).
- `resumed-twice` has a `low` leaf, so the case of a `mid` or `high` leaf that is broken down was not run. `stale-claim` has one claim three days old and one a minute old; a claim near its limit was not tried.
- The loop guard's count and the helper's stop were not reached, and an attempts limit found already passed could not come up: only one run read `failures.md` after a failed run.
- Wall seconds are the harness's span around the container run, with the container's start and stop in it.
- The quotes above are short excerpts (under 15 words) of the agents' reports and messages, of the skill text and of the prompt; no prompt, stream or tool output is copied.
