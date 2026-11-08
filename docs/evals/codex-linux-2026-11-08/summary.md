# Linux Codex lifecycle trials, 2026-11-08

Eight scenarios ran in separate scratch repositories using fresh Codex CLI 0.167.0 sessions with model `gpt-6.1-terra`. The tested project commit was `3a8b215ef3fc1b06ec2759d700151ee944000043`; the controller also had an uncommitted line-ending fix in `tests/run.sh`. Production skills and trial assertions were unchanged. The controller ran the assertions outside the agent. The multi-module assertion was additionally run in a separate, network-disabled Linux container with a read-only copy of the committed verifier.

| Scenario | Verdict | Assertions |
|---|---|---:|
| happy-path | PASS | 12/12 |
| baseline-red | PASS | 10/10 |
| interrupted-merge | PASS | 16/16 |
| race-claim-conflict | PASS | 13/13 |
| ts-lifecycle | PASS | 13/13 |
| java-lifecycle | PASS | 13/13 |
| multi-module | PASS | 15/15 |
| ci-local | PASS | 13/13 |

Total: 8/8 scenarios and 105/105 final assertions. TypeScript and Java each used three distinct sessions, one per skill invocation. Each received the exact generated prompt plus a higher-priority controller instruction to stop after one invocation; earlier sessions and assertions are retained under `runs/<scenario>/invocations/`.

The multi-module agent used the sequential fallback. The lane-evidence script reported `overlapping`, including under the separate Linux verifier, because its first-to-last worktree event intervals overlap. Those events establish worktree use, not concurrent agent execution. This is a false-positive concurrency classification and must not be used as evidence of genuine parallel execution.

## Boundary and limitations

The agent container mounted only its scratch workspace, the prompt, runner, and a dedicated Codex login volume; it did not mount the evaluator or evidence. The Codex Linux permission profile denied agent-shell reads of the login, prompt, and runner, allowed scratch Git metadata, and disabled agent-shell networking. A dummy-only probe denied reads of protected sentinels while allowing a scratch commit and branch. Docker's default seccomp filter prevented sandbox namespace creation; the successful runs used `seccomp=unconfined` with the Codex sandbox. This boundary has not had a full adversarial audit, so these results are provisional.

Diagnostics retain the profile-syntax failure, the first happy-path stopped by Windows/Linux line-ending differences, the initial multi-module Maven PATH failure, and two containers stopped with exit 137 after a shared writable dependency cache was noticed. Subsequent runs used separate scratch repositories and separate caches. The first Maven preflight had a PowerShell quoting failure; the retry passed. Two verifier extraction attempts failed due to path quoting and Windows permissions; the first Linux verifier failed on CRLF. A committed LF verifier then passed. Diagnostic and session logs are UTF-8 normalized and host user paths redacted; prompts were not changed. No credential material was intentionally included.

Each scenario contains its generated prompt, runner, raw JSON event stream in `session.log`, report, session ID, exit codes, independent assertion output, Git state, starting commit, and SHA-256 manifest. Root `SHA256SUMS` covers the bundle. The six previous infrastructure-blocked scenarios all passed in this batch; the two previously passing scenarios were also rerun.

The first evidence-checker run failed because outcome.txt files were omitted during packaging; they were added before final verification.

A prompt-byte verification initially failed when Git Bash could not create a sandboxed signal pipe; an authorized retry confirmed all eight stored prompts exactly match prompt.sh. File timestamps in results.json are filesystem times for the final session log.


## Clean installation and optional tools

Two additional scratch repositories installed the nine Markdown-only skill folders under `.agents/skills`. In a fresh discovery session each listed all nine. A separate fresh session then ran `$todo-continue --merge`; both the no-tools and optional-tools variants passed all 12 happy-path assertions. The optional-tools session also executed `.todo/todo-lint.sh` and `.todo/check.sh` successfully before merging. Each discovery and task session, prompt, exit code, Git state and assertion output is retained under `installations/`.

For the optional-tools setup the controller copied the committed LF version of `tools/todo-lint.sh` to `.todo/todo-lint.sh` and created `.todo/check.sh` to run that lint and `python3 -m unittest discover -s tests`. Both installed files are retained in `installations/with-tools/installed-tools/`. A first attempt copied the Windows CRLF checkout of the lint script into Linux; Bash could not run it and the agent stopped before work. That attempt is retained in `diagnostics/install-with-tools-crlf/`. The successful retry used a fresh repository and the LF source. These installation runs were separate from the eight-scenario totals above.


## Representative existing-project trial

The controller cloned `bassemZohdy/eval-skills` at `1d4040b6584c94ae7143534911835f5b9053d3de` into a scratch repository. The scoped feature added a `--list` option to `scripts/sync_shared.py` to print the 14 managed target paths deterministically without changing them. The original checkout was not modified. Four fresh Codex sessions performed initialization, task creation, an initial continue, and a continue retry. Their prompts, JSON event streams, exit codes, and Git snapshots are in `representative-eval-skills/`.

The first continue did not start: `todo-add` left the newly created root uncommitted, but `todo-continue` required that root to exist in committed `main:TODO.md`. This conflicts with the documented workflow in which the first claim commits pending backlog edits. The retry explicitly instructed a scratch-only commit of `TODO.md` and `CHANGELOG.md` before invoking continue; it then completed and merged the feature in scratch commit `ceb81962dea68bc980b6420e4772f43ef2a5b2c3`. This is a pass **with a workaround**, not a seamless first-attempt pass.

An independent network-disabled container verified that two list calls returned the same 14 unique expected paths, neither list nor `--check` changed target files, and `--check` still returned `in sync`. The original full regression ran 244 tests with four existing skips; the independent final regression ran 246 tests with the same four skips, exit zero. The initial `TODO.md` and preserved `TODO.legacy.md` have the same Git blob hash `300227f640007c4da8dc3ae69cd7092b4cd198b1`. The recorded Git diff shows the new test file and no modifications to existing tests. The `--list --check` combination was not specified; the agent chose list precedence.
