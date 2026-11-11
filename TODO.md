# Active Backlog

## 🌳 Task Tree

- [ ] **FIX-093** · P0 · low · Remove the carriage return that FEAT-078 left inside tools/todo-lint.sh: the file is treated as binary and tests/trials/test-shell-line-endings.sh fails on every CI platform since d7f0772
  - Done when: no shell script under tools, tests or .todo contains a CR byte and the lint still warns on a missing Ref; `bash tests/run.sh`
  - State: branch todo/FIX-093-remove-cr-from-lint from main; next: start FIX-093
- [ ] **TASK-073** · P1 · mid · Add static analysis for the shell code: about 3,900 lines in tools/, tests/ and tests/trials/ have no shellcheck run, and five of the six tools set neither -e nor -u; add a CI step and fix or annotate what it reports
  - Done when: test.yml runs shellcheck over tools, tests and .todo, run.sh runs it when installed, and a seeded unquoted-variable finding fails it; `bash tests/run.sh`
  - State: next: decompose
- [ ] **TASK-075** · P1 · mid · Record real runs of the agent benchmark: docs/evals/benchmark has six scenarios and three arms but results.csv holds only its header, so COMPARISON.md still rests on reviewer estimates made for 0.2.0
  - Done when: results.csv has a row per arm and scenario with checksummed evidence, and a row whose evidence is missing fails the harness check; `bash tests/trials/test-benchmark-harness.sh`
- [ ] **TASK-085** · P2 · mid · Slim what an install clones, after the owner picks the target: docs/evals holds 1,643 of the 1,839 tracked files (12 MB, 1,366 of them raw run logs and diagnostics) and every marketplace install or npx skills add clones them; keep summaries and results on main and move raw runs to a separate branch or release assets
  - Done when: tracked files under docs/evals fall below the agreed count, every README and docs link still resolves, and a dangling evidence link fails the check; `bash tests/run.sh`
  - State: next: decompose
- [ ] **TASK-086** · P2 · mid · Add resume and regression-failure trial variants outside Python: ts-lifecycle, java-lifecycle and multi-module have no red-baseline or interrupted-run scenario (docs/trials.md, limits)
  - Done when: selftest sets up a red-baseline and an interrupted variant for TypeScript and for Java, and doing nothing fails each; `bash tests/trials/selftest.sh`
- [ ] **TASK-087** · P2 · mid · Widen the Claude Code evidence: every recorded batch ran on Windows 11 with Git Bash, none on Linux or macOS, and no Claude Code lane run has the worker-activity records that prove concurrency (docs/agent-compatibility.md)
  - Done when: a dated docs/evals folder holds a checksummed Linux or macOS batch that agent-compatibility.md cites, and a lane run without worker-activity records fails to read as concurrent; `bash tests/trials/test-lane-evidence.sh`
- [ ] **FEAT-088** · P2 · mid · Stamp the copied scripts with their release: users copy tools/*.sh by hand and nothing says which version a copy is, and a release needs hand edits in three places (0.4.0 took a separate manifest-bump commit, 8b5a2fd); add a version line and a --version flag to each tool and one helper that sets the manifests, README and stamps together
  - Done when: run.sh fails when a tool's stamp, either manifest or the newest CHANGELOG heading disagree, and each tool prints its version; `bash tests/run.sh`
  - State: next: decompose
- [ ] **TASK-089** · P2 · low · Restructure the README Status section: one 1,900-character paragraph of trial history becomes a table of agent, platform, result and evidence link, with the known limits as a list
  - Done when: the README drift check still passes and fails if the agents-with-recorded-trials line or an evidence link is lost; `bash tests/run.sh`
- [ ] **TASK-090** · P2 · mid · Cut what /todo-continue always loads: 54,689 bytes and 8,871 words load for every node and the budget only caps growth (tokens were never measured); move the --worktree and claim-collision branches of git-flow.md into a reference read on demand and lower the budget
  - Done when: the /todo-continue row of the load budget drops by at least 15 percent, the check fails above it, and the skill text checks still pass; `bash tests/run.sh`
- [ ] **TASK-091** · P2 · mid · Add a two-clone claim scenario to the trial harness: team use is unverified (README Status) and every claim trial runs in one clone; use a bare remote and two clones whose claims and new root IDs collide after a pull
  - Done when: selftest sets up the scenario with its bare remote and doing nothing fails it; `bash tests/trials/selftest.sh`
