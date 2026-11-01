# todo-skills compared with similar tools

> **Note:** v0.3 below is the author re-scoring their own tool after the task tree, git flow, claims and trials. Treat the v0.3 rows as the least reliable numbers on this page. The v0.2 rows are kept for comparison; the other tools were not re-read.

Scored on 2026-11-01. Scores are the author's judgment from the public documentation read for this comparison. They are not benchmarks. Sources are listed at the end.

## Method

Each tool gets an integer score from 0 to 5 on 11 criteria. Totals are weighted and scaled to 0-100: `total = sum(score x weight) / 5`. Two weight profiles are used, because the right answer depends on the work.

- **Profile A, solo or lean agent workflow.** Rewards small footprint, few dependencies and strict verification. This is the case todo-skills was designed for, so it favors todo-skills. Read it with that in mind.
- **Profile B, team and spec-first work.** Rewards planning depth, parallel work and orchestration. It is the counter-case.

| # | Criterion | What a 5 looks like | Weight A | Weight B |
|---|---|---|---|---|
| 1 | Lean | A handful of small files, no installer | 15 | 5 |
| 2 | Low tooling deps | Nothing to install or run beyond the agent | 10 | 5 |
| 3 | Machine-checkable state | A tool, not the model, rejects a corrupt backlog | 10 | 10 |
| 4 | Verification rigor | Work cannot be closed without passing checks, enforced | 15 | 10 |
| 5 | Context and resume | Small active context, state survives a context reset | 10 | 10 |
| 6 | Planning and spec depth | Requirements, design and plan before code | 5 | 20 |
| 7 | Review and debugging | Independent review and a root-cause discipline | 10 | 10 |
| 8 | Task deps and orchestration | Typed dependencies, computed ready queue | 5 | 10 |
| 9 | Team and parallel | Concurrent agents or people without collisions | 5 | 10 |
| 10 | History and traceability | Finished work archived with links back to its source | 10 | 5 |
| 11 | Maturity and evidence | Widely used, documented, tested | 5 | 5 |

## Scores

| Tool | 1 Lean | 2 Deps | 3 Check | 4 Verify | 5 Ctx | 6 Plan | 7 Review | 8 Orch | 9 Team | 10 Hist | 11 Mat |
|---|---|---|---|---|---|---|---|---|---|---|---|
| todo-skills v0.3 | 3 | 5 | 5 | 4 | 4 | 3 | 3 | 4 | 3 | 4 | 1 |
| todo-skills v0.2 | 4 | 5 | 4 | 4 | 4 | 2 | 3 | 3 | 2 | 4 | 1 |
| todo-skills v0.1 | 5 | 5 | 3 | 4 | 3 | 1 | 2 | 2 | 1 | 4 | 0 |
| Superpowers | 2 | 4 | 2 | 5 | 4 | 4 | 5 | 3 | 3 | 2 | 5 |
| Spec Kit | 2 | 3 | 3 | 3 | 2 | 5 | 2 | 2 | 3 | 3 | 5 |
| BMAD | 1 | 3 | 3 | 4 | 4 | 5 | 4 | 4 | 4 | 4 | 4 |
| OpenSpec | 3 | 3 | 5 | 3 | 3 | 4 | 2 | 2 | 3 | 5 | 4 |
| Backlog.md | 3 | 3 | 4 | 3 | 4 | 3 | 2 | 4 | 4 | 4 | 4 |
| beads | 2 | 2 | 5 | 2 | 4 | 1 | 1 | 5 | 5 | 4 | 4 |
| Taskmaster | 3 | 2 | 4 | 2 | 3 | 3 | 1 | 4 | 3 | 2 | 4 |
| GSD | 2 | 3 | 3 | 5 | 5 | 5 | 4 | 4 | 3 | 4 | 4 |

## Totals

| Rank | Profile A (solo, lean) | Score | Profile B (team, spec-first) | Score |
|---|---|---|---|---|
| 1 | GSD | 75 | GSD | 81 |
| 2 | **todo-skills v0.3** | **74** | BMAD | 78 |
| 3 | todo-skills v0.2 | 72 | Superpowers | 73 |
| 4 | Superpowers | 70 | **todo-skills v0.3** | **71** |
| 5 | BMAD | 68 | Backlog.md | 68 |
| 6 | OpenSpec | 67 | OpenSpec | 67 |
| 7 | Backlog.md | 67 | Spec Kit | 63 |
| 8 | todo-skills v0.1 | 65 | todo-skills v0.2 | 62 |
| 9 | beads | 59 | beads | 60 |
| 10 | Spec Kit | 56 | Taskmaster | 57 |
| 11 | Taskmaster | 53 | todo-skills v0.1 | 48 |

v0.3 gains 2 points over v0.2 under Profile A and 9 under Profile B. The gain is in machine-checkable state (lint I1-I10 plus warnings), planning (the tree, sizes and plan docs), orchestration (computed next node, dependencies, claims) and team work (a branch per task, published claims). It gives up a point on leanness: seven skills, two reference files and a lint script are a bigger footprint than v0.2. Verification stays at 4 because the gates are followed by the model, not enforced by a tool.

## Reading the results

- GSD leads both profiles. It combines fresh-context subagents, a plan checker, a verifier and persisted state, at the price of a much larger footprint.
- todo-skills is competitive only when leanness, low dependencies and a hard verification gate matter. Its weakest scores are maturity (1), planning (3), team work (3) and review (3). No weighting fixes maturity.
- A difference of 1-2 points is noise. Moving one score by one point shifts a total by 1-4 points.
- To use your own weights, replace the weight columns and apply the formula above.

## Caveats

- todo-skills v0.3 has been exercised only by fresh agent sessions in scratch projects (`tests/trials`), not by people in real projects. The lint script and stop hook pass `tests/run.sh`, but the skills' behavior depends on the agent following them.
- The author scored their own tool. The v0.3 numbers move with a single judgment call: moving verification from 4 to 5 would add 3 points under Profile A.
- Evidence for BMAD and Taskmaster is partial. The Taskmaster documentation page failed to load, so its scores lean on release notes and earlier snippets.
- Kiro is not scored. It is an IDE, and the page read did not cover its hooks or task status.
- The maturity column rewards adoption and documentation, not quality.

## Sources

- OpenSpec: https://developertoolkit.ai/en/ecosystem/frameworks/openspec/
- Kiro specs: https://docs.plannotator.ai/frameworks/kiro-specs
- Backlog.md: https://github.com/MrLesk/Backlog.md
- beads: https://beads.gascity.com/core-concepts
- GSD: https://www.mintlify.com/gsd-build/get-shit-done/how-it-works
- Spec Kit: https://anhtnt90dev.github.io/ai-engineering-stack-guide/en/frameworks/spec-kit
- Superpowers: https://lobehub.com/skills/collection/superpowers
- BMAD: https://codemyspec.com/blog/bmad-method-explained
- Taskmaster: https://github.com/eyaltoledano/claude-task-master/releases
- Claude Code Stop hooks: https://claudefa.st/blog/tools/hooks/stop-hook-task-enforcement
