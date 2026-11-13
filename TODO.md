# Active Backlog

## 🌳 Task Tree

- [/] **TASK-118** · P1 · low · Add .github/workflows/trials.yml: a workflow that runs only on manual trigger and, on ubuntu-latest and macos-latest, installs the pinned Codex and Claude Code CLIs and prints their versions and what python3 and bash resolve to, with no login and no secrets (the agent-free trial checks already run on both systems in test.yml)
  - Done when: trials.yml triggers on workflow_dispatch only, pins every action to a commit, names no secret and no pull_request or push trigger, and the test fails on a copy that adds a push trigger or an unpinned action; `bash tests/trials/test-trials-workflow.sh`
  - Links: Ref: docs/trials.md · From: TASK-116
  - State: attempts 0/3; baseline 252 passing; branch todo/TASK-118-trials-workflow from main; next: read docs
- [ ] **TASK-087** · P2 · mid · Widen the Claude Code evidence: every recorded batch ran on Windows 11 with Git Bash, none on Linux or macOS, and no Claude Code lane run has the worker-activity records that prove concurrency (docs/agent-compatibility.md)
  - Done when: a dated docs/evals folder holds a checksummed Linux or macOS batch that agent-compatibility.md cites, and a lane run without worker-activity records fails to read as concurrent; `bash tests/trials/test-lane-evidence.sh`
- [ ] **TASK-116** · P2 · mid · Rerun the trial scenarios on the revised skill text with Codex: on this Windows host Codex cannot run python3 in its sandbox (probe of 2026-11-13 stopped at the baseline), and a Linux run needs a container with Codex set up in it
  - Done when: a dated docs/evals folder holds a checksummed Codex batch on the revised text that docs/trials.md and docs/agent-compatibility.md cite; `bash tests/run.sh`
  - Links: From: TASK-112
