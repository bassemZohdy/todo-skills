# Active Backlog

## 🌳 Task Tree
- [ ] **FIX-035** · P0 · high · Start a new uncommitted root on the base without losing backlog edits or racing another claim
  - Done when: a root added by todo-add is claimed from the base without a separate backlog commit, and competing claims remain protected; `bash tests/trials/test-pending-root.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/summary.md
- [ ] **TASK-030** · P1 · mid · Independently validate evaluation evidence using a separate CI runner
  - Done when: a CI verification run checks pinned source, assertion logs and evidence hashes without giving the tested agent write access to the verifier, and records the result; `bash tests/run.sh`
  - Links: Ref: docs/trials.md
- [ ] **FIX-036** · P1 · high · Distinguish concurrent lane execution from overlapping worktree lifetimes
  - Done when: interleaved sequential worktree events do not claim parallel agents, and verified concurrent workers are distinguishable; `bash tests/trials/test-lane-concurrency.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/summary.md
- [ ] **FIX-037** · P1 · mid · Exclude a batch evidence folder from the trial scenario score
  - Done when: score.sh counts every scenario but does not count the batch evidence directory as an extra scenario; `bash tests/trials/test-score-layout.sh`
  - Links: Ref: tests/trials/README.md
- [ ] **FIX-039** · P1 · mid · Run multi-node Codex trials with a fresh process for every skill invocation
  - Done when: TypeScript and Java trials retain the exact generated prompt and independent evidence for distinct sessions through root completion; `bash tests/trials/test-codex-fresh-invocations.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/summary.md
- [ ] **TASK-040** · P1 · high · Audit Linux trial isolation against read and write boundary escapes
  - Done when: independent probes exercise the login, evaluator, evidence, scratch Git and network boundaries and record their limitations; `bash tests/trials/test-linux-boundary.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/summary.md
- [ ] **FIX-038** · P2 · mid · Keep optional shell tools usable when installed from a Windows checkout into Linux
  - Done when: a copied optional lint script runs under Linux after a Windows checkout and retains equivalent lint behavior; `bash tests/trials/test-shell-line-endings.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/summary.md
