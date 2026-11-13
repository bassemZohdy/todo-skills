# Lifecycle trials

The trials in `tests/trials/` give a fresh agent a scratch project in a known starting state, let it follow the skills, and check what it left behind with `assert.sh`. `bash tests/trials/selftest.sh` (also run in CI) checks the harness without an agent: every scenario must set up, and doing nothing must fail it (except the read-only scenarios).

## Scenarios

| Area | Scenarios | Toolchain |
|---|---|---|
| Plan | `replan` | Python |
| Execution and merges | `happy-path`, `ts-lifecycle`, `java-lifecycle` | Python; Node 22; Java 17 + Maven |
| Resume | `interrupted-merge`, `refresh-from-base`, `blocked-sibling` | Python |
| Parallel lanes | `lanes`, `multi-module` | Python; Maven multi-module |
| Regression failure | `baseline-red`, `ts-baseline-red`, `java-baseline-red` | Python; Node 22; Java 17 + Maven (the TypeScript and Java ones have pi runs only, below) |
| Interrupted run | `interrupted-merge`, `ts-interrupted`, `java-interrupted` | Python; Node 22; Java 17 + Maven (same note) |
| Uncommitted work on the base | `leftover-work`, `dirty-tree` | Python |
| Plan stop, breakdown, and a node blocked by a regression it cannot fix | `plan-stop`, `decompose`, `regress-block` | Python; pi runs only, below |
| Claims and races | `claimed-elsewhere`, `race-claim-conflict`, `race-claim-benign` | Python |
| Team use (two clones, one bare remote) | `team-claim` | Python; pi runs only, below |
| Project setup | `monorepo`, `no-git`, `ci-github`, `ci-local` | Python (`make test` in `monorepo`); no repository; GitHub remote or none |
| Backlog commands | `add-fix`, `update-block`, `update-drop` | Python |
| Release and read-only views | `release`, `release-ask`, `status-readonly`, `report` | Python |

The expected end state of every scenario is in the table in [tests/trials/README.md](../tests/trials/README.md).

`ts-lifecycle` (TypeScript, `node:test`, no dependencies), `java-lifecycle` (Maven, JUnit 5) and `multi-module` (two Maven modules, two lanes, one reactor build as the regression suite) were added after 0.3.0 so the skills are exercised outside Python. Scratch projects are built from plain files, so nothing is downloaded except JUnit and the Maven plugins on a first Maven run.

## Run one

```bash
bash tests/trials/run-claude.sh /tmp/runs ts-lifecycle     # fresh Claude Code agent, then assert.sh
bash tests/trials/run-codex.sh ~/todo-trials baseline-red  # fresh Codex agent (keep the folder outside the Windows temp folder)
bash tests/trials/score.sh /tmp/runs                       # trial score over a batch
```

`run-claude.sh` starts `claude -p` with edits accepted and the Bash, Read, Write, Edit, Glob and Grep tools allowed, so run it only in a throwaway environment. `run-codex.sh` is the Codex twin and confines the agent's writes to the scratch repository. To use another agent, run `setup.sh`, give that agent the output of `prompt.sh`, then run `assert.sh`. Each scenario ends in one verdict: PASS, FAIL, INFRA_ERROR (the environment stopped the agent) or UNVERIFIED (no record that an agent ran); only PASS counts in the score. The harness checks that need no agent are listed in [tests/trials/README.md](../tests/trials/README.md#harness-checks); CI runs them.

## Results

| Scenario | Agent | Date | Result |
|---|---|---|---|
| `ts-lifecycle` | Claude (the interactive session that maintains this repo, following `plugin/skills/todo-continue/SKILL.md` and `todo/reference/git-flow.md` by hand) | 2026-11-07 | Pass: `assert.sh` 13/13. Plan tree FEAT-001 with 2 children; red (missing export), green, `--no-ff` merges, integration `npm test` 3 passing, drain, merge to main. |
| `java-lifecycle` | same | 2026-11-07 | Pass: `assert.sh` 13/13. Red was a Maven compilation error (`cannot find symbol`), green via `-Dtest=...Test -Dsurefire.failIfNoSpecifiedTests=true`, reactor 3 tests passing. |
| `multi-module` | same | 2026-11-07 | Pass: `assert.sh` 14/14. Two lanes (core, text) in separate worktrees, claims fast-forwarded on main, second lane refreshed from main after the first landed (no conflict), both drained, worktrees removed. |

### Fresh-agent runs (independent evaluation, 2026-11-07)

Fresh `claude -p` processes (Claude Code 2.1.319, `claude-sonnet-5-5`, Windows 11 with Git Bash), each checked by `assert.sh` from the controller. Full results, logs and checksums: [docs/evals/claude-code-2026-11-07/summary.md](evals/claude-code-2026-11-07/summary.md).

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

Fresh Codex CLI 0.167.0 sessions using `gpt-6.1-terra` in Linux containers passed all eight scenarios (105/105 final assertions). TypeScript and Java used a fresh session per node. The multi-module lanes ran sequentially; the event heuristic reported `overlapping`, which is not proof of concurrent agents, and `lane-evidence.sh` has since been changed to report `unverified` for worktree events alone (FIX-036). A later run with one fresh Codex process per lane (`run-codex-lanes.sh`) recorded both workers' tool activity overlapping for 75 s and passed 15/15 ([TASK-044](evals/lanes-codex-2026-11-08/summary.md)). Clean installations with and without optional tools passed, and a scratch clone of an existing project completed a feature after an explicit backlog-commit workaround (the underlying `/todo-add` then `/todo-continue` gap is fixed by [FIX-035](evals/fix-035.md); the same feature on the same project then passed on the first attempt with no commit between the sessions, [TASK-043](evals/eval-skills-2026-11-08/summary.md)). A later [boundary audit](evals/linux-boundary-2026-11-08.md) with dummy login and evidence sentinels passed its probes (reads and writes of the login, evaluator and evidence, symlink escape and loopback network all denied; scratch Git allowed) and the controller's assertions now run through `assert-exec.sh`, which confines project test processes in the Linux profile. It is not a proof of complete isolation, and multi-node TypeScript and Java trials now run one fresh Codex process per invocation (`run-codex-multi.sh`), so the results stay provisional. Prompts, logs, exit codes, Git state, failures and checksums are in [the Linux evidence](evals/codex-linux-2026-11-08/summary.md); the [independent CI verification](evals/codex-linux-2026-11-08/ci-verification.md) checked the retained evidence on Ubuntu and macOS, and [how to reproduce the batch](evals/codex-linux-2026-11-08/reproduce.md) is kept beside it.

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

### Limits of the earlier by-hand runs

- The executor of the three runs in the first table was not an independent fresh-context agent: the scenarios were executed by hand against the skill text. They show the lifecycle is executable and the assertions are satisfiable, not that an unprimed agent finds the same path. The fresh-agent runs above provide later evidence for Claude Code and Codex.
- The Python scenarios (`interrupted-merge`, `baseline-red`, and the others listed above) remain the evidence for resume and regression-failure behaviour; the three new scenarios have no red-baseline or interrupted-run variant yet.
- Parallel lanes ran sequentially by one executor (the documented no-subagent fallback), so concurrency itself was not exercised in this batch; [TASK-044](evals/lanes-codex-2026-11-08/summary.md) later exercised it with one Codex process per lane.
- Slips made during the runs and corrected before the commit: a Java test file was first named `SubtractTestTest` (fixed and amended so the `Done when` id `SubtractTest` is the one that ran); the multi-module claim recorded `baseline 1 passing` although the reactor has 2 tests (not corrected in the scratch repo).
- Reproduce with `bash tests/trials/setup.sh <dir> <scenario>`, follow `/todo-continue` (`--all-lanes --merge` for `multi-module`), then `bash tests/trials/assert.sh <dir> <scenario>`.

An entry here is added only after a real run, with the agent, date, pass or fail and the ambiguities the agent reported. Nothing on this page claims a result that was not observed.
