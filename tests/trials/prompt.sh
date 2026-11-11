#!/usr/bin/env bash
# Prints the exact prompt for a fresh trial agent, so every run of a scenario is given the same words.
# Usage: bash tests/trials/prompt.sh <dir> <scenario>
set -eu
dir="${1:?usage: prompt.sh <dir> <scenario>}"; scenario="${2:?scenario}"
case "$scenario" in
  interrupted-merge)  task='Run `/todo-continue`. Stop after one invocation.' ;;
  refresh-from-base)  task='Run `/todo-continue` (no `--merge`). Stop after one invocation.' ;;
  ts-baseline-red|java-baseline-red|ts-interrupted|java-interrupted) task='Run `/todo-continue`. Stop after one invocation.' ;;
  team-claim)         task='A teammate pushed to `origin` since you last pulled, and you have one local commit that is not pushed. Run `git pull --no-rebase`: it conflicts in TODO.md. Resolve the conflict by the skills'"'"' conflict rules, finish the merge with `git commit --no-edit`, and lint. Then run `/todo-continue`; stop right after the start commit (`chore(backlog): start <ID>`). Never push.' ;;
  claimed-elsewhere)  task='Run `/todo-continue`; stop right after the start commit (`chore(backlog): start <ID>`). Do not build.' ;;
  race-claim-*)       task='Run `/todo-continue`; stop right after the start commit (`chore(backlog): start <ID>`), or earlier if the skill says to stop. Do not build. Do not modify or remove git hooks.' ;;
  release-ask)        task='Run `/todo-release`. When the skill tells you to ask the user something, STOP there and end your turn with the question.' ;;
  release)            task='Run `/todo-release`. The user has already answered your version question with: "0.2.0, confirmed".' ;;
  monorepo)           task='Run, in order, `/todo-init`, then `/todo-add "add a power function to the api package"`, then `/todo-continue --merge`. Accept every proposal and confirm every confirmation.' ;;
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
  ts-lifecycle|java-lifecycle)
    if [ "${TRIAL_ONE_INVOCATION:-0}" = 1 ]; then
      task='Run `/todo-continue --merge` for exactly one invocation, then stop and report. The controller will run it again in a fresh session until the root is merged.'
    else
      task='Run `/todo-continue --merge`. It executes one node per invocation, so run it again after each report until the skill says nothing is left to continue and the root is merged into main.'
    fi ;;
  lanes|multi-module)
    # TRIAL_LANE_PHASE is set only by run-codex-lanes.sh, where the controller is the coordinator's subagent tool.
    case "${TRIAL_LANE_PHASE:-}" in
      coordinate) task='Run `/todo-continue --all-lanes --merge` as the coordinator. You have a subagent tool: the trial controller, which starts one fresh agent per lane, all at once. At step 3 of .claude/skills/todo/reference/lanes.md do no lane work yourself. Instead write each lane subagent'"'"'s complete instructions (everything step 3 says it gets, its rules included) to ../<repo>.todo/<ROOT-ID>.brief.md, one file per lane, where <ROOT-ID> is the root of that lane and ../<repo>.todo/<ROOT-ID> its worktree. Then stop and report. After the lane agents return, a fresh coordinator session runs steps 4 and 5. Do not modify or remove git hooks.' ;;
      worker) task='You are the lane subagent for one root, started by the coordinator of `/todo-continue --all-lanes --merge` (step 3 of .claude/skills/todo/reference/lanes.md). Your working folder is this lane'"'"'s worktree. Follow the coordinator'"'"'s instructions below, then stop and return your summary. Do not modify or remove git hooks.' ;;
      *) task='Run `/todo-continue --all-lanes --merge`. If you have no subagent tool, follow what the skill says for that case. Do not modify or remove git hooks.' ;;
    esac ;;
  *) echo "unknown scenario: $scenario" >&2; exit 1 ;;
esac
cat <<EOF
You are a trial agent testing a set of agent skills. Your ONLY working folder is $dir (cd there with an absolute path in every shell call). Do not read or write outside it, except the worktrees the skills create at ../<repo>.todo/.

The skills are in .claude/skills/<name>/SKILL.md inside that folder (core rules: .claude/skills/todo/SKILL.md and .claude/skills/todo/reference/*.md). Slash commands are not available: to run /todo-x, read .claude/skills/todo-x/SKILL.md and follow it literally, loading what it tells you to load. Never push or fetch, never use git add -A or git add ., never tag. If git needs an identity, use git -c user.email=t@t -c user.name=t.

Task: $task

Reply with (1) the report the skill asks for, and (2) every ambiguity, contradiction or unclear instruction you hit in the skill text, each with the exact quoted text and how you resolved it ("none" if none).
EOF
