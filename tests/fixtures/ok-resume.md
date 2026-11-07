# Active Backlog

## 🌳 Task Tree

- [ ] **FEAT-050** · P1 · mid · L · Resume an interrupted node
  - Done when: the child resumes from its State line; `bash tests/run.sh`
  - State: branch todo/FEAT-050-resume from main; next: build children
  - [x] **FEAT-050.1** · low · Finished child
    - Done when: the first part works; `bash tests/run.sh`
  - [/] **FEAT-050.2** · mid · Interrupted child
    - Done when: the second part works; `bash tests/run.sh`
    - State: attempts 2/3; baseline 12 passing; hyp: stale cache; branch todo/FEAT-050.2-interrupted from todo/FEAT-050-resume; files: a.sh; next: resume
