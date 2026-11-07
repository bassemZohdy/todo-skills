# Active Backlog

## 🌳 Task Tree
- [ ] **FEAT-008** · P1 · mid · Add optional Markdown RTM traceability with docs/RTM.md preferred and README.md fallback
  - Done when: simple projects work without an RTM and projects with either location retain requirement-to-task-to-verification links; `bash tests/run.sh`
  - [ ] **FEAT-008.1** · mid · Define minimal RTM format and document resolution rules
    - Done when: docs/RTM.md wins when present, otherwise an RTM section in README.md is used, and neither is required; `bash tests/run.sh`
  - [ ] **FEAT-008.2** · mid · Connect planning and task addition to an existing RTM location
    - Done when: plan/add update requirement mappings only when RTM is opted in, keep stable IDs and avoid duplicating task state; `bash tests/run.sh`
  - [ ] **FEAT-008.3** · mid · Preserve verification traceability through completion and archival
    - Done when: task completion records test references in the selected RTM and archived CHANGELOG task IDs resolve without stale TODO links; `bash tests/run.sh`
  - [ ] **FEAT-008.4** · mid · Test fallback, precedence, and backwards compatibility
    - Done when: fixtures cover docs-only, README-only, both, neither, and completed tasks with no new required dependencies; `bash tests/run.sh`
- [ ] **TASK-009** · P1 · mid · Strengthen existing verification against false-positive test runs without changing the task schema
  - Done when: verification rejects zero-test runs, missing test targets and masked failures using fixture tests while existing valid runners remain supported; `bash tests/run.sh`
- [ ] **TASK-010** · P1 · low · Add focused regression fixtures for resume, verification and CI fallback paths
  - Done when: tests cover interrupted task resumption, blocked verification and missing optional CI files without external services; `bash tests/run.sh`
- [ ] **TASK-011** · P2 · low · Make existing documentation-drift checks report actionable file and symbol references
  - Done when: continuation reports impacted README/docs references on interface changes and does not block unrelated tasks or require new tools; `bash tests/run.sh`
- [ ] **TASK-007** · P2 · low · Submit to the Anthropic plugin directory (owner action: portal login and terms) and record it (#11)
  - Done when: submission date and reference are recorded in docs/distribution.md; `test -f docs/distribution.md`
