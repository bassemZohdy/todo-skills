# Linux trial boundary audit, 2026-11-08

`bash tests/trials/test-linux-boundary.sh` uses a disposable Linux container,
fake login and evidence sentinels, and a loopback server. It mounts no real
credentials. On Codex CLI 0.167.0, `todo-codex-linux:0.167.0`, and Docker with
`seccomp=unconfined`, the audit reported **9 passed, 0 failed** and one
pre-fix boundary failure.

The agent sandbox denied reads and writes of dummy login, evaluator, evidence,
and another scratch location; denied an evidence symlink escape and loopback
network access; and allowed a scratch commit, branch and worktree. The audit
also ran the actual `assert.sh` through `assert-exec.sh` with a controlled
scratch Makefile. Its test process could read the controller but could not
modify it, access the dummy login or evidence, write another scratch location,
or use the loopback server. The baseline-red report remains readable via a
temporary read-only sandbox view; other evidence stays denied. A first probe
failed because a file-level permission could not override its denied parent;
the wrapper now copies only that report to a temporary controller file.

Before that isolated verifier, a controlled unsandboxed test process could
read the dummy login and overwrite the dummy evidence. During a Java diagnostic,
the old controller also populated Maven's default cache while asserting the
first failed invocation; a later agent reused it and the old runner misleadingly
reported PASS. That diagnostic is an infrastructure failure, not a valid pass.
The Linux runner and scorer now use the isolated assertion wrapper when
`TRIAL_LINUX_ISOLATION=1`. Missing Maven and an inaccessible Maven local
repository stop the multi-session controller as infrastructure errors.

The TypeScript and prepared-cache Java trials each completed in three distinct
fresh Codex sessions. Afterward, a separate network-disabled container without
the login volume ran the wrapper and checked the final repositories: **13/13**
assertions passed for each. The controller was mounted read-only. Raw session
logs, prompts, snapshots, checksums and these independent assertion logs are
under `%TEMP%/todo-fresh-20261108/evidence` on the evaluation host, with a
summary, machine-readable results and SHA-256 manifest; they are not a
durable published artifact. The first Java attempt lacked Maven and the second
had an inaccessible default cache. A reviewer subagent also failed to start in
one session; the agent reported a self-review instead.

These probes are not a proof of complete isolation: the profile permits general
OS reads, the verifier can read its controller, scratch test code can modify the
scratch repository, and other escape routes and Docker/host configurations were
not exhaustively tested. The container needs `seccomp=unconfined` for the inner
Codex sandbox on this host. Windows and runs without the opt-in Linux profile
still execute project tests with the controller's own permissions and must not
be described as strongly isolated. Treat the results as provisional.
