# Files the skills use

The backlog itself is two files, `TODO.md` (the active task tree) and `CHANGELOG.md` (the archive). The skills also read the project's own instructions, write plan docs, an optional requirements matrix, a status page and check scripts, change the code of the task at hand, and keep their progress in git. This page lists every one of those files, which command reads or writes it, and how it gets committed. The rules themselves are in [`plugin/skills/todo/SKILL.md`](../plugin/skills/todo/SKILL.md) (the "Layer" table and "Backlog files").

## Layers

| Layer | Files | Role | Write policy |
|---|---|---|---|
| Requirements | `README.md`, `CONTRIBUTING.md`, `docs/*.md` | What to build, how to set up and test it, the Definition of Done | Read-mostly; see the table below for the few lines the skills write |
| Plans | `docs/plans/PROJECT.md`, `docs/plans/<ROOT-ID>-<slug>.md` | Goal, scope, lanes, decisions, revisions; long designs a task links with `Ref:` | Written by the planning commands, only on your yes |
| Active queue | `TODO.md` | One task tree. A tracker of work items, not a place for design | Edited only by the todo-* skills |
| Validation | Source code and test suites | What decides "done" | Changed only for the task at hand |
| Archive | `CHANGELOG.md` | Permanent, append-only (Keep a Changelog + Conventional Commits) | Only `## [Unreleased]` changes, by a root drain and the confirmed `/todo-release`; `/todo-init` creates the file or adds a missing `[Unreleased]` |
| Traceability (optional) | `docs/RTM.md`, else the `## RTM` section of `README.md` | Requirement → task → test links | Edited only when it already exists; never created by a skill |
| Report | `docs/status.html` | A snapshot page for people | Written only by `/todo-report` |
| Checks (optional) | `.todo/check.sh`, `.todo/todo-lint.sh`, a CI job, a `pre-push` hook | Lint + tests, run by CI, the hook and `/todo-continue` | `/todo-init --ci` on your yes; you commit them |
| Version store | git | A branch (or worktree) per task; claims on the base branch | See [GIT-FLOW.md](GIT-FLOW.md) |

## Every file

| Path | What the skills use it for | Read by | Written by |
|---|---|---|---|
| `TODO.md` | The task tree | Every command | `/todo-init` creates it (two headings) or migrates an older format on your yes; `/todo-add`, `/todo-plan`, `/todo-update`, `/todo-continue` |
| `CHANGELOG.md` | Finished roots, one entry each; IDs already used; dependencies already satisfied; the release history | Every command (the lint reads it for I5 and I7) | `/todo-init` creates it or adds `## [Unreleased]`; a root drain in `/todo-continue` adds one entry; `/todo-release` turns `[Unreleased]` into a version and updates the link lines at the end |
| `README.md` | `Tests: <command>` (the regression command), `Base: <branch>`, `Models: low=…, mid=…, high=…`, a `Definition of Done` heading, an `## RTM` section, setup and test instructions | `/todo-init`, `/todo-continue`, `/todo-plan`, `/todo-add`, `/todo-report` | `/todo-init` adds the `Tests:` line on your yes; any command adds `Base:` on your yes when you name a base other than the default; `/todo-continue` edits references a task's interface change made stale ("Documentation drift"), and the RTM section when that is where the RTM lives |
| `CONTRIBUTING.md` | A stated test command, a `Definition of Done` checklist | `/todo-init`, `/todo-continue` | Never |
| `docs/*.md` | The doc a task's `Ref:` points to, a `Definition of Done` checklist, the governing sections a task reads before coding | `/todo-init`, `/todo-plan`, `/todo-add`, `/todo-continue` | `/todo-continue`, only under "Documentation drift" (outside `docs/plans/`) |
| `docs/plans/PROJECT.md` | The project plan: Goal, Scope, Out of scope, Lanes, Decisions, Open questions, Revisions. Dropped IDs named under Revisions are never reused | `/todo-plan`, `/todo-add`, `/todo-continue` (ID numbering), `/todo-report` | `/todo-init --plan`, `/todo-plan`, `/todo-plan --revise`, `/todo-update --status drop` (a Revisions line), each on your yes |
| `docs/plans/<ROOT-ID>-<slug>.md` | A long design or plan for one root, linked with `Ref:` | Every command that reads the task's `Ref:` | `/todo-add`, when a request needs more than 6 nodes or more than 4 lines, on your yes |
| `docs/RTM.md` (or README `## RTM`) | Requirements matrix: `Req \| Requirement \| Tasks \| Verification` | `/todo-plan`, `/todo-add`, `/todo-continue`, only when it exists | Tasks cell: `/todo-plan` and `/todo-add` on your yes; Verification cell: `/todo-continue`; dropped IDs removed by `/todo-plan --revise` and `/todo-update --status drop` |
| `docs/status.html` | The interactive status page | | `/todo-report`, through `docs/status.html.tmp`, which is renamed or removed |
| `.todo/check.sh` | One entrypoint: the backlog lint and the project's tests | `/todo-init`, `/todo-continue` (last gate before a root lands) | `/todo-init --ci` on your yes |
| `.todo/todo-lint.sh` | The lint the skills and CI run instead of checking by reading | Every command, when it exists | You: copy `tools/todo-lint.sh` from this repository. The skills never download it |
| `.github/workflows/todo-check.yml` | A GitHub Actions job running the lint (or the whole check) | | `/todo-init --ci` on your yes |
| `.gitlab-ci.yml` | A `todo-check` job | `/todo-init` (test command detection) | `/todo-init --ci`, shown first and added on your yes |
| `.git/hooks/pre-push` | Local fallback: runs `.todo/check.sh` and refuses the push when it fails | | `/todo-init --ci` on your yes, when there is no CI; never overwrites an existing hook |
| `TODO.legacy.md` | A free-form `TODO.md` moved aside | | `/todo-init`, on your yes |
| `package.json`, `pom.xml`, `build.gradle(.kts)`, `Cargo.toml`, `pyproject.toml`, `pytest.ini`, `setup.cfg`, `uv.lock`, `go.mod`, `*.csproj`, `*.sln`, `Gemfile`, `Makefile`, lockfiles | Runtime, package manager and test command | `/todo-init`, `/todo-continue` (when there is no `Tests:` line), `/todo-release` lists version files that still name the previous version | Never. Version files are left for you to bump |
| `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, other CI files | The test command CI runs, so the regression command matches it; which CI job to add | `/todo-init` | Only the CI files above |
| Source and test files | The task's change | `/todo-add` (is it already done?), `/todo-continue` | `/todo-continue`, only what the task line covers |
| `plugin/skills/todo-report/template.md` | The page template (inside the skill) | `/todo-report` | Never |

The commands also read git itself: `git status`, `git log --all --format=%s` (IDs named in commit subjects are never reused), `git show <base>:TODO.md` (claims), `git worktree list` and `git tag --list`.

## Outside the working tree

| What | Where | Created by | Removed by |
|---|---|---|---|
| Task branches | `todo/<ID>-<slug>`, one per node | `/todo-continue`, `/todo-update --status in-progress` | `git branch -d` after each merge into the parent; a bare claim branch of your own is force-deleted when a rerun replaces it |
| Worktrees | `../<repo>.todo/<ID>` beside the main checkout | `/todo-continue --worktree` and `--all-lanes` | `git worktree remove` after the merge (lane worktrees stay until their root lands) |
| Commits on the base branch | Tree claims (fast-forward), claim releases, the release commit, the merge of a verified root | `/todo-continue`, `/todo-update --status ready`, `/todo-release` | Never rewritten |

No skill tags, fetches, pulls or pushes. Sharing commits with other clones is git's job and yours.

## Backlog files and when they are committed

**Backlog files** are `TODO.md`, `CHANGELOG.md`, `docs/plans/PROJECT.md`, the `docs/plans/<ROOT-ID>-*.md` a `Ref:` names, and the README `Tests:` and `Base:` lines a skill wrote.

- `/todo-init`, `/todo-plan` and `/todo-add` leave their edits **uncommitted**. The next commit a skill makes on a `todo/` branch, usually the tree claim, stages them by explicit path. So a root you have just added is claimable without a separate commit.
- The clean-tree check ignores backlog files, untracked files and generated files (`__pycache__`, `*.pyc`, `dist/`, `build/`, `target/`, `node_modules/`, `*.log`). Any other change stops a command until you commit, stash or use `--worktree`.
- README is staged by a backlog commit only while `git diff README.md` adds exactly the `Tests:`/`Base:` lines. README edits made under "Documentation drift" belong to the task and are committed with it. Any other README change is yours and is never staged by a skill.
- New roots, and any change to a tree nobody has claimed, are made on the base branch. On a `todo/` branch the skills refuse them and name the base.
- An RTM edit made while completing a task is a task file, committed with the node, not a backlog file.
- `.todo/`, the CI file and the hook are project files: you commit them (on the base or through a pull request). No claim commit carries them.
- `docs/status.html` is a snapshot. Commit it only if your team wants it versioned.

## What each command touches

| Command | Reads | Writes | Commits |
|---|---|---|---|
| `/todo` | `TODO.md`, `CHANGELOG.md`, `.todo/todo-lint.sh` | Nothing | None |
| `/todo-init [--plan] [--ci]` | README, CONTRIBUTING, `docs/`, `TODO.md`, `CHANGELOG.md`, marker files, CI config, `.todo/` | Missing `TODO.md` / `CHANGELOG.md` / `[Unreleased]`; a migration or `TODO.legacy.md` on your yes; README `Tests:` / `Base:` on your yes; `docs/plans/PROJECT.md` (`--plan`); `.todo/check.sh`, a CI file or the `pre-push` hook (`--ci`) | None. With `--ci` it runs `.todo/check.sh` once to show it works |
| `/todo-plan [<goal>] [--revise]` | README, `docs/`, `TODO.md`, `CHANGELOG.md`, the plan doc, the RTM | `docs/plans/PROJECT.md`, `TODO.md`, RTM Tasks cells, after your confirmation | None |
| `/todo-add` | `TODO.md`, `CHANGELOG.md`, the `Ref:` doc, code and tests (to check the work is not already done), the RTM | `TODO.md`; `docs/plans/<ROOT-ID>-<slug>.md` and RTM rows on your yes | None |
| `/todo-continue` | Everything above that the node needs | The node's code and tests, `TODO.md`, `CHANGELOG.md` (drain), README/`docs/` (drift), RTM Verification | Claim, start, plan, node, merges into the parent, block, decompose, drain; the merge into the base only with `--merge` |
| `/todo-update` | `TODO.md`, `CHANGELOG.md`, the plan doc | `TODO.md`; a Revisions line in the plan doc and RTM Tasks on a drop | On a `todo/` branch: ready, block, drop, revert. Anywhere: a claim release on the base. `--status in-progress`: the claim and start commits |
| `/todo-status` | `TODO.md`, `CHANGELOG.md`, git | Nothing | None |
| `/todo-report` | `TODO.md`, `CHANGELOG.md`, `docs/plans/PROJECT.md`, git, the template | `docs/status.html` only | None |
| `/todo-release` | `CHANGELOG.md`, `TODO.md`, git tags, version files (listed, not edited) | `CHANGELOG.md` | `chore(release): X.Y.Z`, `CHANGELOG.md` only |

## Never touched

- Released `CHANGELOG.md` sections.
- Version files such as `package.json` or `pyproject.toml`: `/todo-release` only lists them.
- README text other than the lines above, unless a task's own interface change made it stale.
- Your uncommitted changes: a command stops and asks instead of committing or reverting them.
- Claude or Codex settings and permissions, credentials, `~/.ssh`, `~/.aws` and environment tokens.
- The network, tags and remotes.
