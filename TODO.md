# Active Backlog

## 🌳 Task Tree
- [ ] **TASK-012** · P0 · mid · Add opt-in strict verification to existing todo-verify.sh
  - Done when: strict mode rejects ambiguous output, zero-test runs and masked failures while default mode preserves compatible runners; `bash tests/run.sh`
- [ ] **TASK-013** · P0 · mid · Run reproducible lifecycle trials on TypeScript, Java and multi-module scratch projects
  - Done when: documented trials exercise plan, execution, resume, merges, parallel lanes and regression failures with reproducible results; `test -f docs/trials.md`; `bash tests/run.sh`
- [ ] **TASK-014** · P1 · mid · Cover RTM fallback and archived-task consistency with focused fixtures
  - Done when: RTM tests cover docs precedence, README fallback, missing RTM, duplicate mappings and archived tasks without changing the simple format; `bash tests/run.sh`
- [ ] **TASK-015** · P1 · mid · Validate common task lifecycle on Claude Code and Codex
  - Done when: a reproducible compatibility report records installs, task lifecycle results, unsupported cases and evidence for both agents without claiming untested support; `test -f docs/agent-compatibility.md`; `bash tests/run.sh`
- [ ] **TASK-016** · P1 · low · Document optional independent architecture review for high-risk tasks
  - Done when: existing planning and review guidance explains how to request a fresh-context design review or use EGM without making it a required stage; `bash tests/run.sh`
- [ ] **TASK-017** · P2 · low · Refresh weighted comparison and limitations for todo-skills 0.3.0
  - Done when: docs/COMPARISON.md distinguishes source-backed features, estimates and end-to-end trials with updated weights and alternatives; `test -f docs/COMPARISON.md`; `bash tests/run.sh`
