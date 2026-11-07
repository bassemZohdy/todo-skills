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

### Limits of these runs

- The executor was not an independent fresh-context agent. Launching nested headless agents (`tests/trials/run-claude.sh`) was refused by the sandbox's permission policy, so the scenarios were executed by hand against the skill text. They show the lifecycle is executable and the assertions are satisfiable, not that an unprimed agent finds the same path.
- The Python scenarios (`interrupted-merge`, `baseline-red`, and the others listed above) remain the evidence for resume and regression-failure behaviour; the three new scenarios have no red-baseline or interrupted-run variant yet.
- Parallel lanes ran sequentially by one executor (the documented no-subagent fallback), so concurrency itself was not exercised.
- Slips made during the runs and corrected before the commit: a Java test file was first named `SubtractTestTest` (fixed and amended so the `Done when` id `SubtractTest` is the one that ran); the multi-module claim recorded `baseline 1 passing` although the reactor has 2 tests (not corrected in the scratch repo).
- Reproduce with `bash tests/trials/setup.sh <dir> <scenario>`, follow `/todo-continue` (`--all-lanes --merge` for `multi-module`), then `bash tests/trials/assert.sh <dir> <scenario>`.

An entry here is added only after a real run, with the agent, date, pass or fail and the ambiguities the agent reported. Nothing on this page claims a result that was not observed.
