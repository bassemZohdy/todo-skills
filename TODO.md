# Active Backlog

## 🌳 Task Tree

- [ ] **TASK-120** · P1 · mid · Cut the model calls of a node by batching its lifecycle steps in the skill text, with no new script: one shell command block for claim, fast-forward of the base and start, and one for drain and merge, with the commit subjects and bodies unchanged (git and backlog-file calls were 74 of 162 calls and about 53 percent of input tokens in the six runs of 2026-11-13, and the logs predict at most about 40 percent fewer input tokens if those calls shrink to four per node)
  - Done when: todo-continue or a reference file it names gives each of the two blocks and tests/run.sh pins them, the 34 trial scenarios still set up and fail on an untouched repository, and a fresh pi benchmark of the six scenarios records fewer median model calls than the 31 of 2026-11-13; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13-load-cut/summary.md#cost-what-the-cut-changed · Depends: TASK-119 · From: TASK-110
  - State: branch todo/TASK-120-batch-lifecycle-steps from main; next: start TASK-120
- [ ] **TASK-087** · P2 · mid · Widen the Claude Code evidence: every recorded batch ran on Windows 11 with Git Bash, none on Linux or macOS, and no Claude Code lane run has the worker-activity records that prove concurrency (docs/agent-compatibility.md)
  - Done when: a dated docs/evals folder holds the summary of a Linux or macOS batch that agent-compatibility.md cites, and a lane run without worker-activity records fails to read as concurrent; `bash tests/trials/test-lane-evidence.sh`
- [ ] **TASK-116** · P2 · mid · Rerun the trial scenarios on the revised skill text with Codex: on this Windows host Codex cannot run python3 in its sandbox (probe of 2026-11-13 stopped at the baseline), and a Linux run needs a container with Codex set up in it
  - Done when: a dated docs/evals folder holds the summary of a Codex batch on the revised text that docs/trials.md and docs/agent-compatibility.md cite; `bash tests/run.sh`
  - Links: From: TASK-112
