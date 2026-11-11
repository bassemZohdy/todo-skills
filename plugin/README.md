# todo-skills (plugin)

A lean, file-native backlog for coding agents. Nine skills (`/todo-init`, `/todo-plan`, `/todo-add`, `/todo-continue`, `/todo-update`, `/todo-status`, `/todo-report`, `/todo-release`, and the `todo` core rules) keep a task tree in `TODO.md`, work each task on its own git branch, require tests plus a regression run before anything merges, and archive finished work in an append-only `CHANGELOG.md`.

Install in Claude Code with `/plugin marketplace add bassemZohdy/todo-skills`, then `/plugin install todo-skills@todo-skills`; in Codex with `codex plugin marketplace add bassemZohdy/todo-skills`, then `codex plugin add todo-skills@todo-skills`.

Besides those two files, the skills read the project's README, CONTRIBUTING and `docs/` (test command, base branch, Definition of Done, the docs a task links), and, when you agree, write plan docs in `docs/plans/`, the README `Tests:` line, an optional requirements matrix, `docs/status.html`, and a check script with a CI job or pre-push hook under `.todo/`. Code changes stay within the task at hand.

This folder is Markdown and JSON only. It sends no data, has no network access, MCP server or hook, and never reads credentials. The skills run local `git` and your project's own test commands. Optional helper scripts are developer tools in the `tools/` folder of the repository and are not part of the plugin. The same skills install into Claude Code (`plugin/.claude-plugin`) and Codex (`plugin/.codex-plugin`); what has been observed on each is in `docs/agent-compatibility.md` in the repository.

Full documentation, the command reference, the file map, the security notes and the tests are in the repository: https://github.com/bassemZohdy/todo-skills. Licensed under MIT (see the repository `LICENSE`).
