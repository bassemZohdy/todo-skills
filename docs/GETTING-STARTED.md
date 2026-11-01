# Getting started

A ten-minute walkthrough on a scratch project. You need an agent that loads skills (Claude Code is the one that has been tested), git, and a project with a test command.

## 1. Install

```bash
git clone https://github.com/bassemZohdy/todo-skills
mkdir -p ~/.claude/skills
cp -r todo-skills/skills/* ~/.claude/skills/
```

Or, in Claude Code: `/plugin marketplace add bassemZohdy/todo-skills`, then `/plugin install todo-skills@todo-skills` (commands are then namespaced, for example `/todo-skills:todo-add`). Copy all nine folders; the command skills load the `todo` core skill and its `reference/` files.

## 2. Set up the backlog

```text
/todo-init
```

Creates `TODO.md` and `CHANGELOG.md` if missing, detects git, the base branch and your test command, and reports. It never creates your README or docs, and changes nothing else without asking. It offers to add a `Tests: <command>` line to your README so every later run uses the same command; if it reports the command as unknown, add that line yourself.

## 3. Add a task

```text
/todo-add Reject expired JWTs in the auth middleware --priority P0
```

The skill may ask up to three short questions. It then writes a 2 to 4 line task with an exact test command (and breaks a large request into a tree, asking you to confirm it):

```markdown
- [ ] **FIX-001** · P0 · S · Reject expired JWTs in the auth middleware
  - Done when: an expired token gets 401; `npm test -- auth/expired`
```

For a bigger goal use `/todo-plan "<goal>"` instead: it writes a short plan doc, proposes a tree split into lanes, and waits for your confirmation. If the plan turns out wrong later, `/todo-plan --revise "<what is wrong>"` changes the open tasks and keeps the IDs.

## 4. Run a task

```text
/todo-continue
```

Per task, the agent: checks the tree is clean and the test suite is green (the baseline), creates the branch `todo/FIX-001-reject-expired-jwts`, marks the task `[/]`, writes the failing test first, implements, **reviews its own diff**, runs `Done when` and the full regression, commits, drains the task into `CHANGELOG.md` under `[Unreleased]`, and refreshes from the base branch. A root task is merged into `main` only if you add `--merge`; otherwise it prints the two commands and stops. Run `/clear` and `/todo-continue` again for the next one.

If a test fails it makes at most three diagnosed attempts, then marks the task `[!]` with the failing command, the error and what you need to do. Unblock it with `/todo-update FIX-001 --status ready`.

## 5. Look around

```text
/todo-status      # tree, active task, blockers, recent history (read-only)
/todo-report      # writes docs/status.html: an interactive page, open it in a browser
```

## 6. Release

```text
/todo-release
```

Proposes a semantic version from the `[Unreleased]` entries, asks you to confirm, and writes the dated section. It prints the `git tag` and `git push` commands and does not run them.

## Working in parallel

Give roots a lane (`Links: Lane: api`) and run `/todo-continue --all-lanes --merge`. One subagent per lane works in its own worktree; the main thread merges the finished roots one at a time. See [REFERENCE.md](REFERENCE.md#lanes-and-parallel-work).

## When something looks wrong

- `bash ~/.claude/skills/todo/scripts/todo-lint.sh` from the repository root checks the backlog rules and tells you the line.
- A session that died mid-task is recovered by the next `/todo-continue`: it finishes an unmerged `[x]` branch or resumes the `[/]` one first.
- Not in a git repository? Everything still works, without branches or commits, after a one-time warning.

## Try it safely

Run it first in a scratch repository. The skills never touch the network, tag or push, but they do edit files and create branches, and they run the test commands written in `TODO.md`, so read a task before you let an agent run it. The scenarios in [`tests/trials/`](../tests/trials/README.md) build small throwaway projects you can use to see each behaviour, and `bash tests/run.sh` runs the lint and hook tests.
