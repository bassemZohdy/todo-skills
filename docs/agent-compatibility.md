# Agent compatibility

What has been checked on each agent, and what has not. Nothing here claims support that was not observed.

| Check | Claude Code | Codex |
|---|---|---|
| Plugin installs from GitHub (`bassemZohdy/todo-skills`) | Yes: `claude plugin marketplace add`, `claude plugin install todo-skills@todo-skills` (2026-11-07) | Yes: `codex plugin marketplace add`, `codex plugin add todo-skills@todo-skills`, codex-cli 0.167.0 (2026-11-07) |
| All nine skills discovered | Yes (`claude plugin validate` passes with warnings) | Yes, nine `SKILL.md` files installed |
| `argument-hint` and frontmatter parse with a strict YAML loader | Yes (`tests/run.sh`) | Yes |
| Task lifecycle (plan, build, verify, merge) run by the agent | Yes, by fresh `claude -p` processes (2026-11-07, 17 scenarios, 38 runs, `docs/evals/claude-code-2026-11-07/summary.md`): 13 of 17 scenarios passed on the first run; the failures were harness problems, since fixed or filed. `ci-local` is an INFRA_ERROR because headless Claude Code may not write `.git/hooks`. Verified on Windows 11 with Git Bash only | Eight Linux container scenarios passed in fresh `codex exec` sessions, with the multi-module lanes sequential. An existing-project trial completed after a backlog-commit workaround. Results are provisional pending a full isolation audit: `docs/evals/codex-linux-2026-11-08/summary.md`. In the earlier Windows sandbox batch, six scenarios were infrastructure errors: `docs/evals/codex-2026-11-07/summary.md`. |
| Stop hook (`todo-stop-hook.sh`) | Designed for Claude Code hooks | Not applicable: Codex has no equivalent wired up here |
| Slash commands (`/todo-continue`, ...) | Yes, as skills | Skills in `<project>/.agents/skills` (or `.codex/skills`) are discovered; `.claude/skills` is not. `$todo-status` and plain language run a skill; a literal `/todo-status` is not handled by Codex in `codex exec` (a model may still map it). The interactive TUI was not tested (`docs/evals/codex-2026-11-07/summary.md`) |

## Unsupported or unverified

- Codex: Linux lifecycle results are provisional; the Windows sandbox still blocked six scenarios, and genuinely parallel Codex lanes have not been verified. The existing-project trial required a backlog-commit workaround.
- Other agents (Cursor, Gemini CLI and so on) can read the skills as Markdown, but nothing has been run there.
