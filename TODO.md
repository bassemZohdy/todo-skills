# Active Backlog

## 🛤️ Lanes

- main: skills, lint, docs and the trial harness of this repository, one agent in order

## 🌳 Task Tree

- [ ] **FEAT-134** · P1 · mid · Guard /todo-continue workers against getting stuck: loops in build, hung commands and dead workers
  - Done when: README describes the three guards and the load budget still holds; `bash tests/run.sh`
  - State: branch todo/FEAT-134-guard-todo-continue-workers from main; next: build children
  - [x] **FEAT-134.1** · high · Count failed runs of Done when during Green as attempts, at 2, 4 and 8 runs with the same failing test
    - Done when: failures.md and todo-continue state the rule, fewer failing tests or a different failing test resets the count, and a run before implementing started is not counted; `bash tests/run.sh`
  - [x] **FEAT-134.2** · mid · Report a stale claim in /todo-status from the age of the last commit on the claimed tree's branch, report only
    - Done when: todo-status flags a claim older than four times the time budget of its complexity (optional README Budget line), never releases or resumes it, and does not flag a fresh claim; `bash tests/run.sh`
  - [ ] **FEAT-134.3** · low · Limit the run time of the Done when and regression commands, a timeout counts as a failed run
    - Done when: the helper's tests run inside the full suite and the skill text names the helper; `bash tests/run.sh`
    - State: branch todo/FEAT-134.3-limit-run-time-done from todo/FEAT-134-guard-todo-continue-workers; next: build children
    - [x] **FEAT-134.3.1** · high · Add an optional helper script that runs a command under a time limit without the timeout program
      - Done when: a command over its limit is stopped and fails with a non-zero exit status, and a command that ends in time keeps its exit status and output; `bash tests/limit.sh`
    - [ ] **FEAT-134.3.2** · mid · Tell /todo-continue to run Done when and the regression under a time limit and to count a timeout as a failed run
      - Done when: verification.md names the limit and the helper with a fallback by hand, failures.md counts a timeout as a failed run, and docs/TOOLS.md and README describe the helper; `bash tests/run.sh`
  - [ ] **FEAT-134.4** · mid · Run fresh agents on a new trial scenario whose task cannot turn green and publish the result summary
    - Done when: the scenario sets up and fails for an agent that does nothing, docs/evals holds one summary that says whether each run stopped at the loop limit, and docs/trials.md links it; `bash tests/trials/selftest.sh`
  - [ ] **FEAT-134.5** · high · Treat a worker that stopped without a verdict as resumable, and stop resuming a node that makes no progress
    - Done when: a node left active by a dead worker is not counted as a failed attempt and raises no tier, the lane coordinator reports it as resumable, and a node resumed twice with no new commit is broken down or blocked; `bash tests/run.sh`
