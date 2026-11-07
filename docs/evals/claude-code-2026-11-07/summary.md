# Independent Claude Code lifecycle evaluation, 2026-11-07

Evaluated commit: `7208627` (exported with `git archive`; `main` later moved to `194a982`, a docs-only backlog commit, which the evaluation did not use).
Executor: fresh `claude -p` processes (Claude Code 2.1.319, model `claude-sonnet-5-5`), one per scenario invocation, each started with `--setting-sources project,local --strict-mcp-config --no-session-persistence` so no user-level skills, plugins or MCP servers were loaded. The scratch project's own `.claude/skills` were the only todo skills available.
Verification: `tests/trials/assert.sh` run by the controller after each process ended, from the pinned export. The agents' own reports were not used as verdicts.
Independence: no Codex result was read before or during execution. `TASK-018` to `TASK-024` (Codex findings, commit `194a982`) were first read after all runs finished, for de-duplication only.

Data: [results.json](results.json) (all 38 runs), per-run folders in [runs/](runs/), checksums in [SHA256SUMS](SHA256SUMS). Logs are redacted (the local user name is replaced by `<user>`); checksums cover the redacted files.

## Environment

| Item | Value |
|---|---|
| OS | Windows 11 Pro 10.0.26300, Git Bash (MSYS2, bash 5.2.37) for all scripts, PowerShell not needed for orchestration |
| git | 2.51.0.windows.1, global `core.autocrlf=true` (LF to CRLF warnings appear in every scratch repo) |
| Python | 3.13.14 (Windows Store build); cp1252 default encoding |
| Node / npm | v24.16.0 / 12.0.2 (the scenario is written for Node 22; `--experimental-strip-types` worked) |
| Java / Maven | Java 25.0.2, Maven 3.9.11 (the scenarios target 17; the poms set `source/target 17`) |
| Scratch location | outside the checkout, under the session scratchpad `eval/runs/<label>/repo` |
| Agent flags | as `tests/trials/run-claude.sh`: `--permission-mode acceptEdits --allowedTools Bash,Read,Write,Edit,Glob,Grep --add-dir <repo>`, plus the isolation flags above and `--output-format stream-json --verbose`; 1500 s timeout |

Before any scenario: `bash tests/trials/selftest.sh` on the pinned export gave 23 passed, 1 failed (`blocked-sibling: setup failed`, finding F2). Authentication check: a trivial `claude -p` returned normally.

## Scenario results

Verdict is for the first run of the scenario with the exact prompt from `prompt.sh`. `Runs` counts all fresh sessions for that scenario (repeats and variants).

| Scenario | Verdict | Assertions | Runs | Notes |
|---|---|---|---|---|
| happy-path | PASS | 12/12 | 3 | 3/3 pass |
| baseline-red | PASS | 7/7 | 3 | 3/3 pass; nothing changed |
| interrupted-merge | PASS | 16/16 | 3 | 3/3 pass |
| race-claim-conflict | PASS | 13/13 | 3 | 3/3 pass |
| ts-lifecycle | **FAIL** | 7/13 | 1 (+2 continuation) | F1: prompt says stop after one invocation, assertion needs the whole tree merged. Passed 13/13 after two more fresh invocations |
| java-lifecycle | **FAIL** | 7/13 | 1 (+2 continuation) | same as ts-lifecycle |
| multi-module | PASS | 14/14 | 1 | Agent chose sequential lanes (no subagent call). `mvn` reactor green |
| ci-local | **INFRA_ERROR** | 12/13 | 2 | Claude Code denied the write to `.git/hooks/pre-push` in both runs; the skill printed the hook as documented. Only the hook check failed |
| refresh-from-base | PASS | 18/18 | 1 | |
| claimed-elsewhere | PASS | 15/15 | 3 | 3/3 pass |
| race-claim-benign | PASS | 13/13 | 3 | 3/3 pass |
| lanes | **INFRA_ERROR** | 8/15 | 5 | First run: host Python `tests` package shadowed the scratch `tests/` (F3); coordinator stopped. With `PYTHONNOUSERSITE=1`: 4/4 PASS, see below |
| monorepo | PASS | 16/16 | 1 | Agent added `tests/__init__.py` to get past the same shadowing |
| replan | PASS | 15/15 | 1 | |
| blocked-sibling | PASS | 11/11 | 3 | Needs `PYTHONUTF8=1` for setup (F2) |
| release-ask | PASS | 8/8 | 3 | 3/3 pass |
| release | PASS | 14/14 | 1 | Not requested; run as a bonus |

Not run: none of the requested scenarios was skipped. `no-git`, `add-fix`, `update-*`, `status-readonly`, `report` and `ci-github` were outside the request.

### Parallel versus sequential lanes (`lanes`, clean Python)

| Variant | Agent tool | Result | Evidence |
|---|---|---|---|
| `lanes-clean-par`, `-par-b`, `-par-c` | available | PASS 15/15 each | Two Agent calls per run; both `start` commits and both `feat` commits fall in the same seconds, then the merges follow (`git log --all --format='%ci %s'` in each run folder) |
| `lanes-clean-seq` | disabled (`--disallowedTools Agent`) | PASS 15/15 | 0 Agent calls, the skill's no-subagent fallback |

`multi-module` was executed sequentially by the agent although the Agent tool was available; genuine parallel `multi-module` was not exercised.

### Rates

- Requested eight scenarios, strict: 5 PASS, 2 FAIL, 1 INFRA_ERROR = **5/8 (62.5%)**.
- All 17 primary scenarios: 13 PASS, 2 FAIL, 2 INFRA_ERROR, 0 UNVERIFIED = **13/17 (76.5%)**.
- Independently verified assertions over the 17 primary runs: **206/226 (91.2%)**; over all 38 runs: 468/489 (95.7%).
- With the F1 mismatch corrected by continuation runs and the environment faults excluded (not counted as passes in the rates above), every scenario reaches its asserted state: ts-lifecycle and java-lifecycle after 3 invocations, lanes with `PYTHONNOUSERSITE=1`.
- Cost and time over all 38 runs: about 3,100 s of agent wall time and US$9.86 as reported by the CLI (token counts per run are in `results.json`).

## Verified defects

All three are reproducible from the evidence; none is a flaw in the skills' git flow itself. No fix was applied.

### F1 (P1) ts-lifecycle and java-lifecycle prompt contradicts their assertions
`prompt.sh` gives `Run /todo-continue --merge. Stop after one invocation.` for both. `/todo-continue` executes one node per invocation, so a root with two children needs three invocations (child 1, child 2, integration plus drain plus merge). The agent did exactly what was asked (it merged FEAT-001.1 and stopped), `assert.sh` then failed 6 of 13 checks. Continuation runs on the preserved repos: invocation 2 added child 2 (7/13 again), invocation 3 drained and merged to `main` (13/13), in both languages. `selftest.sh` cannot catch this because it never runs an agent. Evidence: `runs/ts-lifecycle/` (first run, `inv2/`, `inv3/`), `runs/java-lifecycle/`. Reproduce: `bash tests/trials/setup.sh <dir> ts-lifecycle`, give `bash tests/trials/prompt.sh <dir> ts-lifecycle` to a fresh agent, run `bash tests/trials/assert.sh <dir> ts-lifecycle`.

### F2 (P2) setup.sh fails for `blocked-sibling` on Windows
`setup.sh` patches `TODO.md` with `python3 - <<'PY2'` using `open(p).read()` and a pattern containing `·`. On Windows the default text encoding is cp1252, so the file is read as `Â·`, the replacement never matches, nothing is staged and `set -e` aborts at `git commit` ("nothing to commit"). `selftest.sh` reports 23 passed, 1 failed. With `PYTHONUTF8=1` the same setup succeeds. Evidence: `harness/selftest-default-encoding.txt` (23 passed, 1 failed), `harness/setup-blocked-sibling-default-encoding.txt` (setup aborts with "nothing to commit"; encoding cp1252), `harness/setup-blocked-sibling-pythonutf8.txt` (succeeds). Every scenario run in this evaluation set `PYTHONUTF8=1` for `setup.sh` only. Reproduce on Windows: `bash tests/trials/selftest.sh` (expect `FAIL  blocked-sibling: setup failed`).

### F3 (P2) No rule for a `Done when` that cannot run for an environmental reason; agents diverge
The scenarios use `python3 -m unittest tests.test_calc.CalcTest.test_x` with no `tests/__init__.py`. On this host another project is on `sys.path` (a `.pth` entry) and provides a regular package named `tests`, which wins over the scratch namespace package, so the command raises `ModuleNotFoundError: No module named 'tests.test_calc'`. Four agents hit it. Three (`happy-path`, `refresh-from-base`, `monorepo`) created an empty `tests/__init__.py`, which is a file outside the node's described scope, and each listed it as an ambiguity. The `lanes` coordinator stopped, citing "Forbidden: editing `Done when`" and refusing a narrower command. A subagent in that run also ran `python3 tests/test_calc.py CalcTest.test_subtract` as a substitute. Neither `reference/verification.md` nor `todo-continue` says which behavior is right. Evidence: `harness/python-tests-shadowing.txt`, `runs/lanes/agent-final-report.txt`, `runs/happy-path/agent-final-report.txt`, `runs/refresh-from-base/agent-final-report.txt`, `runs/monorepo/agent-final-report.txt`. Reproduce: any machine whose Python can import an unrelated regular package called `tests`; or `python3 -c "import tests"` outside any project shows it.

## Observations recorded but not turned into tasks

- `ci-local` always ends INFRA_ERROR under `run-claude.sh`: Claude Code's headless `acceptEdits` mode denies writes under `.git/hooks`. `README.md` in `tests/trials` documents this and `score.sh` has `TRIAL_SKIP`, but `run-claude.sh` calls `assert.sh` directly, so its exit status is non-zero regardless. Reproduced twice (`ci-local`, `ci-local-r2`, `permission_denials` in `result-event.json`).
- In the first `lanes` run the coordinator wrote its first claim edits to the wrong `TODO.md` lines and fixed them with an extra `chore(backlog): fix claim placement` commit on `main`. One occurrence in five runs; not reproduced.
- In `lanes-clean-par-b` the `claude -p` process stayed alive about 10 minutes after the work finished (a `ScheduleWakeup` fallback with 600 s). The result was correct; the cost is wall time. One occurrence.
- The lane scenarios leave an empty `<repo>.todo/` directory next to the scratch repo after worktree removal; the assertions only check `git worktree list`.
- `bash tests/run.sh` on the pristine pinned export (and on the evaluation branch) gives 127 passed, 1 failed: `plugin/skills/todo-report/template.md differs from tools/template.html: regenerate it`. It fails without any of this evaluation's changes on this Windows host; the cause (line endings or generator behavior) was not investigated, so no task was filed.
- `docs/trials.md` ("Limits of these runs") says launching nested headless agents was refused by the sandbox policy. In this environment nested `claude -p` runs worked. `docs/agent-compatibility.md` still says Claude Code lifecycle runs were by hand rather than by an unprimed fresh agent; these results are the first recorded fresh-process evidence. Both pages need updating by the maintainers; no task was filed for a doc update.
- Agent-reported ambiguities (quoted in each `agent-final-report.txt`) were mostly wording nits: lint without `.todo/todo-lint.sh` (the plugin ships Markdown only, so the lint is never present in a scratch project and agents check invariants by reading), merge-conflict handling in the interrupted-merge step, and the order of `Ref:` handling in lanes.

## Integrity checks

For every run the controller recorded, before `assert.sh`, the hash of the whole pinned harness tree and of the scratch project's `.claude/skills`; both were identical before and after in all 38 runs (files in `runs/<label>/`: `harness-hash-*.txt`, `skills-hash-*.txt` for primary runs). No scenario created tags or pushed (no remote exists; `assert.sh` checks tags). The lane scenarios created worktrees under `../<repo>.todo/`, which the prompt permits.

## Recommendations (no added complexity)

1. Fix F1 in the harness, not the skills: either let the prompt say how many invocations the scenario needs or have `assert.sh` accept the state after one invocation. Add a selftest check that compares prompt wording with the assertion.
2. Open files in `setup.sh` with an explicit encoding (F2); this alone makes the full selftest pass on Windows.
3. Add one sentence to `reference/verification.md` for F3: when a `Done when` fails before any test runs for a reason outside the task (import path, missing tool), stop and report it, or state exactly which scaffolding file is allowed. Today three of four agents improvised the same file and one stopped.
4. Make `run-claude.sh` pass `TRIAL_SKIP` through (or print INFRA_ERROR for a permission denial) so `ci-local` is not reported as a skill failure.
5. Record these runs in `docs/trials.md` and `docs/agent-compatibility.md` and remove the statement that nested agents cannot be launched.

## Follow-up (same day): fixes and re-validation

The three tasks filed from this evaluation were then implemented, together with four related harness tasks (`TASK-020` to `TASK-023`). Each fix was checked by a test script and, where an agent matters, by fresh sessions with the corrected harness (logs of these re-validation runs were not added to `runs/`):

| Finding | Task | Result after the fix |
|---|---|---|
| F1 prompt contradicts assertion | TASK-025 | `ts-lifecycle` and `java-lifecycle` each pass 13/13 in one fresh session with the new prompt ("run it again after each report until the root is merged") |
| F2 cp1252 setup failure | TASK-026 | `bash tests/trials/selftest.sh` gives 24 passed, 0 failed on this Windows host with no `PYTHONUTF8` override |
| F3 no rule for an unrunnable Done when | TASK-027 | `reference/verification.md` now says: add one empty scaffolding file inside the node's own folders and report it, otherwise stop and report "Done when cannot run" |
| (observation) baseline-red passed without a report | TASK-020 | a real `baseline-red` session passes 10/10 including the new report checks; silent, empty and wrong reports are rejected |
| (observation) lane evidence was only a clean worktree count | TASK-021 | hook-based `lane-evidence.sh`: a real `lanes` session passes 16/16 and a real `multi-module` session 15/15, both `execution: overlapping` |
| (observation) INFRA vs PASS in scoring | TASK-022 | `score.sh` reports PASS, FAIL, INFRA_ERROR and UNVERIFIED and counts every scenario |
| (observation) evidence overwritten | TASK-023 | `run-claude.sh` writes one checksummed folder per invocation |

`TASK-018`, `TASK-019` and `TASK-024` need a logged-in Codex and were not attempted.
