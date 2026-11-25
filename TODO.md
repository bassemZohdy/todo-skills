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
- [/] **FEAT-143** · P1 · mid · Close the gaps that fresh Codex and Claude Code runs showed in the stuck-worker text: an impossible test at the red phase, a node left [/] with no verdict, and no bound on an agent's own scripts and total time
  - Done when: both rerun scenarios (stuck-loop, time-limit) ended in a verdict on fresh Codex and Claude Code runs, the load budgets hold and the pinned phrases are kept; `bash tests/run.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-25/summary.md
  - State: attempts 0/3; baseline 399 passing; branch todo/FEAT-143-close-gaps-that-fresh from main; next: read docs
  - [x] **FEAT-143.1** · mid · Change the skill text so that a test that cannot pass is routed to failures.md and blocked at once, an invocation ends in [x] or [!], and an agent's own scripts and total time on a node are bounded, within the load budgets
    - Done when: step 7 of todo-continue and its Test failures paragraph route an impossible test seen at the red run to failures.md, the todo-continue text says a started node ends [x] or [!] and a block of a stopped run names the limit, verification.md bounds own scripts and total time, the pins for them exist, and every load row fits its budget; `bash tests/run.sh`
  - [x] **FEAT-143.2** · mid · Rerun stuck-loop and time-limit with fresh Codex and Claude Code agents on the changed text and publish only the summary and a CSV
    - Done when: docs/evals holds a summary and runs.csv with one row per run, each run ended in a verdict or the failure is classified as skill, harness or environment, and docs/trials.md links it; `bash tests/run.sh`
    - Links: Depends: FEAT-143.1
