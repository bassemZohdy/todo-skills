# todo-skills compared with similar tools

> **Note:** the scores below were produced by an independent reviewer that read each tool's primary sources (official repositories and docs) and did **not** see the author's scores. The author's own scores for todo-skills are shown beside the reviewer's. The earlier version of this page, with scores written by the author for every tool from secondary articles, is replaced.

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
| Superpowers | 3 | 4 | 0 | 3 | 2 | 4 | 5 | 1 | 3 | 1 | 5 |
| Spec Kit | 2 | 2 | 2 | 3 | 4 | 5 | 3 | 2 | 3 | 3 | 5 |
| BMAD (low confidence) | 1 | 1 | 1 | 3 | 4 | 5 | 4 | 2 | 3 | 3 | 4 |
| OpenSpec | 3 | 4 | 4 | 2 | 4 | 4 | 2 | 2 | 3 | 5 | 4 |
| Backlog.md | 3 | 3 | 3 | 3 | 4 | 2 | 1 | 3 | 3 | 4 | 4 |
| beads | 1 | 2 | 4 | 1 | 5 | 1 | 0 | 5 | 5 | 4 | 4 |
| Taskmaster | 2 | 2 | 3 | 1 | 3 | 3 | 0 | 4 | 2 | 1 | 4 |
| GSD (low confidence) | 1 | 2 | 2 | 3 | 5 | 5 | 3 | 3 | 3 | 3 | 4 |
| **todo-skills 0.1.0, reviewer (after simplifying)** | 4 | 5 | 4 | 3 | 5 | 2 | 3 | 3 | 3 | 4 | 2 |
| todo-skills, earlier reviewer (before simplifying) | 4 | 5 | 4 | 3 | 4 | 2 | 2 | 3 | 2 | 4 | 1 |
| todo-skills, author | 3 | 5 | 5 | 4 | 4 | 3 | 3 | 4 | 3 | 4 | 1 |

## Totals

| Rank | Profile A (solo, lean) | Score | Profile B (team, spec-first) | Score |
|---|---|---|---|---|
| 1 | **todo-skills 0.1.0** | 73 | GSD (low confidence) | 68 |
| 2 | OpenSpec | 66 | Spec Kit | 66 |
| 3 | Backlog.md | 60 | OpenSpec | 66 |
| 4 | Spec Kit | 58 | **todo-skills 0.1.0** | 65 |
| 5 | GSD (low confidence) | 57 | BMAD (low confidence) | 63 |
| 6 | Superpowers | 55 | Superpowers | 57 |
| 7 | BMAD (low confidence) | 52 | Backlog.md | 56 |
| 8 | beads | 51 | beads | 55 |
| 9 | Taskmaster | 40 | Taskmaster | 47 |

Before simplifying, a reviewer of the same kind gave todo-skills 67 (A) and 58 (B). The author's own scores would give 74 and 71, which shows the size of the self-scoring bias. Use the reviewer's numbers.

## Reading the results

- Under Profile A, which was designed around lean solo work, todo-skills leads by 7 points over OpenSpec. Under Profile B the spec-heavy tools (GSD, Spec Kit, OpenSpec) lead and todo-skills is fourth.
- The reviewer scored todo-skills low on planning (2) and maturity (2), middling on verification (3: enforced by the model, not a tool), review, dependencies and team (3 each), and high on tooling dependencies (5), context and resume (5) and machine-checkable state (4). It named three weaknesses: advisory enforcement of "done", almost no field evidence, and thin planning and orchestration.
- A difference of 1-2 points is noise. Moving one score by one point shifts a total by 1-4 points. To use your own weights, replace the weight columns and apply the formula above.

## Caveats

- Evidence for BMAD and GSD is partial and marked low confidence; GSD's original repository is archived and development moved to `open-gsd/gsd-core`.
- Sources were fetched through a summarising tool, so details can be missed. Treat each row as a best reading, not a measurement.
- The maturity column rewards adoption and documentation, not quality.
- The reviewer worked from a copy of the repository read through the GitHub API; todo-skills has since gained more trials (races, release, monorepo) that are not reflected.
- Kiro is not scored. It is an IDE, and its hooks and task status were not covered.
- Corrections found on the way: Superpowers is not a task tracker and is prompt-only on verification; OpenSpec has a standalone binary and a `validate` command; beads now uses Dolt and git is optional; Taskmaster does not check tests when a task is marked done and is MIT with Commons Clause; Backlog.md does not require git.

## Sources

- Superpowers: https://github.com/obra/superpowers
- Spec Kit: https://github.com/github/spec-kit
- BMAD: https://github.com/bmad-code-org/BMAD-METHOD
- OpenSpec: https://github.com/Fission-AI/OpenSpec
- beads: https://github.com/steveyegge/beads
- GSD: https://github.com/open-gsd/gsd-core
- Taskmaster: https://github.com/eyaltoledano/claude-task-master
- Backlog.md: https://github.com/MrLesk/Backlog.md

Secondary articles used for the earlier version of this page:

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
