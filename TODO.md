# Active Backlog

## 🌳 Task Tree

- [ ] **TASK-018** · P1 · high · Enable isolated Codex trials with scratch Git writes while protecting the controller and evidence
  - Done when: a fresh Codex process can read the trial skills and modify only its scratch workspace while controller and evidence access is denied; `bash tests/trials/test-codex-isolation.sh`
  - Links: Ref: docs/agent-compatibility.md
- [ ] **TASK-019** · P1 · mid · Run and record the eight Codex lifecycle scenarios in an isolated environment
  - Done when: fresh sessions, independent assertions, Git state, exit codes and checksummed evidence are recorded for all eight scenarios with infrastructure errors distinguished from failures; `bash tests/trials/test-codex-evidence.sh`
  - Links: Ref: docs/trials.md · Depends: TASK-018
- [ ] **TASK-024** · P1 · mid · Verify Codex skill discovery and slash-command behavior independently of the file-reading trial prompt
  - Done when: a fresh Codex session's actual skill invocation behavior and any unsupported slash-command behavior are recorded with reproducible evidence; `bash tests/trials/test-codex-invocation.sh`
  - Links: Ref: docs/agent-compatibility.md · Depends: TASK-018
