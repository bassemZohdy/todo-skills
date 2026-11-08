# Active Backlog

## 🌳 Task Tree

- [ ] **FEAT-012** · P1 · mid · Check permissions on the admin routes
  - Done when: a non-admin request is denied with 403 and an admin request passes; `python3 -m unittest tests.test_admin`
- [ ] **FEAT-013** · P1 · high · Parse the deployment config file
  - Done when: a valid file loads and an invalid one raises ConfigError; `python3 -m unittest tests.test_config`
- [ ] **FEAT-014** · P2 · mid · Add a CSV export of orders
  - Done when: the export writes one row per order; `python3 -m unittest tests.test_export`
