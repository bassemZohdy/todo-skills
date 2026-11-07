# Active Backlog

## 🌳 Task Tree
- [ ] **TASK-028** · P0 · mid · Validate Codex Git lifecycle in an isolated WSL2 or Linux runner
  - Done when: fresh Codex completes happy-path with branch, implementation, checks and merge, or records a reproducible infrastructure blocker; `bash tests/trials/test-codex-evidence.sh`
  - Links: Ref: docs/evals/codex-2026-11-07/summary.md
- [ ] **TASK-029** · P0 · mid · Re-run the six previously blocked Codex scenarios and publish independent verdicts
  - Done when: all six scenarios have fresh execution logs, verifier results, exit codes, hashes and explicit PASS/FAIL/INFRA_ERROR/UNVERIFIED verdicts without silent skips; `bash tests/trials/test-codex-evidence.sh`
  - Links: Ref: docs/evals/codex-2026-11-07/summary.md · Depends: TASK-028
- [ ] **TASK-030** · P1 · mid · Independently validate evaluation evidence using a separate CI runner
  - Done when: a CI verification run checks pinned source, assertion logs and evidence hashes without giving the tested agent write access to the verifier, and records the result; `bash tests/run.sh`
  - Links: Ref: docs/trials.md
- [ ] **TASK-031** · P1 · low · Trial clean Markdown-only plugin installation with and without optional tools
  - Done when: a fresh install discovers all nine skills, documents optional-tool setup and completes a basic task with the expected verification behavior; `bash tests/run.sh`
  - Links: Ref: docs/agent-compatibility.md
- [ ] **TASK-032** · P1 · mid · Run a reproducible end-to-end trial on a representative existing project
  - Done when: a fresh agent completes a scoped feature in a non-fixture project and records regression results, Git history, independent assertions and limitations; `test -f docs/trials.md`; `bash tests/run.sh`
  - Links: Ref: docs/trials.md
- [ ] **TASK-033** · P2 · low · Reconcile README and evaluation reports with current verified support
  - Done when: README, docs/trials.md, docs/agent-compatibility.md and docs/COMPARISON.md consistently distinguish passed trials from infrastructure errors and historical scores; `bash tests/run.sh`
  - Links: Ref: docs/agent-compatibility.md · Depends: TASK-029
- [ ] **TASK-034** · P2 · low · Reconcile open GitHub issues with the completed backlog
  - Done when: issue #11 is checked against its recorded completion and issue #5 has a documented keep-or-close decision without adding redundant progress state; `test -f docs/REFERENCE.md`
