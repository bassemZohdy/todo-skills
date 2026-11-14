# Active Backlog

## 🌳 Task Tree

- [ ] **FEAT-125** · P1 · mid · Declare lanes in TODO.md itself: an optional Lanes section above the Task Tree, one line per lane (name: what it covers), so lane names need no plan doc
  - Done when: a TODO.md with the section lints clean, one without it still lints clean, and every child's check is green; `bash tests/run.sh`
  - State: branch todo/FEAT-125-declare-lanes-in-todo from main; next: build children
  - [x] **FEAT-125.1** · mid · Lint accepts one Lanes section before the Task Tree, fails I6 on a misplaced, duplicate or malformed lane line, and warns W9 on a root whose Lane is not declared (no section declares only main)
    - Done when: fixtures ok-lanes, I6-lanes-after-tree, I6-lane-duplicate and W9-undeclared-lane give those results, an invalid lane line is rejected, and the tools/ and .todo/ copies stay identical; `bash tests/run.sh`
  - [/] **FEAT-125.2** · low · Core skill and docs/REFERENCE.md describe the section: the schema block, the I6 row and the Lanes paragraph, inside the load budget
    - Done when: run.sh pins the new schema and I6 wording and no load-budget row is exceeded; `bash tests/run.sh`
    - State: attempts 0/3; baseline 270 passing; branch todo/FEAT-125.2-core-skill-docs-reference from todo/FEAT-125-declare-lanes-in-todo; next: read docs
  - [ ] **FEAT-125.3** · low · /todo-init writes the section with the main lane into a new TODO.md and offers to add it to an existing tree-format file
    - Done when: run.sh pins the new template and the offer, and the trial setups that start from an empty backlog expect the section; `bash tests/trials/selftest.sh`
  - [ ] **FEAT-125.4** · mid · /todo-add --lane, a Lane edit in /todo-update and /todo-plan add the lane line when they use a lane that is not declared yet
    - Done when: run.sh pins the rule in all three skills and fails when one of them lacks it; `bash tests/run.sh`
  - [ ] **FEAT-125.5** · mid · /todo-status, /todo-report and the page template show each lane's description from the section
    - Done when: the status page check renders a lane description from a fixture with the section and still renders a fixture without it; `bash tests/run.sh`
  - [ ] **FEAT-125.6** · low · The stop hook, verify, replay and report scripts and the trial fixtures accept a file with the section, and this repository's TODO.md declares its lane
    - Done when: each script passes on a fixture with the section and an untouched trial setup still fails every scenario; `bash tests/trials/selftest.sh`
- [ ] **TASK-126** · P1 · mid · Plan inside TODO.md by default: /todo-plan writes lanes and the tree and offers a plan doc only for a complex goal (more than 6 nodes, a high root, or on request), and /todo-init --plan only points to it
  - Done when: a small goal leaves no docs/plans folder and no Ref, a complex one is offered a doc per root, and every child's check is green; `bash tests/run.sh`
  - Links: Depends: FEAT-125
  - [ ] **TASK-126.1** · mid · /todo-plan drafts no PROJECT.md and writes no Ref by default, offers docs/plans/ROOT-ID-slug.md by the /todo-add rule for a complex goal, and still reads and edits a PROJECT.md that exists
    - Done when: run.sh pins the default, the complex-goal offer and the existing-doc rule, and fails on the 0.5.1 wording; `bash tests/run.sh`
  - [ ] **TASK-126.2** · mid · /todo-plan --revise works without a plan doc: it proposes none and writes the Revisions line only when the doc exists
    - Done when: run.sh pins the rule and the plan-revise trial setup, which has a plan doc, still expects its dated Revisions line; `bash tests/trials/selftest.sh`
  - [ ] **TASK-126.3** · low · /todo-init --plan, and a goal stated in the /todo-init message, only point to /todo-plan: no questions asked and no PROJECT.md offered
    - Done when: run.sh fails when todo-init still holds the three pre-planning questions or names PROJECT.md, and the docs name /todo-plan as the one planning command; `bash tests/run.sh`
  - [ ] **TASK-126.4** · mid · Add the trial scenario plan-inline: a three-task goal ends with the lanes and the tree in TODO.md, no docs/plans folder and no Ref
    - Done when: the selftest sets the scenario up and an untouched setup fails it; `bash tests/trials/selftest.sh`
- [ ] **TASK-127** · P2 · low · Run fresh agents on the changed init, plan and lane text and publish the result summary
  - Done when: docs/evals holds one summary for the batch with a result per scenario (init, plan-inline, plan-revise, add with a lane, lanes, status) and docs/trials.md links it; `bash tests/run.sh`
  - Links: Depends: FEAT-125, TASK-126
