# Security

## What the skills can do

The plugin (`plugin/`) is Markdown instructions only, plus one HTML page template embedded in a Markdown file. Optional read-only shell scripts (the lint, the Stop hook, `todo-verify.sh`, `todo-rtm.sh`, `todo-report.sh`) live in `tools/` of the repository and are not part of the plugin. They never touch the network, tag, push or run destructive commands.

An agent following the skills still runs the `Done when` and test commands found in a repository, so review `TODO.md` the way you review code: a task from an untrusted source can name any command. The skills limit `Done when` to test, lint, typecheck and build commands, read a script before running it, and refuse commands that delete files, use `sudo`, run downloaded code, push, publish, deploy, leave the repository or read credentials ([docs/VERIFICATION.md](docs/VERIFICATION.md#command-safety)). The lint rejects an obvious set (`sudo`, `rm -r`, `git push`, download-to-shell and similar). These are safety nets, not a sandbox.

The trial harness in `tests/trials/` is a developer tool, not part of the plugin. `run-claude.sh` and `run-codex.sh` start a real agent with file edits accepted and shell access, so run them only in a throwaway environment. Codex's sandbox on Windows confines writes but cannot deny reads (`docs/evals/codex-2026-11-07/summary.md`), and the Linux isolation is only partly audited (`docs/evals/linux-boundary-2026-11-08.md`): reads of the login, evaluator and evidence were denied in the probes, but the profile allows general OS reads, and without the opt-in Linux profile (`TRIAL_LINUX_ISOLATION=1`) project tests run with the controller's permissions.

## What it runs, reads, writes and sends

- **Runs locally:** `git` (branch, commit, merge, worktree; never fetch, pull, push, tag, reset hard or clean), your project's own test, lint and build commands from `Done when`, the README `Tests:` line and `.todo/check.sh`, and any of the `tools/` scripts you chose to copy into your project. Nothing is installed or downloaded by the plugin.
- **Reads:** `TODO.md`, `CHANGELOG.md`, `README.md`, `CONTRIBUTING.md`, `docs/` (including `docs/plans/` and an optional `docs/RTM.md`), `.todo/`, project marker files and CI configuration (to detect the test command), and the source the current task needs. It never reads credentials, environment tokens, `~/.ssh` or `~/.aws`; the lint and the safety rules name those paths only to refuse commands that touch them.
- **Writes:**
  - always: `TODO.md` and the `[Unreleased]` section of `CHANGELOG.md`;
  - for the task at hand: its source and test files, README or `docs/` references the task's interface change made stale, and the Verification cell of an existing RTM;
  - only after you say yes: the README `Tests:` and `Base:` lines, `docs/plans/PROJECT.md` and `docs/plans/<ROOT-ID>-*.md`, RTM task links, `TODO.legacy.md`, `.todo/check.sh`, `.github/workflows/todo-check.yml`, a job in `.gitlab-ci.yml`, and a git `pre-push` hook;
  - on `/todo-report`: `docs/status.html`, which renders text from `TODO.md`, `CHANGELOG.md` and the plan doc with `textContent` only and loads nothing from the network;
  - in git: `todo/*` branches, commits, and worktrees beside the repository in `../<repo>.todo/`.

  It changes no Claude or Codex settings or permissions and never edits version files. The full list is in [docs/FILES.md](docs/FILES.md).
- **Sends:** nothing. There is no network access, telemetry, MCP server or hook shipped in the plugin.

`/todo-init --ci` writes `.todo/check.sh`, which runs your test command in CI and in the `pre-push` hook, and `/todo-continue` runs it before a task lands. Review changes to it like any CI script.

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's private vulnerability reporting on this repository ("Security" tab, "Report a vulnerability"). Include what you ran, what happened, and the skill text or script involved. You can expect an acknowledgement within a week.
