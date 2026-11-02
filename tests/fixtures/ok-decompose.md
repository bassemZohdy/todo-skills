# Active Backlog

## 🌳 Task Tree
- [ ] **FEAT-001** · P1 · XL · Build the reporting module
  - Done when: reports render; `python3 -m unittest tests.test_report`
  - [ ] **FEAT-001.1** · L · Report data layer, decomposed when it becomes workable
    - Done when: data layer covered; `python3 -m unittest tests.test_report_data`
    - State: next: decompose
  - [ ] **FEAT-001.2** · S · Render a report as text
    - Done when: text render tested; `python3 -m unittest tests.test_report_text`
  - [ ] **FEAT-001.3** · S · Name a report test file after mkfs to check substring matching
    - Done when: no false positive; `pytest tests/test_mkfs.py`
