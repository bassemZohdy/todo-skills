# Active Backlog

## 🛤️ Lanes

- main: skills, lint, docs and the trial harness of this repository, one agent in order

## 🌳 Task Tree

- [ ] **TASK-126** · P1 · mid · Plan inside TODO.md by default: /todo-plan writes lanes and the tree and offers a plan doc only for a complex goal (more than 6 nodes, a high root, or on request), and /todo-init --plan only points to it
  - Done when: a small goal leaves no docs/plans folder and no Ref, a complex one is offered a doc per root, and every child's check is green; `bash tests/run.sh`
  - Links: Depends: FEAT-125
  - State: branch todo/TASK-126-plan-inside-todo-md from main; next: build children
  - [x] **TASK-126.1** · mid · /todo-plan drafts no PROJECT.md and writes no Ref by default, offers docs/plans/ROOT-ID-slug.md by the /todo-add rule for a complex goal, and still reads and edits a PROJECT.md that exists
    - Done when: run.sh pins the default, the complex-goal offer and the existing-doc rule, and fails on the 0.5.1 wording; `bash tests/run.sh`
  - [x] **TASK-126.2** · mid · /todo-plan --revise works without a plan doc: it proposes none and writes the Revisions line only when the doc exists
    - Done when: run.sh pins the rule and the plan-revise trial setup, which has a plan doc, still expects its dated Revisions line; `bash tests/trials/selftest.sh`
  - [x] **TASK-126.3** · low · /todo-init --plan, and a goal stated in the /todo-init message, only point to /todo-plan: no questions asked and no PROJECT.md offered
    - Done when: run.sh fails when todo-init still holds the three pre-planning questions or names PROJECT.md, and the docs name /todo-plan as the one planning command; `bash tests/run.sh`
  - [x] **TASK-126.4** · mid · Add the trial scenario plan-inline: a three-task goal ends with the lanes and the tree in TODO.md, no docs/plans folder and no Ref
    - Done when: the selftest sets the scenario up and an untouched setup fails it; `bash tests/trials/selftest.sh`
- [ ] **TASK-127** · P2 · low · Run fresh agents on the changed init, plan and lane text and publish the result summary
  - Done when: docs/evals holds one summary for the batch with a result per scenario (init, plan-inline, plan-revise, add with a lane, lanes, status) and docs/trials.md links it; `bash tests/run.sh`
  - Links: Depends: FEAT-125, TASK-126
