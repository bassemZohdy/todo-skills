# Security

## What the skills can do

The plugin (`plugin/`) is Markdown instructions only, plus one HTML page template embedded in a Markdown file. Optional read-only shell scripts (the lint, the stop hook, `todo-verify.sh`, `todo-rtm.sh`, `todo-report.sh`) live in `tools/` of the repository and are not part of the plugin. They are written to never touch the network, tag, push, or run destructive commands. An agent still runs the `Done when` and test commands found in a repository, so review `TODO.md` the way you review code: a task from an untrusted source can name any command. The lint rejects an obvious set (`sudo`, `rm -r`, `git push`, download-to-shell and similar); it is a safety net, not a sandbox.

`/todo-init --ci` writes `.todo/check.sh`, which runs your test command in CI and in the `pre-push` hook. Review changes to it like any CI script.

`/todo-report` writes `docs/status.html`, which renders text from `TODO.md` and `CHANGELOG.md` with `textContent` only and loads nothing from the network.

## What it runs, reads, writes and sends

- **Runs locally:** `git` (branch, commit, merge, never fetch, pull, push or tag), your project's own test, lint and build commands from `Done when` and the README `Tests:` line, and any of the `tools/` scripts you chose to copy into your project. Nothing is installed or downloaded by the plugin.
- **Reads:** `TODO.md`, `CHANGELOG.md`, `README.md`, `docs/` and the source the current task needs. It never reads credentials, environment tokens, `~/.ssh` or `~/.aws`; the lint and the safety rules name those paths only to refuse commands that touch them.
- **Writes:** `TODO.md`, `CHANGELOG.md`, `docs/plans/`, `docs/status.html`, an optional RTM edit, the task's own files, and on request `.todo/` and a git `pre-push` hook. It changes no Claude settings or permissions.
- **Sends:** nothing. There is no network access, telemetry, MCP server or hook shipped in the plugin.

## Reporting a vulnerability

Please do not open a public issue. Use GitHub's private vulnerability reporting on this repository ("Security" tab, "Report a vulnerability"). Include what you ran, what happened, and the skill text or script involved. You can expect an acknowledgement within a week.
