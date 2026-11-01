# Active Backlog

## 🌳 Task Tree

- [ ] **FEAT-002** · P1 · XL · Add token refresh to the auth service
  - Done when: refresh returns a new token and the old one is rejected; `npm test -- auth`; regression: `npm test`
  - [ ] **FEAT-002.1** · L · Refresh endpoint
    - Done when: endpoint covered by integration test; `npm test -- auth/refresh`
    - [x] **FEAT-002.1.1** · S · Token store interface
      - Done when: store round-trips a token; `npm test -- auth/store`
    - [/] **FEAT-002.1.2** · M · Rotate refresh tokens
      - Done when: reuse of a rotated token fails; `npm test -- auth/rotate`
      - State: attempts 1/3; branch todo/FEAT-002.1.2-rotate from todo/FEAT-002.1-refresh; next: add reuse test
  - [ ] **FEAT-002.2** · S · Document the refresh flow
    - Done when: docs build passes; `npm run docs:check`
    - Links: Ref: docs/auth.md#refresh · Depends: FEAT-002.1
- [ ] **FIX-003** · P0 · S · Reject expired JWTs
  - Done when: expired token returns 401; `npm test -- auth/middleware`
  - Links: Ref: docs/auth.md#tokens · Depends: TASK-001 · From: FEAT-002.1.1
- [!] **FIX-004** · P2 · S · Flaky clock test
  - Done when: test passes ten times in a row; `npm test -- clock`
  - Blocked: baseline red → `npm test` 3 failures in billing → a human must fix billing tests
