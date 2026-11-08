# Active Backlog

## 🌳 Task Tree
- [ ] **FEAT-042** · P1 · mid · Show backlog progress bars in the read-only views, without changing TODO.md
  - Done when: todo-lint.sh --progress, /todo-status and docs/status.html use one progress definition and agree on the fixture; `bash tests/run.sh`
  - Links: Ref: docs/REFERENCE.md#issue-reconciliation
  - State: branch todo/FEAT-042-show-backlog-progress-bars from main; next: build children
  - [/] **FEAT-042.1** · mid · Print the overall progress line with todo-lint.sh --progress
    - Done when: --progress prints the expected line for tests/fixtures/progress and keeps the lint exit code; `bash tests/run.sh`
    - State: attempts 0/3; baseline 129 passing; branch todo/FEAT-042.1-print-overall-progress-line from todo/FEAT-042-show-backlog-progress-bars; next: read docs
  - [ ] **FEAT-042.2** · low · Show per-root, per-lane and overall progress bars in /todo-status
    - Done when: the todo-status skill defines the bars, the blocked cells and the drained count; `bash tests/run.sh`
  - [ ] **FEAT-042.3** · mid · Add the overall progress line to the docs/status.html KPIs
    - Done when: the template's progress function gives the lint's line for the fixture under node; `bash tests/run.sh`
  - [ ] **FEAT-042.4** · low · Document the progress views and the issue 5 decision
    - Done when: COMMANDS, TOOLS and REFERENCE describe --progress and the bars; `bash tests/run.sh`
