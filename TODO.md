# Active Backlog

## 🌳 Task Tree

- [ ] **TASK-123** · P1 · mid · Cut the input a todo-skills run re-sends on every model call by shrinking the skill text a node run keeps in context, since wording that allows chained commands did not cut calls (the skill files read in a run were about 40 percent of one measured run's input, and the median stayed at 31 calls on 18 fresh runs)
  - Done when: the load budget in docs/DEVELOPMENT.md is lowered to the new size of /todo-continue and tests/run.sh pins it, the 34 trial scenarios still set up and fail on an untouched repository, and a fresh pi benchmark of the six scenarios records a lower median uncached input than the 52,187 of 2026-11-14 with every cell PASS; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-14-batched-steps/summary.md#what-it-means · From: TASK-120
  - State: branch todo/TASK-123-shrink-resident-skill-text from main; next: start TASK-123
- [ ] **TASK-087** · P2 · mid · Widen the Claude Code evidence: every recorded batch ran on Windows 11 with Git Bash, none on Linux or macOS, and no Claude Code lane run has the worker-activity records that prove concurrency (docs/agent-compatibility.md)
  - Done when: a dated docs/evals folder holds the summary of a Linux or macOS batch that agent-compatibility.md cites, and a lane run without worker-activity records fails to read as concurrent; `bash tests/trials/test-lane-evidence.sh`
- [ ] **TASK-116** · P2 · mid · Rerun the trial scenarios on the revised skill text with Codex: on this Windows host Codex cannot run python3 in its sandbox (probe of 2026-11-13 stopped at the baseline), and a Linux run needs a container with Codex set up in it
  - Done when: a dated docs/evals folder holds the summary of a Codex batch on the revised text that docs/trials.md and docs/agent-compatibility.md cite; `bash tests/run.sh`
  - Links: From: TASK-112
