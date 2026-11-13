# Claude Code on the revised skill text (2026-11-13)

TASK-112 asked for the trial scenarios to be rerun on the revised skill text with Claude Code and Codex, because only pi with GLM 5.3 had run them after FIX-098 to FIX-103. This is the Claude Code half; the Codex half is TASK-116 (see "Codex").

## What ran

- **Text:** `main` at `94a035e` (after FIX-115), run from a frozen worktree. All 34 scenarios of `tests/trials/setup.sh`, including `leftover-work`, `dirty-tree`, `plan-stop`, `decompose` and `regress-block`.
- **Agent:** Claude Code 2.1.323, `claude -p` through `tests/trials/run-claude.sh` with the CLI's built-in default model (`--setting-sources project,local` leaves out the user settings, so no model is configured, and the exact model id was not recorded), `--permission-mode acceptEdits`, `--setting-sources project,local --strict-mcp-config` (no user plugins or MCP servers in the agent), three scenarios at a time. Windows 11 with Git Bash, assertions unisolated (`TRIAL_WINDOWS_ISOLATION=0`).
- **One run per scenario**, plus one rerun of each scenario that failed.

## Results

| Scenarios | Result |
|---|---|
| 32 of 34 | PASS on the first run |
| `happy-path` | FAIL, then PASS on the rerun |
| `ci-local` | FAIL twice, 12 of 13 assertions; the same one both times |

**`happy-path` (first run).** The agent edited `TODO.md` with a Python script on Windows, which wrote CRLF line endings; it noticed after the merge and added `chore(backlog): restore LF line endings` on `main`. The assertions rightly failed: the base takes only claims and merges (guardrail 6). The skills already say to keep a file's line endings; the agent got it wrong once and the rerun, with no change to the text, passed. One occurrence in two runs.

**`ci-local`.** Claude Code's headless mode refuses a write under `.git/hooks` as a sensitive file; the agent did what `reference/ci.md` says for that case and printed the two hook lines, so the only failing assertion is "pre-push hook runs check.sh". This is the INFRA limit that the 2026-11-07 batch already recorded ([summary](../claude-code-2026-11-07/summary.md)), not a defect of the text; `run-claude.sh` still scores it FAIL, as that batch's follow-up noted.

The lane scenarios `lanes` and `multi-module` passed, but both assertion logs say `lane execution: unverified`: separate worktrees were used and no worker-activity records exist, so these runs do not show that lanes ran concurrently (TASK-087 stays open on that point). The three new scenarios passed on the first run. On `decompose` the agent read `reference/plan-step.md`. The reports of `plan-stop` and `regress-block` do not name a reference file, and Claude Code's final text is all that is kept, so this batch cannot show which files it opened (pi's session logs can).

## What the reports say

Ambiguity sections are shorter than pi's and cover mostly the same ground: the order of the plan commit against the start commit, whether the lint and baseline of step 3 apply before a breakdown (the agent skipped them, as intended), the format of a failing test id, and whether a block commit carries the node's code (it does, as written). Nothing is a conflict between the always-loaded text and a reference file.

## Codex

A probe of `tests/trials/run-codex.sh` on `happy-path` with the host's own Codex (codex-cli 0.167.2) stopped at the baseline step: inside Codex's Windows sandbox the Windows Store `python3` shim is "Permission denied", so no test could run, and the agent reported a red baseline. That is the host, not the skills, and it fails four assertions (`CX-happy-path` in `runs.csv`). A second probe put a virtual environment with its own `python3.exe` first on `PATH`, using the default isolation: the Store Python behind a virtual environment is just as unreachable for the sandbox ("The file cannot be accessed by the system"), the outcome was INFRA_ERROR and the agent again stopped at the baseline. The 2026-11-08 batch needed a regular Python 3.13 install for this; this host has only the Store one. That second probe's evidence is not archived here; the run folder is in the maintainer's workspace. The 2026-11-08 Windows batch used an elevated sandbox and the Linux batch a container; neither was set up again here, and a container run needs Codex configured inside it. TASK-116 holds the Codex half.

## Evidence integrity

A subset of each run, as in the other batches: report (the agent's final message), assertion log and Git state. Claude Code keeps no session log, so `SESSIONS.sha256` does not exist. Before anything was copied the full archive was scanned for the values of every environment variable whose name contains KEY, TOKEN, SECRET or PASSWORD, for the Windows profile name and for mail addresses at the common providers; the profile name in paths was replaced by `<user>` (111 files) and nothing else was found. `SHA256SUMS` covers the files as archived.

## Not done

- No Linux or macOS run (TASK-087): that needs Claude Code signed in inside a container or on another host.
- No Codex run on the revised text (TASK-116).
- The benchmark was not run with Claude Code.
- One run per scenario; the reruns are the only repeats.
