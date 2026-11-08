# Getting started

A ten-minute walkthrough on a scratch project. You need an agent that loads skills (Claude Code and Codex have been tested; see [agent compatibility](agent-compatibility.md)), git, and a project with a test command. Each step says which files it creates or changes; the full map is in [FILES.md](FILES.md).

## 1. Install

```bash
git clone https://github.com/bassemZohdy/todo-skills
mkdir -p ~/.claude/skills
cp -r todo-skills/plugin/skills/* ~/.claude/skills/
```

Or, in Claude Code: `/plugin marketplace add bassemZohdy/todo-skills`, then `/plugin install todo-skills@todo-skills` (commands are then namespaced, for example `/todo-skills:todo-add`). Copy all nine folders: the command skills load the `todo` core skill and its `reference/` files.

Codex: `codex plugin marketplace add bassemZohdy/todo-skills`, then `codex plugin add todo-skills@todo-skills`, or copy the folders to `<project>/.agents/skills/` (Codex does not read `.claude/skills`). Start a skill with `$todo-add …` or plain language.

## 2. Set up the backlog

```text
/todo-init
```

It creates `TODO.md` and `CHANGELOG.md` if they are missing, detects git, the base branch and your test command, and prints one report. It never creates your README or `docs/`, and changes nothing else without asking. It offers to add a `Tests: <command>` line to README so every later run uses the same command; if it reports the command as unknown, add that line yourself. The new files stay uncommitted: the first task's claim commits them.

Optional:

- `/todo-init --plan` asks up to three questions about the goal and saves the answers as `docs/plans/PROJECT.md`.
- `/todo-init --ci` writes `.todo/check.sh` (lint + tests) and a CI job that runs it, or, without CI, a `pre-push` hook. Copy [`tools/todo-lint.sh`](../tools/todo-lint.sh) to `.todo/todo-lint.sh` first so the check includes the lint ([TOOLS.md](TOOLS.md)). Commit `.todo/` and the CI file yourself.

## 3. Add a task

```text
/todo-add Reject expired JWTs in the auth middleware --priority P0
```

The skill may ask up to three short questions and checks the code to make sure the work is not already done. It then writes a 2 to 4 line task with an exact test command into `TODO.md`. A large request becomes a tree, which it shows you and writes only after you confirm.

```markdown
- [ ] **FIX-001** · P0 · mid · Reject expired JWTs in the auth middleware
  - Done when: an expired token gets 401; `npx jest tests/auth/expired.test.ts`
```

For a bigger goal use `/todo-plan "<goal>"`: it writes a short plan doc (`docs/plans/PROJECT.md`), proposes a tree split into lanes, and waits for your confirmation. If the plan turns out wrong later, `/todo-plan --revise "<what is wrong>"` changes the open tasks and keeps the IDs ([PLANNING.md](PLANNING.md)).

## 4. Run a task

```text
/todo-continue
```

For one node, the agent:

1. Checks the backlog rules, that the tree is clean (a root you have just added and not committed is fine), and that the test suite is green: the **baseline**.
2. Claims the tree: creates `todo/FIX-001-reject-expired-jwts-in`, commits the claim (with your pending backlog edits) and fast-forwards `main` to it, so another session sees the task as taken.
3. Marks the task `[/]` on that branch, reads the governing docs, writes the failing test first, then implements.
4. **Reviews the diff** (a fresh-context reviewer when the agent has subagents), then runs `Done when` and the full regression and compares them with the baseline.
5. Commits the change with `Refs: FIX-001`, refreshes the branch from `main`, runs `.todo/check.sh` if you have one, and **drains** the task: one entry under `## [Unreleased]` in `CHANGELOG.md`, the task removed from `TODO.md`.
6. Merges into `main` only if you add `--merge`; otherwise it prints the commands and stops.

A tree of several nodes takes one `/todo-continue` per node. Clear the context (`/clear` in Claude Code) and run it again for the next one.

If a test fails it makes at most three diagnosed attempts, then marks the task `[!]` with the failing command, the error and what you need to do. Unblock it with `/todo-update FIX-001 --status ready` ([VERIFICATION.md](VERIFICATION.md)).

## 5. Look around

```text
/todo-status      # tree, active task, next task, blockers, recent history (read-only)
/todo-report      # writes docs/status.html: an interactive page, open it in a browser
```

## 6. Release

```text
/todo-release
```

It proposes a semantic version from the `[Unreleased]` entries, asks you to confirm, writes the dated section in `CHANGELOG.md` and commits it. It lists version files such as `package.json` for you to bump, and prints the `git tag` and `git push` commands without running them.

## Working in parallel

Give roots a lane (`/todo-add "…" --lane api`, which writes `Lane: api` in `Links:`) and run `/todo-continue --all-lanes --merge`. One subagent per lane works in its own worktree beside the repository (`../<repo>.todo/<ROOT-ID>`); the main thread re-checks and merges the finished roots one at a time ([PLANNING.md](PLANNING.md#lanes)). For one task at a time without switching your checkout, use `/todo-continue --worktree`.

## When something looks wrong

- The backlog lint names the rule and the line. Copy `tools/todo-lint.sh` into your project as `.todo/todo-lint.sh` and run `bash .todo/todo-lint.sh`; every command then uses it too.
- A session that died mid-task is recovered by the next `/todo-continue`: it finishes an unmerged `[x]` branch or resumes the `[/]` one first.
- A task claimed by a branch that no longer exists is released with `/todo-update <ID> --status ready`.
- Not in a git repository? Everything still works, without branches or commits, after a one-time warning.

## Try it safely

Run it first in a scratch repository. The skills never touch the network, tag or push, but they edit files, create branches and run the test commands written in `TODO.md`, so read a task before you let an agent run it. The scenarios in [`tests/trials/`](../tests/trials/README.md) build small throwaway projects you can use to see each behavior.
