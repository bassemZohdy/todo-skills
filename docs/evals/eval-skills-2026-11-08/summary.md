# Existing-project trial without the FIX-035 workaround, 2026-11-08 (TASK-043)

> Only this summary is published. The evidence of these runs (prompts, session logs, Git state, checksums) stays with the maintainer; paths below that point into it no longer exist in the repository.

The [2026-11-08 Linux batch](../codex-linux-2026-11-08/summary.md#representative-existing-project-trial) completed a feature
in a scratch clone of `bassemZohdy/eval-skills` only after the controller told the agent to commit the backlog between
`/todo-add` and `/todo-continue`. [FIX-035](../fix-035.md) made the first tree claim carry an uncommitted new root. This
run repeats the same feature on the same project with the fixed skills and **no commit of any kind between the sessions**.

**Result: PASS on the first attempt, no workaround.** Trust stays provisional, for the same sandbox reasons as the earlier batch.

## Setup

- Project: `bassemZohdy/eval-skills` at `1d4040b6584c94ae7143534911835f5b9053d3de` (the commit used before), cloned into a
  scratch repository with `core.autocrlf=false` and no remote. The original checkout was not modified.
- Skills: the nine folders of `plugin/skills` from todo-skills `15892fdf5c255f9a7086f3bdb049a7c11bf8beb8`, with LF line endings,
  installed under `.agents/skills` in one controller commit (`36aa2f655cec2d1469a90e8ccf914da8256f3b77`, `setup-sha.txt`).
- Agent: three fresh `codex exec --ephemeral` processes (Codex CLI 0.167.0, `gpt-6.1-terra`) in the `todo-codex-linux:0.167.0`
  container, one per step. Each runner (`<step>/runner.sh`) denies the login, prompt and runner paths to agent commands, allows
  writes only to `/work`, and disables networking for agent commands. The controller script is `step.sh`.

## Sessions

| Step | Session | Prompt | Git after the session |
|---|---|---|---|
| `init` | `01a1ba0c-86b8-7272-b664-1481d581dd60` | the same as before | no commit; `TODO.md` replaced, `CHANGELOG.md` and `TODO.legacy.md` new |
| `add` | `01a1ba0d-4e51-7700-ae0a-2eaae83ab60d` | the earlier request without its "first commit" sentence | no commit; FEAT-001 only in the working tree |
| `continue` | `01a1ba0d-f706-7710-b3e3-468e0b9cae3b` | the same as before | claim, start, feature, drain and `Merge FEAT-001 into main` |

No prompt mentions a commit. `git-state.txt` in each step folder records `HEAD` before and after the session: init and add
leave `main` at the setup commit, and continue starts from it. Its first commit, `chore(backlog): claim FEAT-001 on
todo/FEAT-001-add-list-option-scripts`, carries the uncommitted backlog edits, as FIX-035 intended.

## Independent checks (controller, network-disabled containers)

- `independent-check.py` (unchanged from the earlier run, repository mounted read-only): two `--list` calls give the same
  14 unique expected paths, neither `--list` nor `--check` writes a target, and `--check` still prints `in sync`.
- Regression: 244 tests with 4 skips before (`baseline.*`), 245 tests with the same 4 skips after (`final-regression.*`), exit 0.
- `independent-git-state.txt`: the original `TODO.md` and `TODO.legacy.md` have the same blob (`300227f6…`); outside `.agents`
  the change adds `CHANGELOG.md` and `tests/test_sync_list.py` and modifies `README.md`, `TODO.md` and `scripts/sync_shared.py`.
  No existing test changed. The full patch is `feature.diff`.

The agent reported one ambiguity, the same as before: the request does not say what `--list --check` does, and it gave
`--list` precedence. It also left `TODO.legacy.md` untracked, which the clean-tree rule allows.

## Verify

When the evidence was published, a test checked its checksums, the session ids, exit codes and runners, that no prompt asks
for a commit, the before and after heads of each step, the claim, drain and merge, and the independent results. The
evidence is not published, so these results cannot be re-verified from this repository; the test was removed with it
(TASK-121).
