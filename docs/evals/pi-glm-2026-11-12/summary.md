# pi + GLM 5.3: fresh-agent trials and benchmark (2026-11-12)

Fresh [pi](https://github.com/badlogic/pi-mono) agents (pi 1.5.2, provider `zai`, model `glm-5.3`, pi's default thinking level `high`) followed the skills in the 29 trial scenarios and in the agent benchmark that had never been run. Codex 0.167.2 (`gpt-6.1-terra`, read-only, no tools) reviewed the findings and the new scripts. Host: Windows 11, Git Bash, Python 3.13 (Microsoft Store alias), **Node 24 and Java 25** (the repo targets Node 22 and Java 17; the TypeScript and Java scenarios passed anyway).

**What this is not.** A single model family, one host, one run per scenario (four for `blocked-sibling`), three runs per benchmark cell. The trial assertions ran **unisolated** (`TRIAL_WINDOWS_ISOLATION=0`; `verifier.txt` in every run says so), so these results are not equal to the isolated Windows batches in `docs/evals/codex-windows-2026-11-08/`. Nothing here replaces the Claude Code and Codex evidence.

## Agent setup (only the todo skills visible)

| | pi | Codex |
|---|---|---|
| Updated first | 1.0.0 to 1.5.2 (`pi update self`) | 0.167.0 to 0.167.2 (`codex update`) |
| Leaks found | none: `pi list` empty, no `~/.pi/agent` skills or `AGENTS.md` | the user profile loaded ~45 skills (`~/.agents/skills`, `~/.codex/skills`), account connectors, MCP servers and a custom `instructions.md` |
| Isolation used | `--no-extensions --no-skills --no-context-files --no-prompt-templates --no-themes` (trials); the benchmark adapter keeps skills and context files on, because the `todo-skills` arm installs them in the scratch repo | a separate `CODEX_HOME` with only the login and a minimal config (`apps`, `plugins`, `computer_use`, `browser_use`, `multi_agent` off) **and** every user skill disabled by path in `[[skills.config]]`, because `~/.agents/skills` is read from the real profile, not from `HOME` or `USERPROFILE` |
| Verified | a probe listed no skills, extensions, templates or instructions | a probe listed no skills |
| Role | all trial and benchmark runs | reviewer only (three reviews). Windows read-only Codex could not run shell commands, so the skill text was embedded in the prompt instead |

## Skill text versions

The skill text changed during the work, so every result names the version it ran on.

| | Text | Used by |
|---|---|---|
| T0 | `main` at `bae7f51`, unchanged | `happy-path`, `team-claim`, `ts-baseline-red`, `ts-interrupted`, `java-baseline-red`, `java-interrupted` |
| T1 | T0 + four `todo-continue` fixes (W3, "added" export, baseline branch, `State:`) | `replan`, `add-fix` |
| T2 | T1 + three more (interrupted-merge lint, report field, failing test ids) | the 22-scenario queue; benchmark rep 1 |
| T3 | T2 + one sentence in the core on changing a marker | the three `blocked-sibling` reruns; benchmark reps 2 and 3 |

## Trial results

Runs are in `runs/<text>-<scenario>/` (`outcome.txt`, `versions.txt`, `verifier.txt`, `prompt.txt`, `report.txt`, `assert.log`, `git-state.txt`, and pi's own session log as `session.jsonl.gz`).

| Result | Scenarios |
|---|---|
| PASS, first run | `happy-path` (T0 and T2), `team-claim`, `ts-baseline-red`, `java-baseline-red`, `ts-interrupted`, `java-interrupted`, `replan`, `add-fix`, `baseline-red`, `interrupted-merge`, `refresh-from-base`, `claimed-elsewhere`, `race-claim-conflict`, `race-claim-benign`, `monorepo`, `ts-lifecycle`, `java-lifecycle`, `lanes`, `multi-module`, `no-git`, `release`, `release-ask`, `report`, `status-readonly`, `update-block`, `update-drop`, `ci-github`, `ci-local` |
| FAIL, then fixed | `blocked-sibling` (T2): the agent chose the right node but rewrote the task line as `  [/] **FEAT-001.2**` without the leading `- `; the lint reports I3. With the T3 sentence it passed 3 of 3 |

`team-claim`, `ts-baseline-red`, `java-baseline-red`, `ts-interrupted` and `java-interrupted` had never had an agent run. `ci-local` passed here; with headless Claude Code it was an INFRA_ERROR (it may not write `.git/hooks`). `lanes` and `multi-module` ran sequentially because pi has no subagent tool: they show the documented fallback, not concurrent lanes.

**The `blocked-sibling` fix is supported by 3 of 3, not proven.** One failure on a text that never said to keep the bullet, three passes after it. Claude Code and Codex had passed this scenario 3 of 3 before, so the slip may be specific to this model. The same report claimed "invariant check: pass" for a file the lint rejects: with no lint script in the project the check is done by reading, and this agent's reading missed its own edit.

### Discarded runs (self-inflicted)

Two trial runs (`monorepo`, `ts-lifecycle`) and two benchmark cells (`todo-skills` `1-bugfix` and `2-api-feature`, rep 1) were killed by the controller after the agent had finished, because `run-pi.sh` and `pi.sh` were edited while bash was reading them (`syntax error near unexpected token` and `nsions: command not found`, exit 127). They are not scored. The trials were rerun from scratch; the two cells stay in `benchmark/results.csv` as INFRA_ERROR and were rerun.

## Findings in the skill text

Each was reported by a pi agent, then checked against the shipped text. The `plugin/` folder is all an installed user has, so a name defined only in `docs/` or `tools/` counts as undefined.

| # | Finding | Evidence | Status |
|---|---|---|---|
| F1 | `todo-continue` 10.2 records `Checked:` "for each W3 command"; W3 is defined only in `docs/REFERENCE.md` and `tools/todo-lint.sh`; the plugin defines W1, W2, W5 | 2 runs; Codex CONFIRMED | fixed: the rule now says which commands. Residual: 1 of 22 T2 reports calls the new wording a judgment call when no lint exists |
| F2 | "public interface ... renamed, removed or with a changed meaning" does not say whether adding an export counts; two runs resolved it in opposite ways | 2 runs; Codex CONFIRMED | fixed: "added" in the doc-drift trigger (and `docs/VERIFICATION.md`). Open: see below |
| F4 | Baseline "on the nearest ancestor branch that exists" has no answer for a new, unclaimed tree | 4 runs (T0); Codex PARTLY | fixed for the unclaimed tree: "(the base for an unclaimed tree)". **Residual:** 8 of 25 later reports (5 of 22 T2, 3 of 3 T3) still quote the sentence, now about a new leaf in an already-claimed tree, whose own branch does not exist yet; every one resolved it the same, correct way (the parent's branch) |
| F5 | "update `State:` after every cycle" but no value is defined for a passing cycle; two runs did different things | 2 runs; Codex CONFIRMED | fixed: update when a cycle changes an item |
| G1 | Interrupted merge: "finish it as step 10 item 3, lint, report" but item 3 has no lint | 2 runs | fixed |
| G2 | Step 11 demands "regression against the baseline" on paths that run no tests | 3 runs | fixed: say "not run" |
| G3 | "failing test ids" has no format (Surefire prints two forms, `node --test` a name and a location) | 2 runs | fixed: "as the runner prints them" |
| M1 | "set `[/]`" does not say to keep the `- ` bullet | 1 run (FAIL), then 3 passes | fixed: one sentence in the core |

Checked and **rejected** (Codex part B): `template.md` missing from `todo-report` (it exists; my prompt had left it out), the lint-script references in `ci.md` and `todo-continue` (conditional on the script existing), the "step 4/5" pointer in `git-flow-edge.md` (consistent), the "Start commit" title (a pointer, not a defect).

**Seen once, not changed:** F3 (the root review "asks once" cannot be answered in a non-interactive run; the agent made the offer in its report and went on); how a child merge passes its message; four gaps in the conflict rules found by `team-claim` (what "the base" means mid-merge, which number a renumbered root gets, document order afterwards, whether its own `Depends:` is rewritten), all resolved correctly by the agent.

**Open question for the maintainer.** Seven T2 reports mention the "public interface" trigger. After F2 the doc-drift grep fires on every added export, which is cheap and now consistent. One agent also notes that the *root review* trigger (`review.md`: "a public interface (a command, flag, endpoint, config key or exported symbol)") reads as firing for almost any new function. That was true before the change; the effect is a one-time offer in the report. Narrowing it is a design choice and was not made.

**Environment note.** On this host the scratch repos are checked out with CRLF (`core.autocrlf=true`); one agent's exact-match edit of `TODO.md` failed on it and it rewrote the file. Harness setup that writes the scenario files with LF would avoid that.

## Benchmark (first real run of `docs/evals/benchmark`)

Three arms by six scenarios, three runs each, GLM 5.3 through `agents/pi.sh`, hidden tests copied outside any agent folder. Isolation is `provisional` (pi has no sandbox). INFRA_ERROR cells are excluded from the denominators. `benchmark/results.csv` has every cell; `benchmark/cells/` holds each cell's report and verifier log.

| Scenario | no-methodology | lean-baseline | todo-skills |
|---|---|---|---|
| 1-bugfix | 3/3 | 3/3 | 3/3 |
| 2-api-feature | 3/3 | 2/3 | 3/3 |
| 3-security-token | 3/3 | 3/3 | 3/3 |
| 4-multi-module | 3/3 | 2/3 | 3/3 |
| 5-interrupted | 3/3 | 3/3 | **0/3** |
| 6-ambiguous | 1/3 | 2/3 | 3/3 |
| **Total** | **16/18** | **15/18** | **15/18** |

| Arm | Median time | Median input tokens | Median output tokens |
|---|---|---|---|
| no-methodology | 26 s | 41k | 1.7k |
| lean-baseline | 76 s | 124k | 3.7k |
| todo-skills | 320 s | 1,039k | 19.2k |

How to read it:

- **The arms are not separated by correctness on these tasks.** 15 to 16 of 18 with three runs per cell is within noise; this does not show the skills help or hurt a small, well-specified task.
- **Cost is large.** The `todo-skills` arm used roughly 25 times the input tokens and 12 times the time of the control. Input tokens are the context re-sent on each of about 30 model calls, and 95% of them were served from cache (measured from `results.csv`); how much of it is skill text was not measured.
- **The one place the skills clearly win is `6-ambiguous`:** 3 of 3 stopped and asked what "loyal" means; the control asked in 1 of 3 and `lean-baseline` in 2 of 3.
- **The one place they clearly lose is `5-interrupted`, by design:** with uncommitted work from a dead session the clean-tree rule stops and asks, in 3 of 3 runs, and the hidden test wants the function finished. The agent was following the skill. Whether the skills should offer to commit the leftover work as a default is a design question, not a defect.
- **What the hidden tests do not measure:** traceability, a green history, a drained changelog, resumability. Those are what the trials assert and are the skills' actual purpose.
- Skill text changed between rep 1 (T2) and reps 2 and 3 (T3).

## Harness changes in this batch

- `tests/trials/run-pi.sh`: the pi twin of `run-claude.sh`; records pi, provider, model, thinking level, tools, Node and Java in `versions.txt`, says in `verifier.txt` whether the assertions were isolated, and treats **zero tool calls** in pi's session log as INFRA_ERROR (pi started with an allowlist it cannot satisfy, such as `bash` on Windows, answers with no tools and no error).
- `docs/evals/benchmark/agents/pi.sh` and a `pi.summary` branch in `usage.sh`: token counts come from pi's own session log (summed assistant usage), never estimated.
- Codex reviewed both scripts. Accepted: an absolute evidence path (a relative runs folder would have counted zero tool calls), one session folder per invocation (a retry would have added the earlier attempt's usage), NUL-delimited checksums. Rejected: zero tool calls as a verdict (an agent that followed a skill must have read its files), and two issues the existing Claude and Codex adapters share.

## Evidence integrity

`runs/` and `benchmark/cells/` hold a subset of each run's files (the prompt, report, assertion log, Git state, versions, verifier mode, tool-call count and pi's session log), copied after the runs. Before copying, the archive was scanned for the values of the three API keys in the environment, the tokens of the Codex login and the maintainer's e-mail address. One hit was found: an agent ran `git config --list` and the global `user.email` appeared in the tool output of the `race-claim-conflict` session. That address and the Windows profile name in paths (`C:\Users\<user>`, `/c/Users/<user>`) were replaced by placeholders in every file, including the compressed session logs, which remain valid JSONL. `SHA256SUMS` in this folder covers the files as archived (after that redaction), not the originals.

## Not done

- No Codex lifecycle trials (the repo's own Windows Codex batch had 6 of 8 INFRA_ERROR from the sandbox).
- No isolated verifier on this host (needs `codex sandbox setup --elevated` and a regular `python.exe`).
- No second model, no repeated trial runs beyond `blocked-sibling`, no concurrent-lane evidence.
- The fixes were not proven by controlled A/B runs. After them F1 and F5 came up in 1 and 2 of 22 T2 reports (against 1 of 6 at T0, a different mix of scenarios), F4 stayed in its narrower form (above) and F2 came up in 7 reports (open question). Only `blocked-sibling` (M1) was rerun on purpose.
