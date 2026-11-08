# Active Backlog

## 🌳 Task Tree
- [ ] **TASK-046** · P2 · mid · Publish durable, checksummed evidence for FIX-035 to FIX-041 and verify it in CI
  - Done when: docs/evals holds the evidence with SHA256SUMS and the Ubuntu and macOS CI jobs run its checker; `bash tests/trials/test-fix-evidence.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/ci-verification.md
  - State: branch todo/TASK-046-publish-fix-evidence from main; next: start TASK-046
- [ ] **TASK-047** · P2 · low · Release 0.4.0 once the evidence tasks are done and regression checks pass
  - Done when: CHANGELOG has a dated 0.4.0 section and both plugin manifests carry 0.4.0; `grep -q '^## \[0.4.0\] - ' CHANGELOG.md`; regression: `bash tests/run.sh`
  - Links: Depends: TASK-043, TASK-044, TASK-045, TASK-046
- [ ] **TASK-050** · P2 · low · Submit the Claude-plugin import to OpenAI directory and record its outcome
  - Done when: the imported Codex manifest and clean skills are checked, then the portal reference, version, submission date, status or owner blocker are recorded in docs/distribution.md; `test -f docs/distribution.md`
  - Links: Ref: docs/distribution.md · Depends: TASK-049, TASK-047
