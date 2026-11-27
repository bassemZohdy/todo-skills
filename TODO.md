# Active Backlog

## 🛤️ Lanes

- main: skills, lint, docs and the trial harness of this repository, one agent in order

## 🌳 Task Tree

- [/] **TASK-149** · P2 · mid · Record Claude Code's stream-json session in run-claude.sh evidence so tdd-order.sh can score Claude runs
  - Done when: run-claude.sh passes --output-format stream-json --verbose, keeps the stream as evidence session.jsonl in the checksums, still writes the final answer to report.txt, and tdd-order.sh reads that file; a run whose stream is empty fails as an infrastructure error, not as a skill failure; `bash tests/trials/test-claude-session-log.sh`
  - Links: Ref: tests/trials/README.md · From: TASK-147
  - State: attempts 0/3; baseline 437 passing; branch todo/TASK-149-record-claude-code-s from main; next: read docs
