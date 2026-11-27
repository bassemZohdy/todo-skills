# Lifecycle trials

The trials in `tests/trials/` give a fresh agent a scratch project in a known starting state, let it follow the skills, and check what it left behind with `assert.sh`. `bash tests/trials/selftest.sh` (also run in CI) checks the harness without an agent: every scenario must set up, and doing nothing must fail it (except the read-only scenarios).

## Scenarios

| Area | Scenarios | Toolchain |
|---|---|---|
| Plan | `replan` | Python |
| Execution and merges | `happy-path`, `ts-lifecycle`, `java-lifecycle` | Python; Node 22; Java 17 + Maven |
| Resume | `interrupted-merge`, `refresh-from-base`, `blocked-sibling`, `drained-unmerged` (a drained root left unmerged: the run goes on), `resume-stopped` and `resumed-twice` (a node left active by a worker that is gone, resumable or already resumed twice) | Python; `resume-stopped` and `resumed-twice` have pi, Claude Code and Codex runs, below |
| Parallel lanes | `lanes`, `multi-module` | Python; Maven multi-module |
| Regression failure | `baseline-red`, `ts-baseline-red`, `java-baseline-red` | Python; Node 22; Java 17 + Maven (the TypeScript ones have pi, Claude Code and Codex runs, the Java ones pi and Claude Code runs, below) |
| Interrupted run | `interrupted-merge`, `ts-interrupted`, `java-interrupted` | Python; Node 22; Java 17 + Maven (same note) |
| Uncommitted work on the base | `leftover-work`, `dirty-tree` | Python |
| Plan stop, breakdown, and a node blocked by a regression it cannot fix | `plan-stop`, `decompose`, `regress-block` | Python; pi, Claude Code and Codex runs, below |
| A task that cannot turn green (the limit of three attempts, and the loop guard for partial runs) | `stuck-loop`, `loop-limit` (a speed target out of reach that no single run rules out) | Python; pi, Claude Code and Codex runs, below |
| A `Done when` that does not end (the time limit) | `time-limit` | Python; pi, Claude Code and Codex runs, below |
| Planning inside `TODO.md` | `plan-inline` | Python; pi, Claude Code and Codex runs, below |
| Claims and races | `claimed-elsewhere`, `race-claim-conflict`, `race-claim-benign`, `stale-claim` (a claim with no commit for four times its budget, which `/todo-status` marks stale) | Python; `stale-claim` has pi, Claude Code and Codex runs, below |
| Team use (two clones, one bare remote) | `team-claim` | Python; pi and Claude Code runs, below (the Codex container cannot read its bare remote) |
| Project setup | `monorepo`, `no-git`, `ci-github`, `ci-local` | Python (`make test` in `monorepo`); no repository; GitHub remote or none |
| Backlog commands | `add-fix`, `add-lane`, `update-block`, `update-drop`, `no-backlog` (no `TODO.md`: the command stops) | Python |
| Release and read-only views | `release`, `release-ask`, `status-readonly`, `report` | Python |

The expected end state of every scenario is in the table in [tests/trials/README.md](../tests/trials/README.md).

`ts-lifecycle` (TypeScript, `node:test`, no dependencies), `java-lifecycle` (Maven, JUnit 5) and `multi-module` (two Maven modules, two lanes, one reactor build as the regression suite) were added after 0.3.0 so the skills are exercised outside Python. Scratch projects are built from plain files, so nothing is downloaded except JUnit and the Maven plugins on a first Maven run.

## Run one

```bash
bash tests/trials/run-claude.sh /tmp/runs ts-lifecycle     # fresh Claude Code agent, then assert.sh
bash tests/trials/run-codex.sh ~/todo-trials baseline-red  # fresh Codex agent (keep the folder outside the Windows temp folder)
bash tests/trials/score.sh /tmp/runs                       # trial score over a batch
```

`run-claude.sh` starts `claude -p` with edits accepted and the Bash, Read, Write, Edit, Glob and Grep tools allowed, so run it only in a throwaway environment. It and `run-pi.sh` build the scratch project at `<runs>/w-<random>/repo`, so the folder the agent works in does not name the scenario, and stop the agent after `TRIAL_TIMEOUT` seconds (default 1500). `run-codex.sh` is the Codex twin and confines the agent's writes to the scratch repository. To use another agent, run `setup.sh`, give that agent the output of `prompt.sh`, then run `assert.sh`. Each scenario ends in one verdict: PASS, FAIL, INFRA_ERROR (the environment stopped the agent) or UNVERIFIED (no record that an agent ran); only PASS counts in the score. The harness checks that need no agent are listed in [tests/trials/README.md](../tests/trials/README.md#harness-checks); CI runs them. The manually started workflow `.github/workflows/trials.yml` installs the Codex and Claude Code CLIs at the versions of the recorded batches on Ubuntu and macOS runners and reports what a trial would find there (shell, Git, Python, Node, CLI versions); it signs in to nothing and reads no secret.

## Results

| Scenario | Agent | Date | Result |
|---|---|---|---|
| `ts-lifecycle` | Claude (the interactive session that maintains this repo, following `plugin/skills/todo-continue/SKILL.md` and `todo/reference/git-flow.md` by hand) | 2026-11-07 | Pass: `assert.sh` 13/13. Plan tree FEAT-001 with 2 children; red (missing export), green, `--no-ff` merges, integration `npm test` 3 passing, drain, merge to main. |
| `java-lifecycle` | same | 2026-11-07 | Pass: `assert.sh` 13/13. Red was a Maven compilation error (`cannot find symbol`), green via `-Dtest=...Test -Dsurefire.failIfNoSpecifiedTests=true`, reactor 3 tests passing. |
| `multi-module` | same | 2026-11-07 | Pass: `assert.sh` 14/14. Two lanes (core, text) in separate worktrees, claims fast-forwarded on main, second lane refreshed from main after the first landed (no conflict), both drained, worktrees removed. |

### Fresh-agent runs (independent evaluation, 2026-11-07)

Fresh `claude -p` processes (Claude Code 2.1.319, `claude-sonnet-5-5`, Windows 11 with Git Bash), each checked by `assert.sh` from the controller. Full results: [docs/evals/claude-code-2026-11-07/summary.md](evals/claude-code-2026-11-07/summary.md).

| Scenario | Result |
|---|---|
| `happy-path`, `baseline-red`, `interrupted-merge`, `race-claim-conflict`, `race-claim-benign`, `claimed-elsewhere`, `blocked-sibling`, `release-ask` | Pass, 3 of 3 fresh runs each |
| `refresh-from-base`, `monorepo`, `replan`, `release`, `multi-module` | Pass |
| `ts-lifecycle`, `java-lifecycle` | Failed on the first run because the prompt said to stop after one invocation (TASK-025); after the prompt fix both pass in one fresh session (13/13 each) |
| `lanes` | INFRA_ERROR on a host whose Python imports a foreign `tests` package; with `PYTHONNOUSERSITE=1` pass in 4 of 4 runs, both with subagents (genuinely overlapping) and with the Agent tool disabled |
| `ci-local` | INFRA_ERROR: the headless agent may not write `.git/hooks` (12 of 13 checks pass; the skill printed the hook) |

### Codex runs (2026-11-07)

Fresh `codex exec` processes via `tests/trials/run-codex.sh` (codex-cli 0.167.0, Windows 11). Details, evidence and the sandbox findings: [docs/evals/codex-2026-11-07/summary.md](evals/codex-2026-11-07/summary.md). Rerun on 2026-11-08 with every assertion in the isolated Windows verifier: the same 2 PASS and 6 INFRA_ERROR, no FAIL; the Java scenarios now stop on Maven being unable to read its host cache in the sandbox ([codex-windows-2026-11-08](evals/codex-windows-2026-11-08/summary.md), TASK-045).

| Scenario | Result |
|---|---|
| `baseline-red`, `interrupted-merge` | Pass (10/10, 16/16) |
| `happy-path`, `race-claim-conflict`, `ts-lifecycle`, `java-lifecycle`, `multi-module`, `ci-local` | INFRA_ERROR: the sandbox blocked Git branch creation, Node child processes or `.git/hooks`; the cause is recorded per run and none is counted as a skill failure |

### Linux Codex runs (2026-11-08)

Fresh Codex CLI 0.167.0 sessions using `gpt-6.1-terra` in Linux containers passed all eight scenarios (105/105 final assertions). TypeScript and Java used a fresh session per node. The multi-module lanes ran sequentially; the event heuristic reported `overlapping`, which is not proof of concurrent agents, and `lane-evidence.sh` has since been changed to report `unverified` for worktree events alone (FIX-036). A later run with one fresh Codex process per lane (`run-codex-lanes.sh`) recorded both workers' tool activity overlapping for 75 s and passed 15/15 ([TASK-044](evals/lanes-codex-2026-11-08/summary.md)). Clean installations with and without optional tools passed, and a scratch clone of an existing project completed a feature after an explicit backlog-commit workaround (the underlying `/todo-add` then `/todo-continue` gap is fixed by [FIX-035](evals/fix-035.md); the same feature on the same project then passed on the first attempt with no commit between the sessions, [TASK-043](evals/eval-skills-2026-11-08/summary.md)). A later [boundary audit](evals/linux-boundary-2026-11-08.md) with dummy login and evidence sentinels passed its probes (reads and writes of the login, evaluator and evidence, symlink escape and loopback network all denied; scratch Git allowed) and the controller's assertions now run through `assert-exec.sh`, which confines project test processes in the Linux profile. It is not a proof of complete isolation, and multi-node TypeScript and Java trials now run one fresh Codex process per invocation (`run-codex-multi.sh`), so the results stay provisional. The results, failures and exit codes are in [the Linux summary](evals/codex-linux-2026-11-08/summary.md); the prompts, logs and checksums of the runs stay with the maintainer, and [how to run the batch again](../tests/trials/codex-linux.md) is kept with the harness.

### Linux Codex runs on the revised text (2026-11-14)

The skill text as revised on 2026-11-13 had not been run with Codex. Fresh Codex CLI 0.167.0 sessions (`gpt-6.1-terra`, one per scenario, in Docker containers) ran 27 of the 34 scenarios: 24 passed and 3 failed one assertion each (324 final assertions passed, 3 failed). The three failures are assertion wording against what the agent did while following the skill (TASK-124); `plan-stop`, `decompose` and `regress-block` passed. Seven scenarios did not run (Maven, multi-session, per-lane and shared-remote setups). Results, setup problems and limits: [docs/evals/codex-linux-2026-11-14/summary.md](evals/codex-linux-2026-11-14/summary.md).

### pi runs (2026-11-12)

Fresh `pi -p` processes via `tests/trials/run-pi.sh` (pi 1.5.2, `glm-5.3` on z.ai, Windows 11 with Git Bash, Node 24, Java 25; the assertions ran unisolated, so this is not equal to the isolated batches). Details, evidence, the skill-text versions each run used and the benchmark: [docs/evals/pi-glm-2026-11-12/summary.md](evals/pi-glm-2026-11-12/summary.md).

| Scenario | Result |
|---|---|
| 28 of the 29 scenarios, including the five that had no agent run (`team-claim`, `ts-baseline-red`, `java-baseline-red`, `ts-interrupted`, `java-interrupted`) and `ci-local` | Pass, one fresh run each (`lanes` and `multi-module` ran sequentially: pi has no subagent tool) |
| `blocked-sibling` | Failed once (the agent dropped the `- ` of a task line when changing its marker; the lint rejects it), then passed 3 of 3 after one sentence was added to the core |

The same batch ran the agent benchmark for the first time (3 arms, 6 scenarios, 3 runs each): `no-methodology` 16/18, `lean-baseline` 15/18, `todo-skills` 15/18, at roughly 25 times the input tokens for `todo-skills`; the skills asked about the ambiguous requirement 3 of 3 times and stopped on uncommitted work in `5-interrupted` 3 of 3 times (design, not a defect).

### pi reruns on the revised text (2026-11-13)

Every ambiguity section of the 2026-11-12 reports was read again, the skill text was changed in four pull requests (FIX-098, FIX-099, FEAT-100, FIX-102), and fresh pi agents reran the scenarios on each version of the new text, same agent, model and host. Details, the text versions and what the reports say now: [docs/evals/pi-glm-2026-11-13/summary.md](evals/pi-glm-2026-11-13/summary.md).

| Text | Scenarios | Result |
|---|---|---|
| T1 (first wording) | all 31, including the new `leftover-work` and `dirty-tree` | Pass, one fresh run each |
| T2 (after reading the T1 reports; fixture branches renamed) | 17 | Pass, one fresh run each |
| T3 (after reading the T2 reports; the text of pull requests 35 to 37) | 9 | Pass, one fresh run each |
| T4 (with FIX-102) | `ts-lifecycle`, `java-lifecycle`, two runs each | Pass, 4 of 4; each made the root's start commit |

The benchmark's `todo-skills` arm was rerun too: `5-interrupted` passed 6 of 6 (it had failed 3 of 3, stopping on the uncommitted work), the other five scenarios 1 of 1 each. Scratch repositories now keep LF line endings on Windows; the CRLF rewrite behind the one failure of 2026-11-12 did not come up again.

Later that day TASK-110 cut the text every `/todo-continue` run loads by 12 percent, moving rarely used branches into reference files that are read on demand. Fresh pi agents reran all 31 scenarios and the six benchmark scenarios of the `todo-skills` arm on that text: 31 of 31 and 6 of 6 passed. None of those runs reaches a moved branch, so TASK-113 added `plan-stop`, `decompose` and `regress-block`; each passed on the text before the cut and on the text after it, one run each, and on the new text each agent opened the reference file its branch points to. Results, the measured cost and what was not exercised: [docs/evals/pi-glm-2026-11-13-load-cut/summary.md](evals/pi-glm-2026-11-13-load-cut/summary.md).

Those runs raised wording gaps; FIX-114 (the plan stop, the breakdown and a blocked node) and FIX-115 (six sentences two or more reports called unclear) closed them, and 17 more fresh runs on the reworded text passed: [docs/evals/pi-glm-2026-11-13-wording/summary.md](evals/pi-glm-2026-11-13-wording/summary.md).

Claude Code then ran all 34 scenarios on that text (`claude -p`, Windows 11 with Git Bash, one fresh run each): 32 passed on the first run, `happy-path` failed once because the agent wrote CRLF line endings with a Python script and passed on the rerun, and `ci-local` failed twice because headless Claude Code may not write `.git/hooks` (the skill printed the hook, as it says to). The three newest scenarios passed first time. Codex was probed once and could not run `python3` in its Windows sandbox, so the Codex half stays open (TASK-116). [docs/evals/claude-code-2026-11-13/summary.md](evals/claude-code-2026-11-13/summary.md).

### pi runs on the Lanes section and inline planning (2026-11-14)

FEAT-125 (the optional `## 🛤️ Lanes` section of `TODO.md`) and TASK-126 (`/todo-plan` plans inside `TODO.md`, `/todo-init` only points to it) changed the text of five commands. Fresh pi agents (GLM 5.3) ran six scenarios on it, including the new `plan-inline` and `add-lane`: five passed, and `plan-inline` failed once on an assertion that required three tasks where the agent correctly wrote one leaf; it passed after the assertion and one sentence of `/todo-plan` were corrected. Details, the points the agents found unclear and the limits: [docs/evals/pi-glm-2026-11-14-lanes-inline-planning/summary.md](evals/pi-glm-2026-11-14-lanes-inline-planning/summary.md).

### pi runs with a helper script for the bookkeeping (2026-11-15)

FEAT-129 tested `tools/todo-flow.sh`, an optional script that makes a node's claim, start, completion and drain commits in one call each. Fresh pi agents (GLM 5.3) ran the 18 benchmark cells of the `todo-skills` arm with and without it: 18 of 18 passed both times, the median model calls fell from 29 to 26 and the uncached input plus output did not fall, against targets of 25% and 30%. Twelve lifecycle scenarios passed on the same text, one of them without the helper. The helper missed both targets; the owner merged it as an optional script all the same. Details and limits: [docs/evals/pi-glm-2026-11-15-flow-helper/summary.md](evals/pi-glm-2026-11-15-flow-helper/summary.md).

### pi runs on the text after a review in rounds (2026-11-15)

TASK-131 reviewed the text of all nine skills and their reference files in rounds, fixing contradictions, stale pointers and gaps and pinning each fix with a check. Fresh pi agents (GLM 5.3) then ran the changed text in three batches, 32 runs over 15 scenarios in five batches, among them the new `no-backlog` (a command stops without a `TODO.md`) and `drained-unmerged` (a root drained without `--merge` does not end the next run): all 32 passed on the first try. What the agents called unclear fed five more rounds, which changed twenty-two sentences, until a batch raised nothing that met the rule. Details, what was left as it is and the limits: [docs/evals/pi-glm-2026-11-15-skill-review/summary.md](evals/pi-glm-2026-11-15-skill-review/summary.md).

### pi runs of a task that cannot turn green (2026-11-22)

FEAT-134 added a loop guard (a failed run of `Done when` without progress counts as an attempt at the 2nd, 4th and 8th run), a stale-claim mark and a time limit. The new scenario `stuck-loop` gives `/todo-continue` a node whose acceptance test no code can pass. Fresh pi agents (GLM 5.3) ran it three times: all three passed the assertions, none stopped at the loop limit. Each saw after one run that the tests contradict each other and blocked the node at once as a failure outside the node, with `attempts` at 0 of 3, so the counting of runs was not exercised. The scratch projects of that batch named the scenario in the working path and the design in the subject of their first commit, and all three agents quote that subject before they first ran the test: the runs do not show that an agent that is not told sees the contradiction after one run. Run again on 2026-11-24 on a harness that no longer names it, the same scenario ended in a block after one run in 6 of 6 runs (next section). What they found unclear and what the runs do not show: [docs/evals/pi-glm-2026-11-22-stuck-loop/summary.md](evals/pi-glm-2026-11-22-stuck-loop/summary.md).

### pi runs on the scenarios for the stuck-worker rules (2026-11-23 and 2026-11-24)

FEAT-138 added five scenarios, each built to reach one rule of FEAT-134: `loop-limit` and `time-limit` (the limit of three attempts and the time limit), `resume-stopped` and `resumed-twice` (a node whose worker is gone) and `stale-claim` (the stale mark of `/todo-status`). Fresh pi agents (GLM 5.3 and GLM 5.3 flash) ran them and `stuck-loop` in two batches. The first, 24 runs, passed 9 of 9 for the worker that is gone and the stale claim and 3 of 15 for a task that cannot turn green: the harness stopped 7 runs at 1500 seconds, 5 failed on a branch name or an edited docstring, and the harness had named the scenario to the agents. FEAT-138.6 removed that, and FEAT-138.7 changed the sentences that two or more reports called unclear: a failed run of the whole `Done when` is an attempt, the loop guard counts partial runs only, and a failure outside the node needs a reason that does not rest on the node's own tries. The second batch, 27 runs on that text with a limit of 3600 seconds, passed 22: 9 of 9 again, and of the 18 runs on a task that cannot turn green 15 ended in a block, 7 when the attempts ran out (6 at the third failed run, one at its fourth), counted as the text says, and 8 as a failure outside the node. The other 3 finished the node with code that passes the unchanged acceptance test and does not do what the task line says (two runs) or what the test says of itself (one run); no rule stopped them, and in neither batch did an agent reach the loop guard's count. The runs one by one, what the agents found unclear and what is open: [docs/evals/pi-glm-2026-11-23-stuck-worker/summary.md](evals/pi-glm-2026-11-23-stuck-worker/summary.md).

### Claude Code runs on the scenarios for the stuck-worker rules (2026-11-24)

TASK-140.1 ran twelve scenarios with fresh Claude Code agents (`claude -p`, Claude Code 2.1.331, `claude-sonnet-5-5`, Windows 11 with Git Bash, the skill text of `main` at `006d965`, which is the text of the second pi batch above), one run each: the six scenarios of the previous section and `happy-path`, `status-readonly`, `plan-inline`, `add-lane`, `no-backlog` and `drained-unmerged`. All 12 passed every assertion. The three scenarios built so that a finished node fails (`stuck-loop`, `loop-limit`, `time-limit`) ended in a block, and none edited the acceptance test. The block of `time-limit` rests on a reason that the text's sentence on a failure outside the node does not allow (the agent said so itself), the block commit of `resumed-twice` has a `Co-Authored-By` line, which the host's instruction asked for and the text rules out, and `drained-unmerged` committed a test file with mixed line endings. It is one run per scenario, so no count here is a rate; no run reached the loop guard's count; and the session logs that the wall times and tool calls come from were not archived. The other 32 scenarios of the Claude Code batch of 2026-11-13 were not rerun on this text. The Codex half is in the next section. The runs one by one, the deviations from the text and what the agents found unclear: [docs/evals/claude-code-2026-11-25/summary.md](evals/claude-code-2026-11-25/summary.md).

### Codex runs on the scenarios for the stuck-worker rules (2026-11-24)

TASK-140.2 ran the same twelve scenarios with fresh Codex agents (`codex exec`, codex-cli 0.167.0 in a Linux container, `gpt-6.1-terra`, started from Windows 11 with Git Bash, the skill text of `main` at `006d965`, which is the text of the second pi batch and of the Claude Code section above), one run each. 10 passed every assertion and 2 failed: `time-limit` (10 of 12) and `stuck-loop` (9 of 11). Of the three scenarios built so that a finished node fails, `loop-limit` ended blocked at the third attempt, counted as the text says, and the other two stopped after one red run with no code written, the node still `[/]` and no block commit: a stop with no verdict, which the assertions do not accept. The summary reads `stuck-loop` as a gap in the skill text and the agent's own choice in about equal parts, and `time-limit` mainly as the agent's choice with a smaller share of the text; it is one run each and the event stream holds no reasoning, so neither reading is firm. The worker that is gone and the stale claim followed the text in 3 of 3 runs, and one node commit (`drained-unmerged`) states a subagent review that the stream does not show. It is one run per scenario, so no count here is a rate; no run reached the loop guard's count; the assertions ran unisolated; and the other 32 scenarios were not rerun on this text (25 ran with Codex on 2026-11-14 on older text, 7 did not run then). The runs one by one, the classification of the two failures and what the agents found unclear: [docs/evals/codex-linux-2026-11-25/summary.md](evals/codex-linux-2026-11-25/summary.md).

FEAT-143.2 ran `stuck-loop` and `time-limit` again, two fresh runs each with Codex (codex-cli 0.167.0 in a Linux container, `gpt-6.1-terra`) and Claude Code (2.1.331, `claude-sonnet-5-5`), on the skill text of FEAT-143.1, which routes a test that cannot pass to `reference/failures.md` before any change, says that a started node ends `[x]` or `[!]` and runs the agent's own scripts under the time limit and caps one session's work on a node at three times it. All 8 runs passed every assertion and ended blocked: the two Codex scenarios that failed on 2026-11-24 passed 4 of 4, and both Claude Code `time-limit` runs blocked after the red run on their own estimate, which the summary names as a likely effect of the new text ([summary](evals/stuck-worker-text-2026-11-25/summary.md)). The other ten scenarios were not rerun on this text.

### Limits of the earlier by-hand runs

- The executor of the three runs in the first table was not an independent fresh-context agent: the scenarios were executed by hand against the skill text. They show the lifecycle is executable and the assertions are satisfiable, not that an unprimed agent finds the same path. The fresh-agent runs above provide later evidence for Claude Code and Codex.
- The Python scenarios (`interrupted-merge`, `baseline-red`, and the others listed above) remain the evidence for resume and regression-failure behaviour; the three new scenarios have no red-baseline or interrupted-run variant yet.
- Parallel lanes ran sequentially by one executor (the documented no-subagent fallback), so concurrency itself was not exercised in this batch; [TASK-044](evals/lanes-codex-2026-11-08/summary.md) later exercised it with one Codex process per lane.
- Slips made during the runs and corrected before the commit: a Java test file was first named `SubtractTestTest` (fixed and amended so the `Done when` id `SubtractTest` is the one that ran); the multi-module claim recorded `baseline 1 passing` although the reactor has 2 tests (not corrected in the scratch repo).
- Reproduce with `bash tests/trials/setup.sh <dir> <scenario>`, follow `/todo-continue` (`--all-lanes --merge` for `multi-module`), then `bash tests/trials/assert.sh <dir> <scenario>`.

An entry here is added only after a real run, with the agent, date, pass or fail and the ambiguities the agent reported. Nothing on this page claims a result that was not observed.
