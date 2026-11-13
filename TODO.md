# Active Backlog

## 🌳 Task Tree

- [ ] **TASK-075** · P1 · mid · Record real runs of the agent benchmark: docs/evals/benchmark has six scenarios and three arms but results.csv holds only its header, so COMPARISON.md still rests on reviewer estimates made for 0.2.0
  - Done when: results.csv has a row per arm and scenario with checksummed evidence, and a row whose evidence is missing fails the harness check; `bash tests/trials/test-benchmark-harness.sh`
  - State: branch todo/TASK-075-record-real-runs-agent from main; next: start TASK-075
- [ ] **FIX-104** · P1 · low · Say in todo-continue step 11 what a red-baseline stop reports as the next workable node and as the regression result, since no green baseline exists to compare against
  - Done when: step 11 names the red-baseline case and a pin in tests/run.sh fails without it; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13/summary.md#seen-not-changed
- [ ] **FIX-105** · P1 · low · Define which form of a failing test id is written after a red baseline when the runner prints two (unittest, Surefire, node --test): five pi reports chose differently
  - Done when: todo-continue step 3 and verification.md name the form to use with one example per runner, pinned in tests/run.sh; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13/summary.md#seen-not-changed
- [ ] **FIX-106** · P1 · low · Close three todo-init gaps: what to report as runtime and package manager when no marker file exists, that step 4 and ci.md agree on running check.sh once with --ci, and whether the Tests: line is offered when the README names the command without a Tests: marker
  - Done when: todo-init and ci.md state each rule once and tests/run.sh pins the three; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13/summary.md#seen-not-changed
- [ ] **FIX-107** · P1 · low · Close three lanes.md gaps for a run without a subagent tool: which step 3 the lane work means, that all lane work comes before the first drain, and that refresh conflicts are possible, not expected, for every later root
  - Done when: lanes.md states the three and tests/run.sh pins them; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13/summary.md#seen-not-changed
- [ ] **FIX-108** · P1 · low · Close four cross-reference gaps: the blocked path of todo-update cites todo-continue Test failures without loading it, step 10 item 2 applies to a root too, the commit scope for nested source folders, and where the task ID goes when Done when names a test class or file
  - Done when: each rule is stated where it is used, inside the load budget, with a pin in tests/run.sh; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13/summary.md#seen-not-changed
- [ ] **TASK-085** · P2 · mid · Slim what an install clones, after the owner picks the target: docs/evals holds 1,643 of the 1,839 tracked files (12 MB, 1,366 of them raw run logs and diagnostics) and every marketplace install or npx skills add clones them; keep summaries and results on main and move raw runs to a separate branch or release assets
  - Done when: tracked files under docs/evals fall below the agreed count, every README and docs link still resolves, and a dangling evidence link fails the check; `bash tests/run.sh`
  - State: next: decompose
- [ ] **TASK-087** · P2 · mid · Widen the Claude Code evidence: every recorded batch ran on Windows 11 with Git Bash, none on Linux or macOS, and no Claude Code lane run has the worker-activity records that prove concurrency (docs/agent-compatibility.md)
  - Done when: a dated docs/evals folder holds a checksummed Linux or macOS batch that agent-compatibility.md cites, and a lane run without worker-activity records fails to read as concurrent; `bash tests/trials/test-lane-evidence.sh`
- [ ] **TASK-109** · P2 · mid · Start a node that has no Ref and no governing doc with next: build instead of next: read docs: the start value looked stale in seven pi reports because nothing was read
  - Done when: todo-continue step 5 and its resume map agree on the start value, docs/REFERENCE.md lists it, and tests/run.sh pins it; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13/summary.md#seen-not-changed
- [ ] **TASK-110** · P2 · mid · Cut the text every /todo-continue run loads: it is about half of the input sent on each model call in the pi benchmark
  - Done when: the /todo-continue row of the load budget in docs/DEVELOPMENT.md is at least 10 percent lower than today and the load check passes with every pinned rule kept; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13/summary.md#cost-where-the-tokens-of-the-skills-arm-go
- [ ] **FEAT-111** · P2 · mid · Add a light path for a low leaf root that takes fewer model calls: fold the start commit into the claim commit and skip the refresh when the base has not moved since the claim
  - Done when: the path is in todo-continue and git-flow.md, pinned in tests/run.sh, and the happy-path assertions accept the shorter history; `bash tests/trials/selftest.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13/summary.md#cost-where-the-tokens-of-the-skills-arm-go
- [ ] **TASK-112** · P2 · mid · Rerun the trial scenarios on the revised skill text with Claude Code and Codex: only pi with GLM 5.3 has run FIX-098 to FIX-103
  - Done when: a dated docs/evals folder holds each batch with checksums that verify and docs/trials.md and docs/agent-compatibility.md cite it; `bash tests/run.sh`
  - Links: Ref: docs/evals/pi-glm-2026-11-13/summary.md#not-done
