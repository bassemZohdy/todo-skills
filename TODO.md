# Active Backlog

## 🌳 Task Tree

- [ ] **TASK-124** · P2 · low · Align three trial assertions with what Codex agents did on 2026-11-14 while following the skill: add-fix expects `python3 -m unittest tests.test_calc.<Class>.test_x` and rejects a `cd tests &&` form, monorepo expects `def test_power` and rejects `test_feat_001_power` (the skill asks for the ID in the test name), dirty-tree expects the words clean or uncommitted in the report
  - Done when: assert.sh accepts each of the three forms and still fails an untouched repository for those scenarios; `bash tests/trials/selftest.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-14/summary.md#the-three-failures · From: TASK-116
- [ ] **TASK-087** · P2 · mid · Widen the Claude Code evidence: every recorded batch ran on Windows 11 with Git Bash, none on Linux or macOS, and no Claude Code lane run has the worker-activity records that prove concurrency (docs/agent-compatibility.md)
  - Done when: a dated docs/evals folder holds the summary of a Linux or macOS batch that agent-compatibility.md cites, and a lane run without worker-activity records fails to read as concurrent; `bash tests/trials/test-lane-evidence.sh`
