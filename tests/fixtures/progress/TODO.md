# Active Backlog

## 🌳 Task Tree
- [ ] **FEAT-010** · P0 · mid · Parent with four leaves
  - Done when: every child passes; `bash tests/run.sh`
  - State: branch todo/FEAT-010-parent-four-leaves from main; next: build children
  - [x] **FEAT-010.1** · low · First done leaf
    - Done when: it works; `bash tests/run.sh`
  - [x] **FEAT-010.2** · low · Second done leaf
    - Done when: it works; `bash tests/run.sh`
  - [/] **FEAT-010.3** · mid · Active leaf
    - Done when: it works; `bash tests/run.sh`
    - State: attempts 0/3; next: build
  - [ ] **FEAT-010.4** · mid · Open leaf
    - Done when: it works; `bash tests/run.sh`
- [!] **FIX-011** · P1 · mid · Blocked leaf root
  - Done when: it works; `bash tests/run.sh`
  - Blocked: flaky runner → `bash tests/run.sh` timeout → fix the runner, then run /todo-update FIX-011 --status ready
