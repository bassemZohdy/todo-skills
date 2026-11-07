# Distribution

| Channel | Status | How |
|---|---|---|
| Claude Code plugin marketplace (this repo) | Available | `/plugin marketplace add bassemZohdy/todo-skills` |
| Codex plugin marketplace (this repo) | Available, verified on codex-cli 0.167.0 | `codex plugin marketplace add bassemZohdy/todo-skills` |
| skills CLI | Available | `npx skills add bassemZohdy/todo-skills` |
| Anthropic plugin directory | Submitted 2026-11-07, under review (0.3.0) | Owner action at claude.ai/directory/manage (login and terms) |

Keep `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` on the same version as the newest CHANGELOG release; `tests/run.sh` checks it. Codex caches an install by that version, so bump it on every release.

## Anthropic directory submission

Submitted: 2026-11-07 · Reference: https://claude.ai/directory/manage/plugins/1aa64a1d-da6d-4226-bcaa-a5d444c86cd9

Validation of `main @ 29817a3` passed with 4 warnings and 6 policy holds. Handled since: listing icon added (a square PNG in the `.claude-plugin` folder), the `todo-release` wording that could read as a skill command line, and a disclosure of what the plugin runs, reads, writes and sends (README, SECURITY.md). Left for the reviewer: the credential-read hold (the safety rules name credential paths only to refuse them) and the name-resemblance hold. Validation of `main @ 318e230` passed with 3 warnings and 12 policy holds, all reviewer-confirmable: five name look-alikes (Nodo, Qodo, Todo4, qodo-skills, Topo), the credential-read hold (the lint regexes and the safety rules name forbidden commands such as `eval`, `sh -c` and credential paths in text only; nothing reads the environment or sends data), the download-and-execute pattern (the same rules text and the test helper `tests/trials/assert.sh`), and the unread-asset hold for the icon. This repository's own `.todo/check.sh` lost its `#!` line (it is run with `bash`). Re-validate before submitting; the report covers only the commit it read.

### Checklist (owner action)

Prepared from the repository; the portal's own fields may differ, so check them as you fill the form.

- [ ] Sign in at claude.ai/directory/manage and accept the directory terms.
- [ ] Plugin: `todo-skills`, manifest `.claude-plugin/plugin.json`, license MIT, author Bassem Zohdy, homepage https://github.com/bassemZohdy/todo-skills.
- [ ] Version: the newest release in CHANGELOG.md (0.2.0 today). `[Unreleased]` holds unreleased work, so run `/todo-release` first if the submission should include it, then keep both manifests on that version.
- [ ] `bash tests/run.sh` passes on the commit you submit.
- [ ] Short description: "A lean, file-native backlog for coding agents: a task tree in TODO.md, a branch per task, tests plus regression before anything merges, and an append-only CHANGELOG.md."
- [ ] Install check from a clean client: `/plugin marketplace add bassemZohdy/todo-skills`, then confirm the nine skills (todo, todo-add, todo-continue, todo-init, todo-plan, todo-release, todo-report, todo-status, todo-update) are listed.
- [ ] Security notes for the reviewer: no network access by the skills, no required tooling beyond git/bash, see SECURITY.md.
- [ ] After submitting, record below: `Submitted: <YYYY-MM-DD> · Reference: <id or URL from the portal>`, and set the table row above to "Submitted".
