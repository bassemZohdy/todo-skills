#!/usr/bin/env bash
# Prints the exact prompt for a fresh trial agent, so every run of a scenario is given the same words.
# Usage: bash tests/trials/prompt.sh <dir> <scenario>
set -eu
dir="${1:?usage: prompt.sh <dir> <scenario>}"; scenario="${2:?scenario}"
case "$scenario" in
  interrupted-merge)  task='Run `/todo-continue`. Stop after one invocation.' ;;
  refresh-from-base)  task='Run `/todo-continue` (no `--merge`). Stop after one invocation.' ;;
  claimed-elsewhere)  task='Run `/todo-continue`; stop right after the start commit (`chore(backlog): start <ID>`). Do not build.' ;;
  race-claim-*)       task='Run `/todo-continue`; stop right after the start commit (`chore(backlog): start <ID>`), or earlier if the skill says to stop. Do not build. Do not modify or remove git hooks.' ;;
  release-ask)        task='Run `/todo-release`. When the skill tells you to ask the user something, STOP there and end your turn with the question.' ;;
  release)            task='Run `/todo-release`. The user has already answered your version question with: "0.2.0, confirmed".' ;;
  monorepo)           task='Run, in order, `/todo-init`, then `/todo-add "add a power function to the api package"`, then `/todo-continue --merge`. Accept every proposal and confirm every confirmation.' ;;
  lanes)              task='Run `/todo-continue --all-lanes --merge`. If you have no subagent tool, follow what the skill says for that case.' ;;
  replan)             task='Run `/todo-plan --revise "FEAT-003 (web dashboard) is out of scope, drop it"`. The user confirms the proposed diff: "yes, apply it".' ;;
  ci-github|ci-local) task='Run `/todo-init --ci`. The user says yes to every offer and confirmation.' ;;
  happy-path)         task='Run `/todo-continue --merge`. Stop after one invocation.' ;;
  baseline-red)       task='Run `/todo-continue`. Stop after one invocation.' ;;
  no-git)             task='Run `/todo-continue`. Stop after one invocation.' ;;
  add-fix)            task='Run `/todo-add "add() crashes with a TypeError traceback when given None; it should raise ValueError(\"add needs numbers\")" --priority P0`. Do not ask questions; the description is complete.' ;;
  update-block)       task='Run `/todo-update FEAT-002 --status blocked --note "waiting for the product decision on rounding"`.' ;;
  update-drop)        task='Run `/todo-update FEAT-002 --status drop --note "duplicate of FEAT-001"`. The user confirms the drop: "yes".' ;;
  status-readonly)    task='Run `/todo-status`.' ;;
  blocked-sibling)    task='Run `/todo-continue`; stop right after the start commit (`chore(backlog): start <ID>`), or earlier if the skill says to stop. Do not build.' ;;
  report)             task='Run `/todo-report`. The user says yes if asked to create `docs/`.' ;;
  ts-lifecycle|java-lifecycle) task='Run `/todo-continue --merge`. It executes one node per invocation, so run it again after each report until the skill says nothing is left to continue and the root is merged into main.' ;;
  multi-module)       task='Run `/todo-continue --all-lanes --merge`. If you have no subagent tool, follow what the skill says for that case.' ;;
  *) echo "unknown scenario: $scenario" >&2; exit 1 ;;
esac
cat <<EOF
You are a trial agent testing a set of agent skills. Your ONLY working folder is $dir (cd there with an absolute path in every shell call). Do not read or write outside it, except the worktrees the skills create at ../<repo>.todo/.

The skills are in .claude/skills/<name>/SKILL.md inside that folder (core rules: .claude/skills/todo/SKILL.md and .claude/skills/todo/reference/*.md). Slash commands are not available: to run /todo-x, read .claude/skills/todo-x/SKILL.md and follow it literally, loading what it tells you to load. Never push or fetch, never use git add -A or git add ., never tag. If git needs an identity, use git -c user.email=t@t -c user.name=t.

Task: $task

Reply with (1) the report the skill asks for, and (2) every ambiguity, contradiction or unclear instruction you hit in the skill text, each with the exact quoted text and how you resolved it ("none" if none).
EOF
