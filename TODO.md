# Active Backlog

## 🌳 Task Tree

- [ ] **TASK-087** · P2 · mid · Widen the Claude Code evidence: every recorded batch ran on Windows 11 with Git Bash, none on Linux or macOS, and no Claude Code lane run has the worker-activity records that prove concurrency (docs/agent-compatibility.md)
  - Done when: a dated docs/evals folder holds the summary of a Linux or macOS batch that agent-compatibility.md cites, and a lane run without worker-activity records fails to read as concurrent; `bash tests/trials/test-lane-evidence.sh`
- [ ] **TASK-116** · P2 · mid · Rerun the trial scenarios on the revised skill text with Codex: on this Windows host Codex cannot run python3 in its sandbox (probe of 2026-11-13 stopped at the baseline), and a Linux run needs a container with Codex set up in it
  - Done when: a dated docs/evals folder holds the summary of a Codex batch on the revised text that docs/trials.md and docs/agent-compatibility.md cite; `bash tests/run.sh`
  - Links: From: TASK-112
