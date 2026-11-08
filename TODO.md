# Active Backlog

## 🌳 Task Tree
- [ ] **FIX-039** · P1 · mid · Run multi-node Codex trials with a fresh process for every skill invocation
  - Done when: TypeScript and Java trials retain the exact generated prompt and independent evidence for distinct sessions through root completion; `bash tests/trials/test-codex-fresh-invocations.sh`
  - State: branch todo/FIX-039-run-multi-node-codex-trials from main; next: start FIX-039
  - Links: Ref: docs/evals/codex-linux-2026-11-08/summary.md
- [ ] **TASK-040** · P1 · high · Audit Linux trial isolation against read and write boundary escapes
  - Done when: independent probes exercise the login, evaluator, evidence, scratch Git and network boundaries and record their limitations; `bash tests/trials/test-linux-boundary.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/summary.md
- [ ] **FIX-038** · P2 · mid · Keep optional shell tools usable when installed from a Windows checkout into Linux
  - Done when: a copied optional lint script runs under Linux after a Windows checkout and retains equivalent lint behavior; `bash tests/trials/test-shell-line-endings.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/summary.md
