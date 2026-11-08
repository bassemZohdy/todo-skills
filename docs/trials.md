# Lifecycle trials

The trials in `tests/trials/` give a fresh agent a scratch project in a known starting state, let it follow the skills, and check what it left behind with `assert.sh`. `bash tests/trials/selftest.sh` (also run in CI) checks the harness without an agent: every scenario must set up, and doing nothing must fail it (except the read-only scenarios).

## Scenarios

| Area | Scenarios | Toolchain |
|---|---|---|
| Plan | `replan` | Python |
| Execution and merges | `happy-path`, `ts-lifecycle`, `java-lifecycle` | Python; Node 22; Java 17 + Maven |
| Resume | `interrupted-merge`, `refresh-from-base`, `blocked-sibling` | Python |
| Parallel lanes | `lanes`, `multi-module` | Python; Maven multi-module |
| Regression failure | `baseline-red` | Python |
| Claims and races | `claimed-elsewhere`, `race-claim-conflict`, `race-claim-benign` | Python |

`ts-lifecycle` (TypeScript, `node:test`, no dependencies), `java-lifecycle` (Maven, JUnit 5) and `multi-module` (two Maven modules, two lanes, one reactor build as the regression suite) were added after 0.3.0 so the skills are exercised outside Python. Scratch projects are built from plain files, so nothing is downloaded except JUnit and the Maven plugins on a first Maven run.

## Run one

```bash
bash tests/trials/run-claude.sh /tmp/runs ts-lifecycle     # fresh Claude Code agent, then assert.sh
bash tests/trials/score.sh /tmp/runs                       # trial score over a batch
```

`run-claude.sh` starts `claude -p` with edits accepted and the Bash, Read, Write, Edit, Glob and Grep tools allowed, so run it only in a throwaway environment. To use another agent, run `setup.sh`, give that agent the output of `prompt.sh`, then run `assert.sh`.

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

Fresh `codex exec` processes via `tests/trials/run-codex.sh` (codex-cli 0.167.0, Windows 11). Details, evidence and the sandbox findings: [docs/evals/codex-2026-11-07/summary.md](evals/codex-2026-11-07/summary.md).

| Scenario | Result |
|---|---|
| `baseline-red`, `interrupted-merge` | Pass (10/10, 16/16) |
| `happy-path`, `race-claim-conflict`, `ts-lifecycle`, `java-lifecycle`, `multi-module`, `ci-local` | INFRA_ERROR: the sandbox blocked Git branch creation, Node child processes or `.git/hooks`; the cause is recorded per run and none is counted as a skill failure |

### Linux Codex runs (2026-11-08)

Fresh Codex CLI 0.167.0 sessions using `gpt-6.1-terra` in Linux containers passed all eight scenarios (105/105 final assertions). TypeScript and Java used a fresh session per node. The multi-module lanes ran sequentially; the event heuristic's `overlapping` output is not proof of concurrent agents. Clean installations with and without optional tools passed, and a scratch clone of an existing project completed a feature after an explicit backlog-commit workaround. Results are provisional because the sandbox boundary has not had a full adversarial audit. Prompts, logs, exit codes, Git state, failures and checksums are in [the Linux evidence](evals/codex-linux-2026-11-08/summary.md).

### Limits of the earlier by-hand runs

- The executor of the three runs in the first table was not an independent fresh-context agent: the scenarios were executed by hand against the skill text. They show the lifecycle is executable and the assertions are satisfiable, not that an unprimed agent finds the same path. The fresh-agent runs above provide later evidence for Claude Code and Codex.
- The Python scenarios (`interrupted-merge`, `baseline-red`, and the others listed above) remain the evidence for resume and regression-failure behaviour; the three new scenarios have no red-baseline or interrupted-run variant yet.
- Parallel lanes ran sequentially by one executor (the documented no-subagent fallback), so concurrency itself was not exercised.
- Slips made during the runs and corrected before the commit: a Java test file was first named `SubtractTestTest` (fixed and amended so the `Done when` id `SubtractTest` is the one that ran); the multi-module claim recorded `baseline 1 passing` although the reactor has 2 tests (not corrected in the scratch repo).
- Reproduce with `bash tests/trials/setup.sh <dir> <scenario>`, follow `/todo-continue` (`--all-lanes --merge` for `multi-module`), then `bash tests/trials/assert.sh <dir> <scenario>`.

An entry here is added only after a real run, with the agent, date, pass or fail and the ambiguities the agent reported. Nothing on this page claims a result that was not observed.
