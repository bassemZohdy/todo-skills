# Agent compatibility

What has been checked on each agent, and what has not. Nothing here claims support that was not observed.

| Check | Claude Code | Codex |
|---|---|---|
| Plugin installs from GitHub (`bassemZohdy/todo-skills`) | Yes: `claude plugin marketplace add`, `claude plugin install todo-skills@todo-skills` (2026-11-07) | Yes: `codex plugin marketplace add`, `codex plugin add todo-skills@todo-skills`, codex-cli 0.167.0 (2026-11-07) |
| All nine skills discovered | Yes (`claude plugin validate` passes with warnings) | Yes, nine `SKILL.md` files installed |
| `argument-hint` and frontmatter parse with a strict YAML loader | Yes (`tests/run.sh`) | Yes |
| Task lifecycle (plan, build, verify, merge) run by the agent | Yes, by fresh `claude -p` processes (2026-11-07, 17 scenarios, 38 runs, `docs/evals/claude-code-2026-11-07/summary.md`): 13 of 17 scenarios passed on the first run; the failures were harness problems, since fixed or filed. `ci-local` is an INFRA_ERROR because headless Claude Code may not write `.git/hooks`. Verified on Windows 11 with Git Bash only | Not run: needs a logged-in Codex and a model; no OpenAI authentication was available (2026-11-07). To run it, execute `tests/trials/setup.sh` and `assert.sh` around a Codex session and record the result in `docs/trials.md` |
| Stop hook (`todo-stop-hook.sh`) | Designed for Claude Code hooks | Not applicable: Codex has no equivalent wired up here |
| Slash commands (`/todo-continue`, ...) | Yes, as skills | Skills are discovered; whether Codex exposes them as slash commands was not checked |

## Unsupported or unverified

- Codex lifecycle behaviour is unverified. Treat Codex as install-verified only until a recorded run exists in `docs/trials.md`.
- Other agents (Cursor, Gemini CLI and so on) can read the skills as Markdown, but nothing has been run there.
