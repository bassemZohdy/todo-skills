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
| `ts-lifecycle`, `java-lifecycle`, `multi-module` | Claude Code | not run | Harness self-test passes; no agent run has been recorded yet. |

An entry here is added only after a real run, with the agent, date, pass or fail and the ambiguities the agent reported. Nothing on this page claims a result that was not observed.
