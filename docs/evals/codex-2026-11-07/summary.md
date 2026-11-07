# Codex lifecycle trials, 2026-11-07

Eight lifecycle scenarios run by fresh `codex exec` processes (codex-cli 0.167.0, logged in with ChatGPT, model `gpt-6.1-terra`, Windows 11, Git Bash for the scripts), each checked afterwards by the controller's `tests/trials/assert.sh`. Evidence per scenario is in [runs/](runs/) (prompt, session log, session id, exit codes, report, assertion output, Git state, outcome, checksums), the machine-readable table is [results.json](results.json) and the whole folder is covered by [SHA256SUMS](SHA256SUMS). The user name is redacted in the logs and the per-run checksums were rebuilt over the redacted files. `bash tests/trials/test-codex-evidence.sh` verifies all of this.

Commit under test: `a0a546b` plus the harness changes of this change set (`run-codex.sh`, `codex-exec.sh`, `infra-signature.sh`, `snapshot-git.sh`). Python scenarios ran with `PYTHONNOUSERSITE=1` (another project on this host's Python path shadows a package named `tests`; see `docs/evals/claude-code-2026-11-07/summary.md`).

## Result

| Scenario | Outcome | Assertions | Why |
|---|---|---|---|
| baseline-red | **PASS** | 10/10 | reported the red baseline, the failing test and a FIX suggestion; nothing changed |
| interrupted-merge | **PASS** | 16/16 | finished the pending `--no-ff` merge |
| happy-path | INFRA_ERROR | 8/12 | `git` could not create `.git/refs/heads/todo/FEAT-001-...` |
| race-claim-conflict | INFRA_ERROR | 11/13 | same ref-directory error at the claim step |
| ts-lifecycle | INFRA_ERROR | 9/13 | stopped at the baseline: Node's test runner failed with `spawn EPERM` (child processes are blocked) |
| java-lifecycle | INFRA_ERROR | 9/13 | same `.git` ref-directory error |
| multi-module | INFRA_ERROR | 9/15 | `.git` read-only for the lane claims and worktrees |
| ci-local | INFRA_ERROR | 12/13 | cannot write `.git/hooks/pre-push`; Git Bash `chmod` failed with `Win32 error 5` |

Strict totals: 2 PASS, 0 FAIL, 6 INFRA_ERROR, 0 UNVERIFIED of 8 (25%). The six INFRA_ERRORs are **not** skill failures and **not** passes: in each the agent reported the block, and `tests/trials/infra-signature.sh` found the matching line in its output (kept in `runs/<scenario>/infra-signature.txt`). They also say nothing about whether the skills would work for Codex outside this sandbox. The lifecycle behaviour of Codex with the skills (branch, claim, build, merge, drain) was therefore **not** exercised here; only the two scenarios that need no new branch ran to the end.

## What the Codex sandbox allows on this host (`TASK-018`)

Measured with `tests/trials/test-codex-isolation.sh` (10 checks, passed in 2 of 2 consecutive runs) and probes kept in the notes below:

- Writes are confined to the workspace when the temp-folder exemptions are switched off (`sandbox_workspace_write.exclude_tmpdir_env_var=true`, `exclude_slash_tmp=true`) and the scratch project is **outside the Windows temp folder**. Overwriting a "controller" file, creating and overwriting files in an "evidence" folder, and creating a file beside the repo were all denied, and the checksums were unchanged.
- **Reads are not isolated.** The unelevated Windows sandbox refuses split read restrictions ("cannot enforce split filesystem read restrictions directly; refusing to run unsandboxed"), and in a run the agent read the controller file. Evidence integrity therefore rests on write denial and SHA256SUMS, not on secrecy.
- Git inside the sandbox can commit, but cannot reliably create branches (`refs/heads/todo/...` fails with "unable to create directory") and the answer for `git worktree add` varied between runs. This is what turned the other scenarios into INFRA_ERROR.
- Options tried and rejected: adding `<repo>/.git` as a writable root made the sandbox allow writes anywhere (a sibling folder and a controller file were overwritten); moving the Git directory out with `git init --separate-git-dir` made `git worktree list` print the git directory as the "main checkout", and the skills stopped on that rule in four scenarios; a container folder as workdir (`--skip-git-repo-check`) also allowed writes outside it. After earlier sandbox runs under the Windows temp folder, writes anywhere under it stopped being denied (seen twice), hence the rule to keep trials elsewhere.
- Not tried: running Codex inside WSL (the Linux sandbox has different `.git` semantics), or the elevated Windows sandbox. Those are the likeliest ways to get full lifecycle runs.

## Skill discovery and invocation (`TASK-024`)

Measured with `tests/trials/test-codex-invocation.sh` (4 checks, passed in 2 of 2 runs; each case is a fresh session and the verdict comes from the session log, not the agent's words, except the skill lists):

| Case | Observation |
|---|---|
| Skills in `<project>/.agents/skills` | All nine skills are listed as available |
| Skills in `<project>/.codex/skills` (probe) | All nine listed |
| Skills only in `<project>/.claude/skills` | **None** listed. Codex does not read Claude Code's folder, which is why the trial prompt tells the agent to open `.claude/skills/<name>/SKILL.md` by hand |
| Prompt `$todo-status` | The skill runs: its `SKILL.md` is opened, the backlog is printed, nothing changes |
| Prompt `/todo-status` in `codex exec` | No Codex slash-command handler was observed. With no skills in the project (probe) the text was taken as a file path (`C:\Program Files\Git\todo-status`). With the skills installed, the model itself mapped it to the skill in both runs, so it worked, but through the model's reading of the skills catalog, not a command |
| Plain language ("What is the status of my backlog?") | The model selected the `todo-status` skill from its description (both runs) |

So for Codex the documented `/todo-*` form is not a guaranteed entry point in `codex exec`; `$todo-status` (explicit mention) and plain language are. Interactive TUI slash handling was not tested.

## Reproduce

```bash
export PYTHONNOUSERSITE=1                       # Python scenarios on a host with a shadowing `tests` package
bash tests/trials/run-codex.sh ~/todo-trials baseline-red      # one scenario; runs dir outside the temp folder
bash tests/trials/test-codex-isolation.sh                       # TASK-018
bash tests/trials/test-codex-invocation.sh                      # TASK-024
bash tests/trials/test-codex-evidence.sh                        # TASK-019: validates this folder
```

Earlier diagnostic runs that led to the design above are not part of the evidence: two batches on a layout with the Git directory moved out (4 of 8 scenarios stopped on the worktree-list rule), and two batches before the infrastructure classifier existed (same agent behaviour, labelled FAIL instead of INFRA_ERROR).
