# Update review, 2026-11-08 (Phase 0)

A review of todo-skills 0.4.0 (`8565d62`) done before changing anything. It checks nine findings from an earlier review
that read only the documentation and did not run anything. It also checks what already covers each proposed item,
reconciles a third-party "lean single-file prompt" and sets the work order.

## Baseline

- `bash tests/run.sh`: **141 passed, 0 failed** (exit 0).
- `bash tools/todo-lint.sh TODO.md CHANGELOG.md`: `OK: invariants I1-I10 hold` (the backlog was empty).
- Read in full: README.md, the core skill, `todo-continue`, `todo-plan` and `todo-add`, `reference/verification.md`,
  `reference/ci.md`, `tools/todo-lint.sh`, `.todo/check.sh`, and the evidence section of `docs/COMPARISON.md`. Read in
  part, where an item touches them: the other skills and reference files, `tests/run.sh` and the `docs/` pages. Not every
  page in `docs/` was read in full; each page is read where a change lands on it.

## Findings F1-F9

| # | Verdict | Evidence |
|---|---|---|
| F1 | NOT CONFIRMED | README.md:3 says `version 0.4.0`; README.md:26 installs with `cp -r todo-skills/plugin/skills/*`, which exists. Both manifests and the newest CHANGELOG heading are 0.4.0. **Gap:** nothing tests the README version or install path. `tests/run.sh:35` compares only `plugin.json` with CHANGELOG. |
| F2 | CONFIRMED | The review step reviews one node's diff (`todo-continue/SKILL.md:44-48`). A parent's integration step adds no feature code, so its diff is small. The optional design review (`todo-plan/SKILL.md:35-41`) reviews the plan before the build, not the root's combined diff before the drain. |
| F3 | CONFIRMED | One verdict: `Reviewed: <subagent\|self>, <n> findings fixed` (`todo-continue/SKILL.md:56`, `reference/git-flow.md:26`, `docs/VERIFICATION.md:58`). |
| F4 | PARTIAL | Both commands ask at most 3 questions: `/todo-plan` on goal, scope and parallel tracks (`todo-plan/SKILL.md:16`), `/todo-add` when behaviour, module or command can't be derived (`todo-add/SKILL.md:20`), and `--clarify` forces a round. There is no checklist and no stop triggers for missing business rules, incompatible implementations or unstated authorization. |
| F5 | CONFIRMED | `.todo/check.sh` runs the lint and the suite (`reference/ci.md:14-21`, this repo's `.todo/check.sh`). No `Validated:` command is ever re-run after the drain. |
| F6 | CONFIRMED | The lint has W1-W4 only (`tools/todo-lint.sh:10`); no warning looks at negative cases. |
| F7 | PARTIAL | `reference/lanes.md` (4,806 bytes) already loads only with a lane flag (`todo-continue/SKILL.md:9`). The interrupted-merge and interrupted-drain bullets (`todo-continue/SKILL.md:24-25`) are 475 bytes, and the "no git" clauses are about 783 bytes, together 2.3% of the 54,066 bytes `/todo-continue` loads. That is too little to justify moving them (see the rulings below). |
| F8 | NOT CONFIRMED | README.md:80 says "Claude Code and Codex have run lifecycle trials", and README.md:117 and `docs/agent-compatibility.md` describe both. Neither says only Claude Code is tested. |
| F9 | CONFIRMED | `tests/run.sh` has no size check. Measured today (bytes and words; tokens were not measured): |

| Command (always loaded) | Bytes | Words |
|---|---|---|
| `/todo` (core) | 22,492 | 3,645 |
| `/todo-init` | 29,791 | 4,808 |
| `/todo-init --ci` (+ ci, verification) | 42,671 | 6,868 |
| `/todo-plan` (+ todo-add, verification) | 43,317 | 7,104 |
| `/todo-add` (+ verification) | 37,104 | 6,067 |
| `/todo-continue` (+ git-flow, verification) | 54,066 | 8,722 |
| `/todo-continue --lane` (+ lanes) | 58,872 | 9,526 |
| `/todo-update` | 30,980 | 5,030 |
| `/todo-status` | 26,179 | 4,233 |
| `/todo-report` (+ template) | 38,658 | 4,644 |
| `/todo-release` | 26,095 | 4,195 |

## Already present

| Proposed | Existing coverage |
|---|---|
| Forced clarification | `/todo-add --clarify` (`todo-add/SKILL.md:20`) |
| Strict verification | `tools/todo-verify.sh --strict` (`reference/verification.md:15`) |
| Requirements traceability | optional RTM, `reference/rtm.md`, `tools/todo-rtm.sh` |
| Definition of Done | `reference/verification.md:34-36` |
| Design review | optional, fresh context, `todo-plan/SKILL.md:35-41`. Item D reuses it. |
| Exit-0 gate | `todo-continue/SKILL.md:50`; zero tests, masked failures and missing paths fail |
| Resume procedure | `todo-continue/SKILL.md:26` and core "Interrupted work comes first" |
| Final summary | `todo-continue/SKILL.md:64` (step 11, Report) |

## Candidate lean prompt

The original text was not supplied, only a summary of it. The experiment therefore uses a template **rebuilt from the
listed features** (a `# Task:` heading, IN_PROGRESS status, `task/<name>` branch and `.worktrees/`, five checkboxes per
subtask, commit hashes, `## Open Questions`, a session log and `[closes subtask #X]`):
[`update-review/lean-template.md`](update-review/lean-template.md). `bash tools/todo-lint.sh lean-template.md /dev/null`
exits 1 with **16 × I3 and 5 × I6** ([output](update-review/lean-template-lint.txt)): the heading and the extra sections
break I6, and the status lines, subtask checkboxes and log lines break I3. So the template cannot share a repository with
the backlog.

| Part | Decision |
|---|---|
| Ambiguity stop protocol | ADAPT (item E): a `reference/` checklist and three stop triggers. Questions go to the plan doc's Open questions or a `[!]` node, with at most 3 per round, and rounds can repeat. |
| Negative tests and an edge-case matrix | ADAPT (item G): lint warning W5 and guidance in `verification.md`. Not an invariant, and not a new TODO.md section. |
| Per-task template, statuses, `## Open Questions` in TODO.md, five checkboxes, `.worktrees/` and `task/` branches, hashes or a log in TODO.md, `[closes subtask #X]` | REJECT: breaks I3 and I6, the 120-line cap, the markers, the `todo/` branch names and Conventional Commits |
| Exit-0 gate, resume, final summary | ALREADY PRESENT (above) |
| The prompt as a whole | Benchmark arm `lean-baseline` (item B): a clean rewrite from the summary, labelled as such |

## Work order

Each item is one root, worked through the repository's own workflow.

1. **TASK-054 (A + I), P0:** this review, tests that README's version equals both manifests and the newest CHANGELOG heading and that the README install path exists, and a README line naming each agent with its evidence file. F1 and F8 found no wrong text, so no claim changes.
2. **FEAT-055 (B), P0:** a benchmark harness in `tests/benchmark/` with six scenarios, three arms, a trusted verifier, a CSV and a stub-agent self-test.
3. **FEAT-056 (C), P1:** two-verdict reviewer `Reviewed: subagent, spec <ok|fail> quality <ok|fail>, <n> findings fixed`, keeping `Reviewed: self, <n> findings fixed`.
4. **FEAT-057 (D), P1:** optional root review before the drain, reusing the design-review mechanism, which moves into a shared `reference/review.md`.
5. **FEAT-058 (E), P1:** ambiguity checklist and stop triggers in a new `reference/clarify.md`, loaded by `/todo-plan` and `/todo-add` only when the request is unclear.
6. **FEAT-059 (F), P1:** an optional `tools/todo-replay.sh` that re-runs the `Validated:` commands of newly drained entries. It checks each command against the lint's own I3/I10 rules and runner list, and shows anything that fails without running it.
7. **FEAT-060 (G), P1:** lint W5 with true-positive and false-positive fixtures, and negative-case guidance in `verification.md`.
8. **TASK-061 (H), P2:** a load-size budget check in `tests/run.sh`, with budgets documented in `docs/DEVELOPMENT.md` and set from the sizes measured after items 2-7.
9. **TASK-062, P2:** release 0.5.0 (MINOR, new optional capabilities).

Dropped or shrunk:

- F1 and F8 text fixes: nothing is wrong, so only the guards are added.
- F7 moves: lanes are already on demand, and the remaining 2.3% isn't worth moving (Ruling 2).
- Item I as a benchmark run: no agent run in this environment (Ruling 3), so it reduces to the README evidence line.

## Rulings

- Ruling 1: The work happens in the maintainer's existing checkout. It is clean and at `origin/main`, so it is equivalent to a fresh clone. Nothing is pushed, tagged or published.
- Ruling 2: The rare `/todo-continue` branches stay inline. They are 2.3% of its load, and moving them would spread one procedure over two files for no measured gain. Item H's budget check will catch growth.
- Ruling 3: No benchmark agent is run here. On this Windows host Codex's sandbox blocks the `.git` writes the todo-skills arm needs (TASK-045: 6 of 8 INFRA_ERROR), so that arm would measure the sandbox, not the method. The protocol is also at least 54 agent runs, which is the maintainer's cost to choose. The harness ships with an empty results file and the exact command.
- Ruling 4: The `lean-baseline` arm and the lint experiment use rewrites of the summarised prompt, because the original text was not available. Both say so.
- Ruling 5: The item C and D review formats are checked statically in `tests/run.sh`, and the benchmark's runner records review trailers, so their effect can be measured once real runs exist.
- Ruling 6: The reviewer's two verdicts come from one subagent call, as the brief asks, so the review step's cost does not double.
