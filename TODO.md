# Active Backlog

## 🌳 Task Tree
- [/] **FIX-053** · P1 · low · Keep the cause of a multi-node INFRA_ERROR in the controller evidence
  - Done when: a multi-node invocation scored INFRA_ERROR by its signature leaves that signature in the controller's infra-signature.txt, so the Ubuntu CI job passes again; `bash tests/trials/test-codex-fresh-invocations.sh`
  - Links: Ref: tests/trials/run-codex-multi.sh
  - State: attempts 0/3; baseline 141 passing; branch todo/FIX-053-multi-infra-cause from main; next: read docs
- [ ] **TASK-050** · P2 · low · Submit the Claude-plugin import to OpenAI directory and record its outcome
  - Done when: the imported Codex manifest and clean skills are checked, then the portal reference, version, submission date, status or owner blocker are recorded in docs/distribution.md; `test -f docs/distribution.md`
  - Links: Ref: docs/distribution.md · Depends: TASK-049, TASK-047
