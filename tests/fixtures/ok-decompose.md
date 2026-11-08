# Active Backlog

## 🌳 Task Tree
- [ ] **FEAT-001** · P1 · high · Build the reporting module
  - Done when: reports render and a missing template fails with an error; `python3 -m unittest tests.test_report`
  - [ ] **FEAT-001.1** · mid · Report data layer, decomposed when it becomes workable
    - Done when: data layer covered; `python3 -m unittest tests.test_report_data`
    - State: next: decompose
  - [ ] **FEAT-001.2** · low · Render a report as text
    - Done when: text render tested; `python3 -m unittest tests.test_report_text`
  - [ ] **FEAT-001.3** · low · Name a report test file after mkfs to check substring matching
    - Done when: no false positive; `pytest tests/test_mkfs.py`
