# todo-skills (plugin)

A lean, file-native backlog for coding agents. Nine skills (`/todo-init`, `/todo-plan`, `/todo-add`, `/todo-continue`, `/todo-update`, `/todo-status`, `/todo-report`, `/todo-release`, and the `todo` core rules) keep a task tree in `TODO.md`, work each task on its own git branch, require tests plus a regression run before anything merges, and archive finished work in an append-only `CHANGELOG.md`.

This folder is Markdown and JSON only. It sends no data, has no network access, MCP server or hook, and never reads credentials. The skills run local `git` and your project's own test commands, and write the backlog, docs and task files. Optional helper scripts are developer tools in the `tools/` folder of the repository and are not part of the plugin.

Full documentation, the command reference, the security notes and the tests are in the repository: https://github.com/bassemZohdy/todo-skills. Licensed under MIT (see the repository `LICENSE`).
