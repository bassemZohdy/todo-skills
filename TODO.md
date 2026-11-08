# Active Backlog

## 🌳 Task Tree
- [ ] **FEAT-055** · P0 · high · Add an arm-agnostic agent benchmark with six scenarios, hidden acceptance tests and a trusted verifier
  - Done when: a stub agent on every scenario and arm gets PASS, FAIL, INFRA_ERROR or UNVERIFIED with hashed evidence and one CSV row, and an agent that edits the hidden tests or verifier cannot change its verdict; `bash tests/trials/test-benchmark-harness.sh`
  - Links: Ref: docs/evals/update-review.md
- [ ] **FEAT-056** · P1 · mid · Split the review verdict into spec compliance and quality in one reviewer call
  - Done when: todo-continue, git-flow and the docs record Reviewed: subagent, spec ok|fail quality ok|fail, n findings fixed, and keep Reviewed: self for the fallback; `bash tests/run.sh`
  - Links: Ref: docs/evals/update-review.md
- [ ] **FEAT-057** · P1 · mid · Offer an optional fresh-context review of a high-risk root's whole diff before it drains
  - Done when: high, security, migration, concurrency or public-interface roots are offered one review of the whole root diff, plan doc and Ref, low and mid roots never are, and without a subagent a new-session review is offered; `bash tests/run.sh`
  - Links: Ref: docs/evals/update-review.md
- [ ] **FEAT-058** · P1 · mid · Add an ambiguity checklist and three stop triggers to /todo-plan and /todo-add
  - Done when: a reference checklist and the stop triggers apply only to unclear requests, keep the 3-question cap, and send open questions to the plan doc or a blocked node, never a new TODO.md section; `bash tests/run.sh`
  - Links: Ref: docs/evals/update-review.md
- [ ] **FEAT-059** · P1 · high · Let .todo/check.sh optionally replay the Validated commands of newly drained roots
  - Done when: safe Validated commands added since a revision run and their failure fails the check, while a command that breaks the lint safety rules or uses an unknown runner is shown and refused, never run; `bash tests/run.sh`
  - Links: Ref: docs/evals/update-review.md
- [ ] **FEAT-060** · P1 · mid · Warn (W5) when a high or security-titled node's Done when names no negative case
  - Done when: such a node without rejects, denies, fails, refuses, raises, unauthorized or invalid gets W5, one with them or an ordinary node gets none, and warnings never change the exit code; `bash tests/run.sh`
  - Links: Ref: docs/evals/update-review.md
- [ ] **TASK-061** · P2 · low · Report the bytes and words each command loads and fail over the documented budget
  - Done when: tests/run.sh prints each command's loaded bytes and words and fails when one exceeds its budget in docs/DEVELOPMENT.md; `bash tests/run.sh`
  - Links: Ref: docs/evals/update-review.md
- [ ] **TASK-062** · P2 · low · Release 0.5.0 after the update items land
  - Done when: CHANGELOG has a dated 0.5.0 section and both plugin manifests and README carry 0.5.0; `grep -q '^## \[0.5.0\] - ' CHANGELOG.md`; regression: `bash tests/run.sh`
  - Links: Depends: TASK-054, FEAT-055, FEAT-056, FEAT-057, FEAT-058, FEAT-059, FEAT-060, TASK-061
