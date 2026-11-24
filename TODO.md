# Active Backlog

## 🛤️ Lanes

- main: skills, lint, docs and the trial harness of this repository, one agent in order

## 🌳 Task Tree

- [ ] **FEAT-138** · P1 · mid · Add trial scenarios that reach the stuck-worker guards and run fresh agents on them
  - Done when: the scenarios loop-limit, time-limit, resume-stopped, resumed-twice and stale-claim set up, fail when nothing is done and have a published agent batch; `bash tests/trials/selftest.sh`
  - Links: From: FEAT-134
  - State: branch todo/FEAT-138-add-trial-scenarios-that from main; next: build children
  - [x] **FEAT-138.1** · high · Add the trial scenario loop-limit, a task whose failing test cannot be proved impossible after one run, so the loop guard's count decides
    - Done when: setup.sh builds it, doing nothing fails assert.sh, a node blocked with its test and Done when unchanged passes, and an edited test, a skipped test or an edited Done when fails; `bash tests/trials/selftest.sh`
  - [x] **FEAT-138.2** · mid · Add the trial scenario time-limit, a Done when that hangs under a README Budget line with .todo/todo-limit.sh in place
    - Done when: setup.sh builds it, doing nothing fails assert.sh, and the assertions accept a blocked node that names the limit and reject a closed node or an edited command; `bash tests/trials/selftest.sh`
  - [x] **FEAT-138.3** · mid · Add the trial scenarios resume-stopped and resumed-twice, a node left active by a worker that is gone, once resumable and once already resumed twice
    - Done when: setup.sh builds both, doing nothing fails each, resume-stopped requires the resume commit with attempts unchanged, and resumed-twice rejects a third resume commit; `bash tests/trials/selftest.sh`
  - [x] **FEAT-138.4** · mid · Add the read-only trial scenario stale-claim, a claim whose branch has had no commit for four times its budget
    - Done when: setup.sh builds it with back-dated commits, and assert.sh requires an unchanged repository and a report that names the claim as stale; `bash tests/trials/selftest.sh`
  - [/] **FEAT-138.5** · mid · Run three fresh pi agents on each new scenario, publish the summary and settle the sentences that two or more reports name
    - Done when: docs/evals holds the batch summary with one row per run and which guard each run reached, docs/trials.md links it, and the three sentences the stuck-loop batch left open are settled; `bash tests/run.sh`
    - Links: Depends: FEAT-138.6, FEAT-138.7
    - State: attempts 0/3; baseline 385 passing; branch todo/FEAT-138.5-run-three-fresh-pi from todo/FEAT-138-add-trial-scenarios-that; next: read docs
  - [x] **FEAT-138.6** · mid · Keep a scenario's name and design out of what a trial agent sees, and let the time limit of a run be raised
    - Done when: no first commit of a scratch project describes its scenario, the pi and Claude Code runners give the agent a working path without the scenario name, TRIAL_TIMEOUT replaces the fixed 1500 seconds, and runs folders of the old layout still score; `bash tests/trials/selftest.sh`
  - [x] **FEAT-138.7** · high · Settle the sentences of the stuck-worker rules that two or more agent reports call unclear
    - Done when: a failed run of the whole Done when is an attempt and the loop guard counts partial runs only, outside the node needs a reason that does not rest on the node's own tries, each other named sentence is changed or left with a recorded reason, every change is pinned, and the load budgets hold; `bash tests/run.sh`
- [ ] **TASK-139** · P1 · mid · Benchmark an initialised project and a multi-node requirement, so the setup cost is separated from the cost per task
  - Done when: the published rows cover the variant and the scenario, and a dated summary states the setup cost, the cost per task and the cost per node with their limits; `bash tests/trials/test-benchmark-harness.sh`
  - Links: Depends: TASK-137
  - [ ] **TASK-139.1** · mid · Add the benchmark variant todo-skills-existing, whose setup.sh leaves an initialised and committed backlog so the agent starts at todo-add
    - Done when: the variant runs with the stub agent, its start commit holds TODO.md, CHANGELOG.md and the README Tests line, and the coverage check does not ask for its rows; `bash tests/trials/test-benchmark-harness.sh`
  - [ ] **TASK-139.2** · mid · Add the benchmark scenario 7-multi-node, one requirement of four separable features with a hidden acceptance test for each
    - Done when: the reference solution passes the verifier, the untouched repository and a solution missing one feature fail it, and the coverage check reports the scenario as pending until rows exist; `bash tests/trials/test-benchmark-harness.sh`
  - [ ] **TASK-139.3** · mid · Run the batch with fresh pi agents and publish the rows and the summary
    - Done when: results.csv holds three runs per cell for five arms on 7-multi-node and for todo-skills and todo-skills-existing on scenarios 1 to 6, the token and cost pages are regenerated, and tests/benchmark/README.md links the summary; `bash tests/run.sh`
- [ ] **TASK-140** · P2 · mid · Rerun on Claude Code and Codex the trial scenarios added or changed since their last batches and publish the results
  - Done when: both summaries are published and docs/agent-compatibility.md states what each agent ran on the current text and what it did not; `bash tests/run.sh`
  - Links: Depends: FEAT-138
  - [ ] **TASK-140.1** · mid · Run fresh Claude Code agents on the scenarios added or changed since 2026-11-13 and publish the summary
    - Done when: docs/evals holds a summary with one row per run and every failure classified as skill, harness or environment, and docs/trials.md links it; `bash tests/run.sh`
  - [ ] **TASK-140.2** · mid · Run fresh Codex agents in Linux containers on the scenarios added or changed since 2026-11-14 and publish the summary
    - Done when: docs/evals holds a summary with one row per run and every failure classified as skill, harness or environment, and docs/trials.md links it; `bash tests/run.sh`
