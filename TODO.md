# Active Backlog

## 🛤️ Lanes

- main: skills, lint, docs and the trial harness of this repository, one agent in order

## 🌳 Task Tree

- [ ] **TASK-139** · P1 · mid · Benchmark an initialised project and a multi-node requirement, so the setup cost is separated from the cost per task
  - Done when: the published rows cover the variant and the scenario, and a dated summary states the setup cost, the cost per task and the cost per node with their limits; `bash tests/trials/test-benchmark-harness.sh`
  - Links: Depends: TASK-137
  - State: branch todo/TASK-139-benchmark-initialised-project-multi from main; next: build children
  - [ ] **TASK-139.1** · mid · Add the benchmark variant todo-skills-existing, whose setup.sh leaves an initialised and committed backlog so the agent starts at todo-add
    - Done when: the variant runs with the stub agent, its start commit holds TODO.md, CHANGELOG.md and the README Tests line, and the coverage check does not ask for its rows; `bash tests/trials/test-benchmark-harness.sh`
  - [ ] **TASK-139.2** · mid · Add the benchmark scenario 7-multi-node, one requirement of four separable features with a hidden acceptance test for each
    - Done when: the reference solution passes the verifier, the untouched repository and each of four solutions that lack one feature fail it, and the coverage check prints the scenario as pending, failing as soon as it has full coverage; `bash tests/trials/test-benchmark-harness.sh`
  - [ ] **TASK-139.3** · mid · Run the batch with fresh pi agents and publish the rows and the summary
    - Done when: results.csv holds three runs per cell for five arms on 7-multi-node and for todo-skills and todo-skills-existing on scenarios 1 to 6, the pending list of the coverage check is empty, the token and cost pages are regenerated, and tests/benchmark/README.md links the summary; `bash tests/run.sh`
- [ ] **TASK-140** · P2 · mid · Rerun on Claude Code and Codex the trial scenarios added or changed since their last batches and publish the results
  - Done when: both summaries are published and docs/agent-compatibility.md states what each agent ran on the current text and what it did not; `bash tests/run.sh`
  - Links: Depends: FEAT-138
  - [ ] **TASK-140.1** · mid · Run fresh Claude Code agents on the scenarios added or changed since 2026-11-13 and publish the summary
    - Done when: docs/evals holds a summary with one row per run and every failure classified as skill, harness or environment, and docs/trials.md links it; `bash tests/run.sh`
  - [ ] **TASK-140.2** · mid · Run fresh Codex agents in Linux containers on the scenarios added or changed since 2026-11-14 and publish the summary
    - Done when: docs/evals holds a summary with one row per run and every failure classified as skill, harness or environment, and docs/trials.md links it; `bash tests/run.sh`
