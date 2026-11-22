# Privacy policy

Last updated 2026-11-22.

todo-skills is a set of Markdown instructions (skills) that a coding agent follows to keep a backlog in your repository. The plugin has no server, account, MCP server or hook, and its maintainer operates no service that receives your data.

## What the plugin collects

Nothing. The plugin does not collect, store, transmit or sell personal data, and it contains no analytics, telemetry or tracking. It makes no network requests of its own: the skills tell the agent to read and write files in your repository and to run local `git` and your project's own test, lint and build commands. [SECURITY.md](SECURITY.md) lists exactly what it runs, reads and writes.

## Where your data goes

- **Your repository.** The backlog lives in files you own (`TODO.md`, `CHANGELOG.md`, optional plan docs and `docs/status.html`) and in `git` branches, commits and worktrees on your machine. Commits carry the author name and email that you configured in `git`; the plugin does not read or change that setting. Anything you push or publish is your decision: the skills never fetch, push, tag or publish.
- **Your agent.** The agent that runs the skills (Claude Code, Codex, GitHub Copilot or another) sends the text it reads, including skill text and project files, to its own model provider. That processing is governed by the privacy policy and settings of that product and your account with it, not by this plugin.
- **Support requests.** If you open an issue or a private vulnerability report on the project's GitHub repository, GitHub stores it under GitHub's privacy statement and the maintainer reads it. Do not put secrets, credentials or personal data in an issue.

## Retention and your controls

The plugin keeps nothing of its own, so there is nothing to retain or delete on its side. To remove what it wrote, delete the files and `todo/*` branches in your repository, or remove the plugin with your agent's plugin command. Review `TODO.md` like code before you let an agent run its `Done when` commands.

## Children

The plugin is a developer tool and is not directed at children under 13.

## Changes and contact

Changes to this policy are made in this file and listed in [CHANGELOG.md](CHANGELOG.md). Questions go to [the issue tracker](https://github.com/bassemZohdy/todo-skills/issues); report a vulnerability as described in [SECURITY.md](SECURITY.md).
