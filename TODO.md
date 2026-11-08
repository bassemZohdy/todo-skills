# Active Backlog

## 🌳 Task Tree
- [ ] **FEAT-060** · P1 · mid · Warn (W5) when a high or security-titled node's Done when names no negative case
  - Done when: such a node without rejects, denies, fails, refuses, raises, unauthorized or invalid gets W5, one with them or an ordinary node gets none, and warnings never change the exit code; `bash tests/run.sh`
  - Links: Ref: docs/evals/update-review.md
  - State: branch todo/FEAT-060-lint-w5-negative-case from main; next: start FEAT-060
- [ ] **TASK-061** · P2 · low · Report the bytes and words each command loads and fail over the documented budget
  - Done when: tests/run.sh prints each command's loaded bytes and words and fails when one exceeds its budget in docs/DEVELOPMENT.md; `bash tests/run.sh`
  - Links: Ref: docs/evals/update-review.md
- [ ] **TASK-062** · P2 · low · Release 0.5.0 after the update items land
  - Done when: CHANGELOG has a dated 0.5.0 section and both plugin manifests and README carry 0.5.0; `grep -q '^## \[0.5.0\] - ' CHANGELOG.md`; regression: `bash tests/run.sh`
  - Links: Depends: TASK-054, FEAT-055, FEAT-056, FEAT-057, FEAT-058, FEAT-059, FEAT-060, TASK-061
