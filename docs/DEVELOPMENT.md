# Development

How this repository is laid out, what its tests check, and how it is released. For the contribution process (issues, pull requests, ground rules), see [CONTRIBUTING.md](../CONTRIBUTING.md).

## Layout

```text
plugin/                          The installable plugin: Markdown, JSON and the icon only
  .claude-plugin/plugin.json     Claude Code manifest (version) and icon.png
  .codex-plugin/plugin.json      Codex manifest (same version; "skills": "./skills/"; "interface": directory listing)
  assets/icon.png                Codex listing logo and composer icon (a copy of .claude-plugin/icon.png)
  README.md                      The plugin's own short README
  skills/
    todo/SKILL.md                Core rules: layers, task format, IDs, git mode, invariants, guardrails
    todo/reference/              Loaded on demand: git-flow.md, verification.md, lanes.md, rtm.md, ci.md, review.md, clarify.md, git-flow-edge.md, deliverables.md, doc-drift.md, failures.md, done-when.md, plan-step.md, routing.md
    todo-init/ todo-plan/ todo-add/ todo-continue/ todo-update/ todo-status/ todo-release/
    todo-report/SKILL.md         …and template.md, the status page inside a fenced block
.claude-plugin/marketplace.json  Claude Code marketplace, source ./plugin
.agents/plugins/marketplace.json Codex marketplace, path ./plugin
tools/                           Optional scripts users copy into their projects, read-only except todo-replay.sh --run (docs/TOOLS.md)
  todo-lint.sh todo-verify.sh todo-rtm.sh todo-replay.sh todo-report.sh todo-stop-hook.sh template.html
tests/
  run.sh                         Fixture, script and repository checks
  shellcheck.sh                  Static analysis of every shell script (shellcheck; .shellcheckrc lists the checks disabled on purpose)
  set-version.sh                 Sets the release version in the manifests, README and tool stamps (Releasing)
  build-codex-package.sh         Builds the OpenAI Plugins Directory archive from plugin/: --claude for the preferred Claude import, else the native Codex ZIP (docs/distribution.md)
  fixtures/                      Lint fixtures: ok-*.md pass, I<n>-*.md fail with I<n>, W<n>-*.md warn
  fixtures/changelog/, report/   A CHANGELOG for the lint fixtures; a hostile backlog for the report
  fixtures-rtm/                  RTM fixtures: docs-only, readme-only, both, neither, stale, duplicate, archived-ok
  trials/                        Agent trial harness (tests/trials/README.md)
  benchmark/                     Agent benchmark harness (tests/benchmark/README.md); its published results are in docs/evals/benchmark/results
docs/                            Documentation; docs/evals/ holds retained, checksummed trial evidence
.todo/                           This repository's own check: check.sh and a copy of tools/todo-lint.sh
.github/workflows/               test.yml (tests: Ubuntu, macOS and Windows with Git Bash), todo-check.yml (backlog lint), windows-verifier-test.yml; each has a concurrency group and a timeout per job, and every `uses:` is pinned to a commit SHA that `.github/dependabot.yml` keeps current (all checked by tests/run.sh)
.gitignore                       Generated files: docs/status.html.tmp, built ZIP archives, __pycache__
TODO.md, CHANGELOG.md            This repository's own backlog, run with the skills
```

## Packaging rules

The plugin folder is what users install and what the Anthropic directory reviews, so it is kept to Markdown, JSON and images. Scripts and HTML live outside it. `tests/run.sh` enforces:

- Only `.md`, `.json`, `.yml`, `.yaml`, `.txt` and image files (and `LICENSE`) in `plugin/`, none starting with `#!`.
- Both marketplaces point at `./plugin`.
- `plugin/README.md` has at least 40 words outside code blocks.
- Both manifests carry the same version, equal to the newest `## [X.Y.Z]` heading in `CHANGELOG.md`.
- Every skill folder has a `SKILL.md` whose `name:` matches the folder, with valid YAML frontmatter, and every command skill is listed in the core's command table and in `README.md`.
- The template embedded in `plugin/skills/todo-report/template.md` equals `tools/template.html`. Edit `tools/template.html`, then copy it into the fenced block.

## Tests

```bash
bash tests/run.sh                                          # must end with "0 failed"
bash tests/trials/selftest.sh                              # the trial harness without an agent
for t in tests/trials/test-*.sh; do bash "$t"; done        # harness checks (three of them need Docker or Codex)
```

`tests/run.sh` needs bash, awk, grep, sed and python3 (for the JSON manifest check; with PyYAML installed it also checks the frontmatter) and writes only temporary directories that it removes. A check that needs PyYAML or node and cannot run prints a `SKIP` line and is counted in the final line; when the `CI` environment variable is set, any skip fails the run (the test workflow installs PyYAML). It checks:

- every lint fixture against its name (pass, the named invariant, or the named warning, with no warning on `ok-*`);
- the lint without a `CHANGELOG.md` (exit 0) and without a `TODO.md` (exit 2);
- the Stop hook: allows a valid, resumable or blocked-verification backlog, blocks an invalid one, honors `stop_hook_active`, is silent without a `TODO.md`;
- `todo-verify.sh` in default and `--strict` mode on accepting and rejecting runs;
- `todo-rtm.sh` resolution and R1-R3 on the RTM fixtures;
- `todo-replay.sh` in a scratch repository: only new entries, list-only by default, a passing and a failing replay, and forbidden, unknown-runner and piped commands refused and never run;
- `todo-report.sh` encodes hostile text and exits 1 without a `TODO.md`;
- the packaging rules above;
- README drift (TASK-054): every version README states equals both manifests and the newest CHANGELOG heading, the `cp -r todo-skills/<path>` install source holds the nine skills, every relative link resolves, and the "Agents with recorded trials" line names Claude Code and Codex with their evidence;
- that the skill text keeps rules other tests rely on (the RTM pointers, the optional design and root reviews, `--strict`, the "Done when cannot run" rule, the documentation-drift rules, the narrowed review trigger, the leftover-work rule, and the pointers and rules of the rare branches that TASK-110 moved into reference files);
- each command's loaded bytes and words against the [load budget](#load-budget), and the `/todo-continue` row against its ceiling of 10% under the 2026-11-11 budget;
- that the agent-compatibility review line names the released version, the trial-report template names none and the release steps name the pages that state one (TASK-074);
- that SECURITY.md and the layout above name every script in `tools/` and every file in `plugin/skills/todo/reference/` (TASK-071);
- that every tag and commit a CHANGELOG link names exists in git (a clone without tags prints a `SKIP`; the links of 0.1.0 to 0.4.0 name release commits because those versions were never tagged, and the owner can add the tags later) (FIX-082);
- that shellcheck (pinned in CI as `shellcheck-py` 0.10.0.1) finds nothing in the scripts under `tools`, `.todo` and `tests`, run through `tests/shellcheck.sh` when it is installed (a `SKIP` otherwise, a failure in CI), and that a seeded unquoted variable fails it (TASK-073);
- that every script in `tools/` carries a `todo_skills_version` stamp equal to both manifests and the newest CHANGELOG heading and prints it with `--version`, and that `tests/set-version.sh` moves all of them in one step on a scratch copy and refuses a malformed version (FEAT-088);
- that the README Status section is a table with a row for Claude Code and for Codex and an existing evidence link on every row (TASK-089);
- that `.gitignore` lists the status page temp file, ZIP archives and `__pycache__` (TASK-084);
- that `plugin/README.md` has the marketplace install lines and the two manifests agree on repository, homepage, license and keywords (TASK-083);
- that the two `icon.png` copies are identical and `.todo/check.sh` starts with its shebang (TASK-080);
- that `.todo/todo-lint.sh` equals `tools/todo-lint.sh`, and that this repository's own `TODO.md` and `CHANGELOG.md` lint clean.

When you change the lint, add a fixture: `ok-<case>.md`, `I<n>-<case>.md` or `W<n>-<case>.md`.

The trial harness, its scenarios and its own checks are described in [tests/trials/README.md](../tests/trials/README.md) and [trials.md](trials.md).

## Load budget

Every command loads the core skill, its own `SKILL.md`, and the reference files its steps always read. `tests/run.sh` adds up the bytes (counted with LF line endings) and words of the files in each row below, prints them, and fails when a command is over either budget, a listed file is missing, or a `SKILL.md` is in no row. Files read only on a condition (`review.md`, `clarify.md`, `rtm.md`, `failures.md`, `plan-step.md`, `routing.md`, `git-flow-edge.md`, `deliverables.md`, `doc-drift.md`) are not counted; `lanes.md` has its own row. Words are a rough stand-in for tokens, which were not measured.

The budgets are the 2026-11-08 measurement plus about 5%, rounded up; the `/todo-continue` rows were lowered on 2026-11-11 to the measurement after TASK-090 plus about 5%. On 2026-11-13 TASK-110 moved the rare branches of `/todo-continue` (a failed verification run, the `--plan` stop, breaking a node down, model routing, an existing root branch) and the rules for writing a `Done when` into reference files, and every row was set to the new measurement plus about 5%; the `/todo-continue` row is 10% under its earlier 52900 bytes and 8600 words, which `tests/run.sh` pins (about 2% above the measurement). Raise one only with a measured reason in the commit, and prefer moving a rare branch into a `reference/` file.

| Command | Files (under `plugin/skills/`) | Byte budget | Word budget |
|---|---|---|---|
| `/todo` | `todo/SKILL.md` | 23100 | 3750 |
| `/todo-init` | `todo/SKILL.md` `todo-init/SKILL.md` | 30900 | 5000 |
| `/todo-init --ci` | `todo/SKILL.md` `todo-init/SKILL.md` `todo/reference/ci.md` `todo/reference/verification.md` | 42400 | 6800 |
| `/todo-plan` | `todo/SKILL.md` `todo-plan/SKILL.md` `todo-add/SKILL.md` `todo/reference/done-when.md` | 37700 | 6200 |
| `/todo-add` | `todo/SKILL.md` `todo-add/SKILL.md` `todo/reference/done-when.md` | 31900 | 5200 |
| `/todo-continue` | `todo/SKILL.md` `todo-continue/SKILL.md` `todo/reference/git-flow.md` `todo/reference/verification.md` | 47600 | 7700 |
| `/todo-continue --lane` | `todo/SKILL.md` `todo-continue/SKILL.md` `todo/reference/git-flow.md` `todo/reference/verification.md` `todo/reference/lanes.md` | 52600 | 8530 |
| `/todo-update` | `todo/SKILL.md` `todo-update/SKILL.md` | 32000 | 5200 |
| `/todo-status` | `todo/SKILL.md` `todo-status/SKILL.md` | 27000 | 4400 |
| `/todo-report` | `todo/SKILL.md` `todo-report/SKILL.md` `todo-report/template.md` | 39900 | 4800 |
| `/todo-release` | `todo/SKILL.md` `todo-release/SKILL.md` | 26800 | 4300 |

## CI

- **`test.yml`** (push to `main`, pull requests; Ubuntu, macOS and Windows, the last in Git Bash; 20 minutes per job, and a newer push to the same ref cancels the older run): `bash tests/run.sh`, `bash tests/trials/selftest.sh`, then every `tests/trials/test-*.sh` except `test-codex-isolation.sh` and `test-codex-invocation.sh` (they need a logged-in Codex) `test-linux-boundary.sh` (it needs Docker and the locally built `todo-codex-linux` image) and `test-windows-verifier-isolation.sh` (native Windows only, in its own workflow). The first three are run by hand.
- **`windows-verifier-test.yml`** (push to `main` and `todo/**`, pull requests; windows-2022 and windows-2025): installs Codex CLI 0.167.0, provisions the elevated sandbox on the disposable runner, and runs `test-windows-verifier-isolation.sh`, the probes of the Windows verifier that native-Windows trials use by default (FIX-041).
- **`todo-check.yml`**: the backlog lint, `bash .todo/todo-lint.sh TODO.md CHANGELOG.md`, the single-lint-job form `/todo-init --ci` writes when CI already runs the tests.
- **`.todo/check.sh`** runs the lint and `bash tests/run.sh`; `/todo-continue` runs it before a root of this repository lands.

## Working on this repository with the skills

This repository tracks its own work in `TODO.md` and `CHANGELOG.md` with the same skills. Its README carries the `Tests:` line the skills read. Add work with `/todo-add` on `main`, run it with `/todo-continue`, and let the drain write the CHANGELOG entry. A change made outside the skills still gets a line under `## [Unreleased]` ([CONTRIBUTING.md](../CONTRIBUTING.md)).

Shell scripts are LF in every checkout (`.gitattributes`: `*.sh text eol=lf`); `tests/trials/test-shell-line-endings.sh` checks that a copied tool still runs after a Windows `autocrlf` checkout. On Windows, run the scripts with Git Bash. A Python that imports a foreign `tests` package from its user site breaks the Python trial scenarios; set `PYTHONNOUSERSITE=1`.

## Releasing this repository

1. `/todo-release` on `main` proposes the version from `[Unreleased]`; confirm it, and it commits `chore(release): X.Y.Z`.
2. Run `bash tests/set-version.sh X.Y.Z`: it sets `"version"` in `plugin/.claude-plugin/plugin.json` and `plugin/.codex-plugin/plugin.json` (Codex caches an install by version), the version statements in README.md, the `todo_skills_version` stamp of each script in `tools/` and the vendored `.todo/todo-lint.sh`. Then run `bash tests/run.sh`, which fails while any of them, or the newest CHANGELOG heading, names another version.
3. Tag and push by hand: `git tag -a vX.Y.Z -m "X.Y.Z"` and `git push --follow-tags`.
4. For the Anthropic directory, follow the checklist in [distribution.md](distribution.md); its package-check record is dated and names the version it checked, so redo it when you submit.
5. Review [agent-compatibility.md](agent-compatibility.md) against the release and update its "Last reviewed … against version" line, saying what was and was not re-run; `tests/run.sh` fails while that line names an older version than the manifests (TASK-074).

## Documentation

When a change touches a command, flag, file, scenario or script, update the pages that name it:

| Change | Pages |
|---|---|
| A command or flag | `README.md` (Commands), [COMMANDS.md](COMMANDS.md), the core's command table |
| A file a skill reads or writes | [FILES.md](FILES.md), the README table "What the skills read and write", [SECURITY.md](../SECURITY.md) |
| The task or CHANGELOG format, an invariant or a warning | [REFERENCE.md](REFERENCE.md) |
| Branching, claims, commits or merges | [GIT-FLOW.md](GIT-FLOW.md), [LIFECYCLE.md](LIFECYCLE.md) |
| Verification, review, blocking, command safety | [VERIFICATION.md](VERIFICATION.md) |
| Planning or lanes | [PLANNING.md](PLANNING.md) |
| A script in `tools/` or the CI setup | [TOOLS.md](TOOLS.md) |
| A trial scenario or harness script | [tests/trials/README.md](../tests/trials/README.md), [trials.md](trials.md) |
| What has been observed on an agent | [agent-compatibility.md](agent-compatibility.md), the README Status |

Retained evidence under `docs/evals/` is checksummed and is never edited after the fact; add a new dated folder instead.
