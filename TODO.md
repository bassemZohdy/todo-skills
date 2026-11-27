# Active Backlog

## 🛤️ Lanes

- main: skills, lint, docs and the trial harness of this repository, one agent in order

## 🌳 Task Tree

- [ ] **TASK-150** · P2 · low · Clarify in test-tiers.md that changing the test setup means runner configuration or a shared fixture, not a new test file or a package marker
  - Done when: test-tiers.md says a new test file or a package marker such as __init__.py is not a test setup change, so a child node whose only setup change is that marker keeps smoke as its baseline; `bash tests/test-smoke-tier.sh`
  - Links: Ref: plugin/skills/todo/reference/test-tiers.md · From: TASK-149
  - State: branch todo/TASK-150-clarify-in-test-tiers from main; next: start TASK-150
