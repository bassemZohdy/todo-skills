# Active Backlog

## 🌳 Task Tree

- [/] **FIX-003** · P1 · S · Make todo-report.sh exit 1 with a stderr message starting "todo-report:" when TODO.md is missing in the current directory
  - Done when: run in a folder without TODO.md, todo-report.sh exits 1 and its stderr starts with "todo-report:", checked by a new case in tests/run.sh; `bash tests/run.sh`
  - State: attempts 0/3; baseline 49 passing; branch todo/FIX-003-make-todo-report-sh from main; next: drain
