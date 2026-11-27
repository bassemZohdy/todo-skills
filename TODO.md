# Active Backlog

## 🛤️ Lanes

- main: skills, lint, docs and the trial harness of this repository, one agent in order

## 🌳 Task Tree

- [ ] **TASK-147** · P2 · mid · Score TDD order from agent logs: a failing test run before the first source edit
  - Done when: tdd-order.sh reports PASS for a log with a failing test run before the first source edit and FAIL when the source is edited first or no test fails first, for the pi, Claude Code and Codex log formats; `bash tests/trials/test-tdd-order.sh`
  - Links: Ref: docs/VERIFICATION.md
  - State: branch todo/TASK-147-score-tdd-order-from from main; next: start TASK-147
- [ ] **FEAT-148** · P2 · mid · Classify tests as sanity, smoke and regression: the fast classes per node, the full regression at the root
  - Done when: a project with a Smoke: line runs its Done when and smoke per node and the full regression at the root, and one without it behaves as before; `bash tests/run.sh`
  - Links: Ref: docs/VERIFICATION.md
  - [ ] **FEAT-148.1** · mid · Test classes in reference/test-tiers.md, read only when Smoke: exists
    - Done when: the rule defines sanity (the Done when), smoke (broad, shallow, fast) and regression (broad, deep, full suite), requires one class tag per new test from the project's own runner, and covers per-class pass counts and finding the node that broke a failure seen at the root; `bash tests/test-smoke-tier.sh`
  - [ ] **FEAT-148.2** · mid · /todo-init detects a smoke command and offers a Smoke: README line
    - Done when: init offers the line only for a detected command (pytest marker, Maven profile, npm script) and writes it on a yes; `bash tests/test-smoke-detect.sh`
  - [ ] **FEAT-148.3** · mid · Trial scenario smoke-tier with a slow suite
    - Done when: the scenario sets up, fails when nothing is done and asserts smoke per node and the full regression at the root; `bash tests/trials/selftest.sh`
    - Links: Depends: FEAT-148.1
