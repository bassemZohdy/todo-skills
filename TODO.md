# Active Backlog

## 🌳 Task Tree
- [ ] **TASK-047** · P2 · low · Release 0.4.0 once the evidence tasks are done and regression checks pass
  - Done when: CHANGELOG has a dated 0.4.0 section and both plugin manifests carry 0.4.0; `grep -q '^## \[0.4.0\] - ' CHANGELOG.md`; regression: `bash tests/run.sh`
  - Links: Depends: TASK-043, TASK-044, TASK-045, TASK-046
- [ ] **TASK-050** · P2 · low · Submit the Claude-plugin import to OpenAI directory and record its outcome
  - Done when: the imported Codex manifest and clean skills are checked, then the portal reference, version, submission date, status or owner blocker are recorded in docs/distribution.md; `test -f docs/distribution.md`
  - Links: Ref: docs/distribution.md · Depends: TASK-049, TASK-047
