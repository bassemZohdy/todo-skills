# Active Backlog

## 🌳 Task Tree

- [ ] **TASK-018** · P1 · high · Enable isolated Codex trials with scratch Git writes while protecting the controller and evidence
  - Done when: a fresh Codex process can read the trial skills and modify only its scratch workspace while controller and evidence access is denied; `bash tests/trials/test-codex-isolation.sh`
  - Links: Ref: docs/agent-compatibility.md
- [ ] **TASK-019** · P1 · mid · Run and record the eight Codex lifecycle scenarios in an isolated environment
  - Done when: fresh sessions, independent assertions, Git state, exit codes and checksummed evidence are recorded for all eight scenarios with infrastructure errors distinguished from failures; `bash tests/trials/test-codex-evidence.sh`
  - Links: Ref: docs/trials.md · Depends: TASK-018
- [ ] **TASK-020** · P1 · mid · Verify the baseline-red agent report identifies the failed baseline and suggests a fix
  - Done when: the trial rejects a silent or missing report even when the repository is unchanged and accepts a report identifying the failing baseline and a fix; `bash tests/trials/test-baseline-red-report.sh`
  - Links: Ref: tests/trials/README.md
- [ ] **TASK-021** · P1 · high · Capture independent evidence of worktree use and overlapping lane execution
  - Done when: trial evidence distinguishes separate overlapping lane runs from sequential execution and from a final clean worktree count alone; `bash tests/trials/test-lane-evidence.sh`
  - Links: Ref: tests/trials/README.md
- [ ] **TASK-022** · P1 · mid · Distinguish infrastructure errors from scenario passes in trial scoring
  - Done when: a blocked or missing agent run cannot pass solely because its repository satisfies assertions and every scenario remains in the totals; `bash tests/trials/test-score-outcomes.sh`
  - Links: Ref: tests/trials/README.md
- [ ] **TASK-023** · P1 · mid · Preserve separate logs and prompts for every trial and diagnostic invocation
  - Done when: repeated runs cannot overwrite earlier evidence and their prompts, logs, exit codes and checksums remain attributable to each invocation; `bash tests/trials/test-evidence-retention.sh`
  - Links: Ref: tests/trials/README.md
- [ ] **TASK-024** · P1 · mid · Verify Codex skill discovery and slash-command behavior independently of the file-reading trial prompt
  - Done when: a fresh Codex session's actual skill invocation behavior and any unsupported slash-command behavior are recorded with reproducible evidence; `bash tests/trials/test-codex-invocation.sh`
  - Links: Ref: docs/agent-compatibility.md · Depends: TASK-018
