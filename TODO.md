# Active Backlog

## 🌳 Task Tree
- [!] **FIX-041** · P1 · high · Isolate native Windows trial verification from authentication and evidence
  - Done when: Windows verification confines project-controlled test processes and protects login, evaluator and evidence files; `bash tests/trials/test-windows-verifier-isolation.sh`
  - Links: Ref: docs/evals/linux-boundary-2026-11-08.md
  - Blocked: unelevated Windows sandbox cannot enforce read isolation → `bash tests/trials/test-codex-isolation.sh` controller content remains readable → provide a vetted Windows isolation backend or use the Linux profile.
