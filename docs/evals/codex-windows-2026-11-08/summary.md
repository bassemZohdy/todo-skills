# Windows Codex lifecycle trials with the isolated verifier, 2026-11-08 (TASK-045)

The eight lifecycle scenarios of the [2026-11-07 batch](../codex-2026-11-07/summary.md), repeated on the same host
(Windows 11 Pro 10.0.26300, Git Bash, codex-cli 0.167.0, model `gpt-6.1-terra`) with the controller at
`533b2bb` (`controller-sha.txt`). Each scenario ran in fresh `codex exec` sessions in the unelevated workspace-write
sandbox, as before. What changed is the controller's side: every assertion ran through `windows-assert-exec.sh` in the
elevated Codex sandbox ([FIX-041](../fix-041.md)), with no network, the login and other runs denied, and Python from a
regular installation (FIX-052). The first line of each `assert.log` names that verifier.

## Result

| Scenario | Outcome | Assertions | Cause |
|---|---|---|---|
| baseline-red | **PASS** | 10/10 | reported the red baseline, the failing test and a FIX suggestion; nothing changed |
| interrupted-merge | **PASS** | 16/16 | finished the pending `--no-ff` merge |
| happy-path | INFRA_ERROR | 8/12 | Git could not create `.git/refs/heads/todo/FEAT-001-...` in the agent's sandbox; the agent stopped at the claim |
| race-claim-conflict | INFRA_ERROR | 11/13 | the same ref-directory block at the claim |
| ts-lifecycle | INFRA_ERROR | 9/13 | baseline `npm test` passed; then the same ref-directory block (first invocation) |
| java-lifecycle | INFRA_ERROR | 5/5, then timeout | Maven in the agent's sandbox could not read `junit-jupiter-engine-5.10.2.jar` from the host cache ("Access is denied"), so the agent stopped at a broken baseline; the verifier then timed out (124) |
| multi-module | INFRA_ERROR | 5/5, then timeout | the same Maven block before either lane started; verifier timeout (124) |
| ci-local | INFRA_ERROR | 12/13 | `.git` is read-only in the sandbox, so the agent could not write `.git/hooks/pre-push`; it gave the user the hook to install |

**2 PASS, 0 FAIL, 6 INFRA_ERROR, 0 UNVERIFIED.** That is the same split as 2026-11-07. No skill failure was observed. Every INFRA_ERROR has its matching line in `runs/<scenario>/infra-signature.txt`, or a verifier exit of 124. In each one the agent reported the block and stopped, as the skills say to. These runs say nothing about the lifecycle of the skills under Codex on Windows: Codex's unelevated Windows sandbox still blocks the branch, worktree and hook writes that lifecycle needs. A Codex agent run in the elevated sandbox, which can grant `.git` writes, was not tried; it is the likeliest way to get full lifecycle runs on Windows.

`score.txt` is the score written at the end of the batch. Its re-verification of interrupted-merge exited 127 once, while
the host was short of memory, so it reads 1 PASS. Repeating that verification gave 16/16 (`rescore-interrupted-merge.log`),
and a second full scoring agrees with every run's own verdict (`score-rerun.txt`).

## Environment set up for the agents

`batch.sh` records all of it, and `environment.txt` has the versions.

- The Microsoft Store `python3` alias could not be started in either sandbox ("The system cannot execute the specified
  program", "The file cannot be accessed by the system"). The agents got a venv of the regular Python 3.13.7 install first
  on `PATH`, with a `python3.exe` beside `python.exe`. The verifier got `TRIAL_PYTHON` (FIX-052). `PYTHONNOUSERSITE=1`
  keeps a host package named `tests` from shadowing the scenarios' tests.
- Maven resolved its local repository as `C:\.m2` in the agents' sandbox. `MAVEN_OPTS` names the host cache, which was
  filled beforehand outside any sandbox (`warm-*.log`). Reading one of its jars was still denied in the sandbox, which is
  the java-lifecycle and multi-module block above. In the verifier, Maven's launcher also could not enter the user
  profile to look for `.mvn`. Making Maven usable in both sandboxes would mean changing the host's ACLs, which was not done.

## Attempts

- **Attempt 1** (`diagnostics/attempt-1/`, controller `1f96cea`): 0 PASS, 4 FAIL, 4 INFRA_ERROR. Three FAILs came from the
  agent's sandbox being unable to start the Store `python3`. The agents correctly stopped at a test command that could not
  run, but `infra-signature.sh` did not know the Windows messages. ci-local's "does not permit writes under `.git`" was
  missed the same way. The harness fix (`fix(trials): read Windows program, Maven and .git-hook blocks as
  infrastructure`) and the agent Python above led to attempt 2. Its reports, outcomes and assertion logs are kept;
  repositories are not.
- **Attempt 2** (`runs/`): the results above.

Two ambiguities the agents reported: `/todo-init` "Do not run the suite" against the CI reference's "run it once after
writing" (ci-local), and continue's "Baseline" pointing at verification step 6 while the reference calls step 1
"Baseline" (java-lifecycle).

## Verify

`bash tests/trials/test-windows-codex-evidence.sh` checks the checksums and the eight scenarios with
`test-codex-evidence.sh` (fresh sessions, and verdicts that agree with their exit codes and signatures). It also checks
that every assertion log ran in the elevated Windows verifier, that every non-PASS verdict has a cause, the multi-node
controllers, and that no user name is left in a path. The user name in host paths is redacted to `<user>`; per-run
checksums were rebuilt over the redacted files. It runs no agent.
