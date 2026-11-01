# Active Backlog

## 🏗️ In Progress (Max 1)

- [/] **FEAT-002** · P1 · Add token expiry check
  - Scope: Add an expiry check in the auth middleware.
  - Out of Scope: Refresh tokens.
  - Ref: none
  - Depends: TASK-001
  - From: TASK-001
  - Validation: `npm test -- auth`
  - Progress: attempts 1/3; done: baseline red; next: implement check

## 📋 Ready (Prioritized Queue)

- [ ] **FIX-003** · P1 · Fix null user lookup
  - Scope: Guard the lookup.
  - Out of Scope: Schema changes.
  - Ref: none
  - Validation: `npm test -- users`

## ⛔ Blocked

- [!] **FIX-004** · P2 · Flaky upload test
  - Scope: Stabilise the test.
  - Out of Scope: Upload service.
  - Ref: none
  - Validation: `npm test -- upload`
  - Blocker Reason: CI storage emulator is down.
  - Command/Error: `npm test -- upload` → ECONNREFUSED 127.0.0.1:9000
  - Action Required: Restart the emulator.
