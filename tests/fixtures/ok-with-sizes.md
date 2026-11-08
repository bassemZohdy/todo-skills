# Active Backlog

## 🌳 Task Tree
- [ ] **FEAT-001** · P1 · mid · XL · Reporting module with optional sizes
  - Done when: reports render; `python3 -m unittest tests.test_report`
  - [ ] **FEAT-001.1** · mid · L · Data layer
    - Done when: data layer covered; `python3 -m unittest tests.test_data`
    - [ ] **FEAT-001.1.1** · high · S · Cache invalidation
      - Done when: stale entries evicted and a corrupt entry is rejected; `python3 -m unittest tests.test_cache`
  - [ ] **FEAT-001.2** · low · Render text without a size
    - Done when: text render tested; `python3 -m unittest tests.test_text`
