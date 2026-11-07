#!/usr/bin/env bash
# Records, with fresh Codex sessions, how Codex really finds and runs the todo-* skills, independently of the trial prompt that
# tells an agent to open .claude/skills/<name>/SKILL.md by hand. Needs the codex CLI and a login; without them it exits 2.
# Each case is one fresh `codex exec`. The verdicts come from the session log (did the agent open todo-status/SKILL.md?) and the
# file system, not from what the agent says about itself, except the skill lists, which only the agent can report.
#   A  skills in <project>/.agents/skills      -> all nine are listed
#   B  skills only in <project>/.claude/skills -> none is listed (Claude Code's folder, not Codex's)
#   C  the prompt "/todo-status"               -> changes nothing; whether the model runs the skill is only reported (INFO): codex exec has
#                                                 no slash-command handler, so "/name" is text the model may or may not map to a skill
#   D  the prompt "$todo-status"               -> the skill runs (explicit mention)
#   E  "What is the status of my backlog?"     -> reported only (INFO): whether the skill is picked from its description
# Usage: bash tests/trials/test-codex-invocation.sh    Takes a few minutes. Works under $HOME/.todo-trials and removes it at the end.
set -u
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
command -v codex >/dev/null 2>&1 || { echo "NEEDS CODEX: the codex CLI is not installed"; exit 2; }
codex login status >/dev/null 2>&1 || { echo "NEEDS CODEX: codex is not logged in"; exit 2; }
base="${TRIAL_BASE:-$HOME/.todo-trials}"; mkdir -p "$base"
tmp="$(mktemp -d "$base/todo-codex-invocation.XXXXXX")"; trap 'rm -rf "$tmp"' EXIT
pass=0; fail=0
ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

mkcase() { # mkcase <name> <skills-folder>: a status-readonly project whose committed skills sit in <skills-folder>
  bash "$here/setup.sh" "$tmp/$1/repo" status-readonly >/dev/null 2>&1 || { bad "setup $1"; return 1; }
  if [ "$2" != .claude/skills ]; then mkdir -p "$tmp/$1/repo/$(dirname "$2")"; mv "$tmp/$1/repo/.claude/skills" "$tmp/$1/repo/$2"; rmdir "$tmp/$1/repo/.claude" 2>/dev/null; fi
  git -C "$tmp/$1/repo" add -A >/dev/null 2>&1; git -C "$tmp/$1/repo" -c user.email=t@t -c user.name=t commit -q -m "skills in $2" >/dev/null 2>&1
}
runcase() { # runcase <name> <prompt>
  printf '%s\n' "$2" > "$tmp/$1/prompt.txt"
  bash "$here/codex-exec.sh" "$tmp/$1/repo" "$tmp/$1/prompt.txt" "$tmp/$1/report.txt" > "$tmp/$1/session.log" 2>&1
  echo $? > "$tmp/$1/exit.txt"
}
list_q='Without opening any files or running any commands, list the exact names of every skill whose name starts with todo that is available to you right now in this session, comma separated, or write NONE.'

mkcase A .agents/skills; mkcase B .claude/skills; mkcase C .agents/skills; mkcase D .agents/skills; mkcase E .agents/skills
runcase A "$list_q" & runcase B "$list_q" & runcase C '/todo-status' & runcase D '$todo-status' & runcase E 'What is the status of my backlog?' &
wait

opened() { grep -Eq 'todo-status[/\\]SKILL\.md' "$tmp/$1/session.log"; }
clean() { [ -z "$(git -C "$tmp/$1/repo" status --porcelain)" ]; }
for c in A B C D E; do [ "$(cat "$tmp/$c/exit.txt")" = 0 ] && [ -s "$tmp/$c/report.txt" ] || bad "case $c: codex exit $(cat "$tmp/$c/exit.txt") or no report"; done

all=yes; for n in todo todo-add todo-continue todo-init todo-plan todo-release todo-report todo-status todo-update; do grep -Eq "(^|[^a-z-])$n([^a-z-]|$)" "$tmp/A/report.txt" || all=no; done
[ "$all" = yes ] && ok "A: skills in .agents/skills are discovered (all nine names listed)" || bad "A: not all nine skills listed: $(head -c 200 "$tmp/A/report.txt")"
! grep -q 'todo-add' "$tmp/B/report.txt" && ok "B: skills only in .claude/skills are NOT discovered by Codex" || bad "B: Codex listed skills from .claude/skills: $(head -c 200 "$tmp/B/report.txt")"
clean C && ok "C: the prompt /todo-status changed nothing in the repository"  || bad "C: /todo-status changed the repository"
if opened C; then echo "INFO  C: /todo-status was read by the model as a request for the skill (SKILL.md opened): no Codex slash-command handler was observed in codex exec; the model mapped it from the skills catalog"; else echo "INFO  C: /todo-status did NOT run the skill: in codex exec it is plain text"; fi
opened D && grep -q 'FEAT-001' "$tmp/D/report.txt" && clean D && ok "D: \$todo-status ran the skill (SKILL.md read, backlog printed, nothing changed)" || bad "D: \$todo-status did not run the skill: $(head -c 200 "$tmp/D/report.txt")"
if opened E && grep -q 'FEAT-001' "$tmp/E/report.txt"; then echo "INFO  E: a plain-language request selected the todo-status skill from its description"; else echo "INFO  E: a plain-language request did NOT select the skill"; fi
echo "INFO  C reply: $(head -c 160 "$tmp/C/report.txt" | tr '\n' ' ')"

[ "$fail" -eq 0 ] || for c in A B C D; do echo "--- $c report"; head -c 400 "$tmp/$c/report.txt"; echo; done
printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
