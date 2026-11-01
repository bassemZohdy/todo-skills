# todo-skills compared with similar tools

> **Note:** the todo-skills rows below score v0.2, before the task tree, git flow and no-git mode were added. They have not been re-scored.

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
| 2 | **todo-skills v0.2** | **72** | BMAD | 78 |
| 3 | Superpowers | 70 | Superpowers | 73 |
| 4 | BMAD | 68 | Backlog.md | 68 |
| 5 | OpenSpec | 67 | OpenSpec | 67 |
| 6 | Backlog.md | 67 | Spec Kit | 63 |
| 7 | todo-skills v0.1 | 65 | **todo-skills v0.2** | **62** |
| 8 | beads | 59 | beads | 60 |
| 9 | Spec Kit | 56 | Taskmaster | 57 |
| 10 | Taskmaster | 53 | todo-skills v0.1 | 48 |

v0.2 gains 7 points over v0.1 under Profile A and 14 under Profile B. Almost all of the gain is in machine-checkable state, resume, review and orchestration. It gives up a point on leanness.

## Reading the results

- GSD leads both profiles. It combines fresh-context subagents, a plan checker, a verifier and persisted state, at the price of a much larger footprint.
- todo-skills is competitive only when leanness, low dependencies and a hard verification gate matter. Its weakest scores are planning (2), team work (2) and maturity (1). No weighting fixes those.
- A difference of 1-2 points is noise. Moving one score by one point shifts a total by 1-4 points.
- To use your own weights, replace the weight columns and apply the formula above.

## Caveats

- todo-skills v0.2 has not been run in a live agent session. The lint script and stop hook pass `tests/run.sh`, but the skills' behavior depends on the agent following them.
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
