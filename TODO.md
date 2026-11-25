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
