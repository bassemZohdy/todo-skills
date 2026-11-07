# Distribution

| Channel | Status | How |
|---|---|---|
| Claude Code plugin marketplace (this repo) | Available | `/plugin marketplace add bassemZohdy/todo-skills` |
| Codex plugin marketplace (this repo) | Available, verified on codex-cli 0.167.0 | `codex plugin marketplace add bassemZohdy/todo-skills` |
| skills CLI | Available | `npx skills add bassemZohdy/todo-skills` |
| Anthropic plugin directory | Not submitted | Owner action at claude.ai/directory/manage (login and terms) |

Keep `.claude-plugin/plugin.json` and `.codex-plugin/plugin.json` on the same version as the newest CHANGELOG release; `tests/run.sh` checks it. Codex caches an install by that version, so bump it on every release.

## Anthropic directory submission

Not yet submitted. Submission date and reference go here once done.
