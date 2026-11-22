# Test failures, blocking, and a Done when that cannot run

Read on demand from `/todo-continue` ("Test failures"), only when a verification run fails, Green fails twice on one test, or a `Done when` cannot run, and from step 2 when it resumes a `[/]` node. Part of the `todo` core skill.

## Test failures

- Diagnose first: reproduce, read the first failing assertion, write one hypothesis in `State:` (`hyp:`), make the smallest change that tests it, rerun.
- At most **3** attempts across sessions (`State:` counter). An attempt is a failed verification run after implementing started, or a failed run that the loop guard makes one (next item); the red run of step 7 (the new test failing before the implementation) is not one. A worker that stopped without a verdict is not one ("A worker that stopped" below).
- **Loop guard.** Failed runs outside step 9 count too, once implementing started: a run of `Done when` or of any part of it, made after a change (a rerun that only reproduces a failure is not counted). The first one starts a count at 1, and each later one without progress adds 1. No progress means the same first failing test (or another that already failed in this session since implementing started) and no fewer failing tests than the last run of the same command; a run that fails before any test reports is no progress too (unless "A Done when that cannot run" below applies). Each of the 2nd, the 4th and the 8th run of that count is an attempt: raise `attempts` in `State:` and write a new `hyp:`. Fewer failing tests, or a first failing test that has not failed in this session since implementing started, is progress: that run is run 1 of a new count and the attempts stay. A passing run ends the count. A step 9 run is a full run of `Done when` and the regression made to close the node: failed, it is an attempt by the item above and is not added to this count. Every other run is counted here, also a partial one while fixing a step 9 failure. The count is not written to `State:`; a new session starts it at 1.
- **Time limit** (`reference/verification.md`): a run stopped at its limit is a failed run: at step 9 an attempt, elsewhere a run of the loop guard's count without progress. Not when the stop came before any test reported for a reason outside the task ("A Done when that cannot run") or the hang is outside the node (below): those rules apply. A stopped baseline run stops the node as a red baseline does.
- **Escalation** (`reference/routing.md`): with a `Models:` line and work in a subagent (`--delegate`, lanes), each failed attempt raises the next one a tier (`low` → `mid` → `high`), recorded as `tier:`. Without routing, say in the report that a stronger model might help.
- You may change code and the tests this node creates, within the task line.
- Forbidden: editing `Done when`, deleting, skipping or weakening tests, `|| true`, loosened assertions, a narrower command.
- **Outside the node** is a failure that no change within the task line and the tests this node creates can turn green: a flaky test, a regression beyond the task line, or a test the node does not own that the change the task asks for breaks. It blocks at once; the remaining attempts are not used up on it.
- A failure outside the node, and the third failed attempt (list each hypothesis), block the node: `[!]`, `State:` replaced by a `Blocked:` line in the core format (secrets redacted; no git: a root's `files:`/`docs:` go into the action part as `(files: …; docs: …)`), committed with the node's changed files as `chore(backlog): block <ID>`; stop. Roots block the same way.
- Run commands only under the safety rules in `reference/verification.md`.

## A Done when that cannot run

If the `Done when` command fails before any test executes, for a reason outside the task's behavior (a dotted test path that resolves to a foreign package, a missing runtime or tool, an absent service), the node is not red and the failure is not an attempt. Never edit `Done when`, and never close the node with a different or narrower command. Then:

1. If one empty or declarative file inside the node's own test or source folders makes the command resolve (for example an empty `__init__.py`), add it, name it in the node commit body, and report it under "Adjacent problems".
2. Otherwise stop and report "Done when cannot run" with the command and its first error. Fixing the host (an installed package, a path entry, a service) is the user's call.

## A worker that stopped

A node still `[/]` whose worker is gone (a subagent returned, or a session ended, with no verdict written: `[x]` or `[!]`, or `next: drain` on a root; a usage limit, a crash, a closed session; the error text decides nothing) is **resumable**: not a failed attempt, so `attempts` and `tier:` stay and nothing is blocked. `/todo-continue` resumes it (step 2); a lane coordinator only reports it (`reference/lanes.md`). A node whose branch is checked out in another worktree is not gone: report it and do not resume it.

Once the resume goes ahead (the `git status` check of step 2 passed) it starts with a commit of the node's own `TODO.md`, empty if unchanged: `git commit --allow-empty -m 'chore(backlog): resume <ID>' -- TODO.md` (by path, so staged or changed code stays uncommitted). Any commit that is not a resume commit counts as progress, uncommitted work does not: a node that needs more than two sessions without a commit does not fit one context window (the scope rule). If `git log -2 --format=%s` on the node's branch shows `chore(backlog): resume <ID>` twice (resumed twice, nothing committed since), do not resume it again and make no resume commit:

- a leaf that is `mid` or `high`: break it down. Read `reference/plan-step.md`, "Decompose", and follow it for this node. Once the user confirms the children, the node becomes `[ ]` with `State: branch <its own branch> from <the branch it was created from>; next: build children`; until then it stays `[/]`, so every later run offers the breakdown again. Uncommitted changes stay where they are (step 3's clean-tree rule asks about them when a child starts).
- a `low` leaf, or a parent's integration step: block it, `[!]`, with a `Blocked:` line that reads: resumed twice with no new commit → `git log -2 --format=%s` <its output joined with " / "> → decide whether the task or the environment is the problem, then /todo-update <ID> --status ready. As at any block (above) the node's changed files are committed with it and nothing is reverted.

Without git there is no commit to count, so this stop does not apply: resume it and say so in the report.
