# pi + GLM 5.3: the Lanes section and inline planning (2026-11-14)

> Only this summary is published. The evidence of these runs (prompts, session logs, Git state) stays with the maintainer.

FEAT-125 let `TODO.md` declare its lanes in an optional `## 🛤️ Lanes` section, and TASK-126 made `/todo-plan` plan inside `TODO.md` (a plan doc only for a complex goal) and left `/todo-init` with no planning of its own. This batch asks whether fresh agents follow the changed text of `/todo-init`, `/todo-plan`, `/todo-add`, `/todo-continue --all-lanes` and `/todo-status`.

## Setup

- Agent: pi 1.5.2 with `glm-5.3` on z.ai, a fresh session per run, tools `read,powershell,edit,write`.
- Host: Windows 11 with Git Bash, unisolated verifier (`TRIAL_WINDOWS_ISOLATION=0`).
- Skill text: commit `3231aae` for the six scenarios, commit `7be0a11` for the `plan-inline` rerun (the only change between them is below).
- One run per scenario. The new scenarios `plan-inline` and `add-lane` were added in this batch (TASK-126.4 and TASK-127); an untouched setup fails each of them.

## Results

| Scenario | What it checks | Outcome | Assertions | Tool calls |
|---|---|---|---|---|
| `monorepo` (init) | `/todo-init` creates `TODO.md` with the Lanes section and `main`, asks nothing about planning, then `/todo-add` and `/todo-continue --merge` finish a root | PASS | 17 of 17 | 50 |
| `plan-inline` | `/todo-plan` writes the tree inside `TODO.md`, no `docs/plans` folder, no `Ref:`, no undeclared lane | FAIL, then PASS on the rerun (below) | 11 of 12, then 12 of 12 | 15, then 16 |
| `replan` (plan-revise) | `/todo-plan --revise` drops a node of an existing tree with a plan doc and logs the dated Revisions line | PASS | 15 of 15 | 22 |
| `add-lane` | `/todo-add --lane math` adds the `math` lane line to the Lanes section with a description and keeps `main` | PASS | 13 of 13 | 19 |
| `lanes` | `/todo-continue --all-lanes --merge` on a tree whose lanes are declared | PASS | 16 of 16 | 60 |
| `status-readonly` | `/todo-status` changes nothing and groups the roots under the lane with its description | PASS | 8 of 8 | 9 |

### The `plan-inline` failure

The first run failed one assertion, which required at least three tasks. The agent wrote one root, `FEAT-001`, for "add subtract, multiply and divide to calc.py, each with its own test", because the scope rule makes three small functions in two files one leaf. That is what the skill says, so the assertion was wrong, not the agent (the same pattern as TASK-124). The assertion now accepts one leaf or three and still requires that all three functions are planned with a unittest `Done when`, in open tasks. The rerun on the final text chose a root with three children and passed 12 of 12. Every other assertion of the first run passed: the Lanes section was kept, no plan doc and no `Ref:` were written, the lint passed with no W9, and only `TODO.md` changed.

### One wording fix from the reports

The agent of the first `plan-inline` run reported a conflict in `/todo-plan`: step 3 said to draft a lane line when there is "one track", while step 4 and the core said `main` needs no line. Step 3 now says `main` needs no line and a single-track plan adds none, and a check in `tests/run.sh` pins it. The rerun did not raise it again.

## What the agents reported as unclear

Each agent lists the ambiguities it met. Those about the changed text, none of them blocking, and not changed by this batch:

- `add-lane`: whether a single new leaf that brings a new lane line still waits for a "yes" (step 9 says a single leaf needs none); `reference/lanes.md` says it is loaded only by `/todo-continue` lane flags, while the core lists it under "a lane flag" for all commands; `todo-add` states the lane name as lowercase letters, digits and dashes, the core adds that it starts with a letter.
- `replan`: where **Out of scope** goes when the plan doc has no **Scope**, and what the created section holds.
- `lanes`: older points in `reference/lanes.md` and `git-flow.md` (the switch back to the root branch after a claim, when `next: drain` is written for a lane leaf), none about the Lanes section.

They are candidates for a follow-up wording task, not defects of the Lanes section itself.

## Limits

- One run per scenario, one agent, one host: the results show that a fresh agent can follow the text, not how often.
- Claude Code and Codex were not run on this text.
- `ci-github`, `ci-local` and `report` were not run. The HTML status page was checked only by `tests/run.sh` (the lane-description parser under Node and the embedded template), not by an agent, and the page was not opened in a browser.
- The `plan-inline` assertion was changed after its first run, in light of what the agent did; the rerun is the evidence for the final assertion.
