#!/usr/bin/env bash
# Runs ONE fresh Codex process on a scratch repository with writes confined to it. Used by run-codex.sh and test-codex-isolation.sh.
# Usage: bash tests/trials/codex-exec.sh <repo> <prompt-file> <report-file>
#   writes the agent's last message to <report-file>; the full session log goes to stdout and stderr; exits with codex's status
#   (124 after 1500 s). Needs the codex CLI, logged in (`codex login status`).
# Isolation, as verified on codex-cli 0.167.0 (Windows 11, unelevated sandbox):
#   -s workspace-write          writes only inside the repo, plus the extra roots below
#   exclude_tmpdir_env_var/exclude_slash_tmp=true
#                               by default the sandbox also makes $TMPDIR and /tmp writable; a scratch project or a controller
#                               kept under the temp folder would then be writable too, so both are switched off
#   --add-dir <repo>.todo       extra writable folder: the skills create lane worktrees at ../<repo>.todo/ (only if it exists)
#   NOT added: <repo>/.git as a writable root. Without it Git can commit (and usually branch) but cannot create worktrees, so the
#   lane scenarios end as INFRA_ERROR under Codex. Adding .git as a root made the sandbox allow writes ANYWHERE (observed: a
#   sibling folder and a "controller" file were overwritten), and moving the Git directory out (git init --separate-git-dir)
#   makes `git worktree list` show the git dir as the "main checkout", on which the skills then stopped (4 of 8 scenarios).
#   A container folder as workdir (repo/ and repo.todo/ inside it, --skip-git-repo-check) also allowed writes outside it.
#   Keep the scratch repo, controller and evidence OUT of the Windows temp folder: after earlier sandbox runs the whole temp
#   tree became writable to the sandbox, and writes outside the workspace stopped being denied (observed twice).
#   -C <native path>            on Windows the repo path must be the native form (C:\...), not C:/...; with a forward-slash
#                               path the sandbox treated .git as protected and Git refused to lock refs
#   stdin is closed             otherwise `codex exec` waits for input and never starts
# Not isolated: READS. Codex's unelevated Windows sandbox "cannot enforce split filesystem read restrictions", so the agent can
# read the controller and the evidence. Only writes are denied; evidence integrity rests on that plus SHA256SUMS.
# The user's Codex config is kept on purpose (--ignore-user-config removes the rules that allow ordinary git commands).
set -u
repo="${1:?usage: codex-exec.sh <repo> <prompt-file> <report-file>}"; pf="${2:?prompt file}"; out="${3:?report file}"
nat() { if command -v cygpath >/dev/null 2>&1; then cygpath -w "$1"; else printf '%s\n' "$1"; fi; }
repo="$(cd "$repo" && pwd)"
if [ "${TRIAL_LINUX_ISOLATION:-0}" = 1 ]; then
  # This profile is for a Linux container with controller at /controller and
  # all trial data under /runs. Audit its boundaries before trusting results.
  case "$repo" in /runs/*) ;; *) echo 'Linux profile requires a repository under /runs' >&2; exit 2 ;; esac
# shellcheck disable=SC1003
  case "$repo" in *'"'*|*'\'*) echo 'unsupported character in repo path' >&2; exit 2 ;; esac
  args=(exec --ephemeral --ignore-user-config -m "${TRIAL_CODEX_MODEL:-gpt-6.1-terra}"
    -c 'default_permissions="trial"'
    -c "permissions.trial.filesystem={\":root\"=\"read\", \"/root/.codex\"=\"deny\", \"/controller\"=\"deny\", \"/runs\"=\"deny\", \"$repo\"=\"write\", \"$repo/.git\"=\"write\"}"
    -c 'permissions.trial.network.enabled=false' -C "$repo" -o "$out")
else
  args=(exec --ephemeral -s workspace-write
    -c sandbox_workspace_write.exclude_tmpdir_env_var=true -c sandbox_workspace_write.exclude_slash_tmp=true
    -C "$(nat "$repo")" -o "$out")
  [ -d "$repo.todo" ] && args+=(--add-dir "$(nat "$repo.todo")")
fi
tmo=(); command -v timeout >/dev/null 2>&1 && tmo=(timeout 1500)
${tmo[@]+"${tmo[@]}"} codex "${args[@]}" "$(cat "$pf")" < /dev/null
