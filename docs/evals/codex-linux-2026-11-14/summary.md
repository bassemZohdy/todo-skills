# Codex in Linux containers, on the revised skill text (2026-11-14)

> Only this summary is published. The evidence of these runs (prompts, session logs, Git state) stays with the maintainer; paths below that point into it no longer exist in the repository.

TASK-116 reran the trial scenarios with Codex on the skill text as revised on 2026-11-13 (the text after TASK-110, FIX-114 and FIX-115), which Codex had not seen: the earlier Codex batches are [2026-11-07](../codex-2026-11-07/summary.md) and [2026-11-08](../codex-linux-2026-11-08/summary.md). Each scenario ran in a Docker container with a fresh Codex CLI 0.167.0 session on `gpt-6.1-terra`, one run per scenario, using the method of [`tests/trials/codex-linux.md`](../../../tests/trials/codex-linux.md). The tested commit is `6de470f`. Host: Windows 11 with Docker Desktop; the container is Debian with Python 3 and Node 22.

## Result

27 of 34 scenarios ran: **24 passed, 3 failed**, 324 final assertions passed and 3 failed. Seven scenarios did not run (below).

| Result | Scenarios |
|---|---|
| PASS (24) | happy-path, baseline-red, interrupted-merge, race-claim-conflict, race-claim-benign, refresh-from-base, claimed-elsewhere, release-ask, release, replan, ci-github, ci-local, no-git, update-block, update-drop, status-readonly, report, blocked-sibling, leftover-work, plan-stop, decompose, regress-block, ts-baseline-red, ts-interrupted |
| FAIL (3) | add-fix (11/12), monorepo (15/16), dirty-tree (10/11) |
| Not run (7) | team-claim, java-lifecycle, java-baseline-red, java-interrupted, ts-lifecycle, multi-module, lanes |

The three new scenarios of TASK-113 passed on Codex too: `plan-stop` 12/12, `decompose` 11/11, `regress-block` 11/11.

## The three failures

Each is one failed assertion; none is a crash, and all three agents followed the skill. They are the assertion's wording against what the agent did, so they are recorded as FAIL, not changed to pass.

| Scenario | Failed assertion | What the agent did |
|---|---|---|
| add-fix | "its Done when targets a test id" (expects `python3 -m unittest tests.test_calc.<Class>.test_x`) | Wrote the command as `cd tests && python3 -m unittest test_calc.CalcTest.test_add_none`: a valid test id, run from inside `tests/` |
| monorepo | "a power test exists on main" (expects `def test_power`) | Named the test `test_feat_001_power`, as the skill asks (the ID in the test name); the test exists and passes |
| dirty-tree | "report says the tree is not clean" (expects the words clean or uncommitted) | Stopped at the ready check, left nothing changed, and asked the user to commit or stash or use `--worktree`, without those words |

TASK-124 then aligned the three assertions (the `cd tests &&` form, a test name that carries the ID, the words "working tree"). The same three repositories and reports, scored again with the aligned assertions, pass 12/12, 16/16 and 11/11. That changes the scoring after the fact, so the result of this batch stays 24 of 27 with the assertions as they were during the run.

## Not run

- **team-claim:** its setup clones through a bare remote at an absolute host path, which a container cannot read.
- **java-lifecycle, java-baseline-red, java-interrupted, multi-module:** need the Maven image (`tests/trials/Dockerfile.codex-linux-maven`) and a prepared dependency cache.
- **ts-lifecycle:** needs one fresh session per node, which this batch's runner does not do.
- **lanes:** needs one Codex process per lane (`run-codex-lanes.sh`).

## Setup problems met

- The first assertions ran without the agent's report, so the report-based checks failed on every run. The report is the last agent message of the session; the assertions were rerun with it, on the same repositories.
- The host's Python shadowed the test package `tests` of `refresh-from-base` (a package in the user site beat the scratch repository's package without `__init__.py`). With `PYTHONNOUSERSITE=1` it passed, 18/18.
- `no-git` needs `--skip-git-repo-check`; without it Codex refuses to start outside a repository. The first attempt (exit 1, no work done) was set aside and the scenario rerun with the flag: PASS, 5/5.
- The skill files in the scratch repositories had CRLF line endings, as in the Windows checkout; the agents read them without trouble.

## Limits

One run per scenario, one agent and model, provisional isolation: the assertions ran on the host without the isolated verifier, and the container profile is the one of the 2026-11-08 batch. Codex was told the skills' folder explicitly (`.claude/skills`), as in the earlier batches; discovery from `.agents/skills` was not retested. The seven scenarios that did not run are not covered by this batch.
