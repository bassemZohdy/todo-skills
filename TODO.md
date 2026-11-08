# Active Backlog

## 🌳 Task Tree
- [ ] **TASK-044** · P1 · high · Record genuinely simultaneous Codex lane execution
  - Done when: lane-evidence.sh reports execution: concurrent from independent worker activity records for the multi-module lanes; `bash tests/trials/test-lane-concurrency-evidence.sh`
  - Links: Ref: tests/trials/README.md
  - State: branch todo/TASK-044-record-simultaneous-codex-lanes from main; next: build children
  - [x] **TASK-044.1** · mid · Make the lane runner start one fresh Codex process per lane at the same time and record each worker's own start and end
    - Done when: a stubbed two-lane run writes one activity line per worker that lane-evidence.sh reads as concurrent; `bash tests/trials/test-lane-activity.sh`
  - [ ] **TASK-044.2** · mid · Run the multi-module batch with the lane runner and publish its evidence
    - Done when: the published evidence has two distinct worker sessions with overlapping activity and passing assertions; `bash tests/trials/test-lane-concurrency-evidence.sh`
- [ ] **TASK-045** · P1 · mid · Repeat the Windows Codex lifecycle batch with the default isolated verifier
  - Done when: every scenario is scored PASS, FAIL or INFRA_ERROR with its cause recorded, assertions ran through windows-assert-exec.sh, and the published evidence passes its checker; `bash tests/trials/test-windows-codex-evidence.sh`
  - Links: Ref: docs/evals/fix-041.md
- [ ] **TASK-046** · P2 · mid · Publish durable, checksummed evidence for FIX-035 to FIX-041 and verify it in CI
  - Done when: docs/evals holds the evidence with SHA256SUMS and the Ubuntu and macOS CI jobs run its checker; `bash tests/trials/test-fix-evidence.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/ci-verification.md
- [ ] **TASK-047** · P2 · low · Release 0.4.0 once the evidence tasks are done and regression checks pass
  - Done when: CHANGELOG has a dated 0.4.0 section and both plugin manifests carry 0.4.0; `grep -q '^## \[0.4.0\] - ' CHANGELOG.md`; regression: `bash tests/run.sh`
  - Links: Depends: TASK-043, TASK-044, TASK-045, TASK-046
