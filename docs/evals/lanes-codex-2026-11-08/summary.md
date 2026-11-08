# Concurrent Codex lanes, 2026-11-08 (TASK-044)

Earlier `multi-module` runs with Codex used the skill's no-subagent fallback: one agent worked both lanes one after
another, and worktree events alone could not show concurrency ([FIX-036](../codex-linux-2026-11-08/summary.md)). This run
starts **one fresh Codex process per lane at the same time** and records each worker's own activity.

**Result: PASS, `execution: concurrent`.** 15 of 15 assertions passed. The two lane workers were launched 3 ms apart and
were both doing tool work for 75 s at once. Trust stays provisional, for the sandbox reasons of the earlier Linux batch.

## How it ran

`tests/trials/run-codex-lanes.sh` (copied here as `run-codex-lanes.sh`, identical to controller commit `0ea76c0`) makes the
controller the coordinator's subagent tool, without changing the skills:

1. **Coordinator** (session `01a1ba73-4d80-…`): `/todo-continue --all-lanes --merge` ran steps 0-2 of `reference/lanes.md`
   (two claim commits fast-forwarded on `main`, one worktree per root) and, at step 3, wrote one brief per lane to
   `<repo>.todo/<ROOT-ID>.brief.md` instead of doing lane work (`run/briefs/`).
2. **Lanes**: the controller accepted both briefs after checking them against Git (`run/dispatch.txt`) and started one
   `codex exec --json` per lane at once (`run/launches.txt`). FEAT-001 (lane `core`, session `01a1ba74-915c-…`) and FEAT-002
   (lane `text`, session `01a1ba74-915d-…`) each wrote a failing test, ran it red with Maven, implemented, ran it green
   plus the reactor regression, and committed the node with `next: drain`. Each could write only its own worktree, the
   shared `.git` and its own `.git/worktrees/<name>`; every command and file change stayed in its own worktree.
3. **Finishing coordinator** (session `01a1ba76-193b-…`): `/todo-continue --all-lanes --merge` again; its step 0 took both
   roots at `next: drain` to step 4: refreshed each from `main`, re-ran `Done when` and the regression (3 tests, then 4),
   drained and merged them (`Merge FEAT-001 into main`, `Merge FEAT-002 into main`), and removed the worktrees.

The controller ran `assert-exec.sh` with the Linux verifier profile afterwards: 15 passed, 0 failed (`run/assert.log`).
Its `INFO lane execution: unverified` line is expected: `assert.sh` sees only Git events, never the activity file.

## Activity evidence

The controller stamped every line of each worker's `codex exec --json` stream with its own clock as the line arrived
(`run/lanes/<ID>/events.log`). A worker's activity runs from its first tool event (`item.started` of a command or file
change) to its last (`item.completed`). The events come from the Codex process; an agent's command output only appears
quoted inside an event. `run/activity.txt` was written outside every root the agents could write:

| Lane | Root | Session | Active (controller clock) | Tool events |
|---|---|---|---|---|
| core | FEAT-001 | `01a1ba74-915c-7a62-a879-4b2311fcbcdd` | 1794129572.6 to 1794129647.8 | 14 |
| text | FEAT-002 | `01a1ba74-915d-7df0-aaee-e080e9238041` | 1794129571.7 to 1794129652.0 | 13 |

`lane-evidence.sh` reads these as `concurrent`. Process lifetimes and worktree events are not used; the stubbed harness
test shows that overlapping processes with disjoint tool activity read as `sequential` (`test-lane-activity.sh`).

## Environment

- Image `todo-codex-linux-maven:0.167.0-login` (`Dockerfile`): the earlier Maven image plus links that put `mvn`, `java`
  and `javac` on the login-shell `PATH`. Codex CLI 0.167.0, model `gpt-6.1-terra`, `--ephemeral --ignore-user-config`.
- Profile per agent (`command.txt`, line `filesystem:`): read everything, deny the login, the controller and the evidence,
  write only the listed roots, no network. A Maven cache (`todo-lanes-m2`) was filled beforehand and was read-only to the
  agents. Every agent got `TMPDIR` and `java.io.tmpdir` inside its own writable Git metadata. `docker-run.txt` has the
  container command.

## Attempts

Four attempts, all kept under `diagnostics/`. Each failure was in the trial environment, and each fix is a runner commit:

| Attempt | Controller | Result | Cause and fix |
|---|---|---|---|
| 1 | `2c955b1` | both workers exited 1, stopped | Denying the whole runs folder kept the sandbox from mounting a worktree's Git metadata (`bwrap: Can't mkdir parents`). Fix `f548cb2`: deny the runs folder's other entries, grant `.git/worktrees/<name>` |
| 2 | `f548cb2` | stopped before the finishing session | `mvn: command not found` for the core worker: Codex runs `bash -lc`, and Debian's `/etc/profile` drops Maven from `PATH`. The text worker finished. Fix: the `-login` image; `3c0e2fc` skips the finishing session when a lane is not at `next: drain`, so it cannot redo the lane alone |
| 3 | `3c0e2fc` | FAIL: lanes concurrent, nothing drained | The finishing coordinator stopped before verifying: Maven's Jansi tried to write a lock file under the read-only `/tmp`, which it read as the command-safety rule's "touches paths outside the repo and its todo worktrees". Fix `0ea76c0`: a writable temp folder per agent |
| 4 | `0ea76c0` | **PASS**, concurrent | |

Attempt 3 is also a finding about the skill text: a build tool's own temp files can read as a command-safety violation.
The workers saw the same Jansi warning and carried on. The skills were not changed for this run.

## Ambiguities the agents reported

Each agent's `report.txt` quotes them. Recurring ones:

- Core "At most one `[/]` task" against lanes leaving each root "`[/]` with `next: drain`" (coordinator): read as per worktree.
- `verification.md` "A root's integration step and drain happen in one invocation" against the lane rule that the worker
  "stops before the root's drain" (both workers): both followed the lane rule.
- Step 8 "With a subagent tool, a fresh-context reviewer does this" against the host rule not to spawn agents (both
  workers): both reviewed their change themselves.
- The documentation search `grep -rnF -- '<name>' README.md docs` in a project without `docs/` (both workers).
- Step 0's "`next: drain` goes to step 4" could be read as skipping step 4's re-verification (finishing coordinator): it
  ran step 4 in full.
- Lane step 3 "gets only" the listed information, while the prompt added trial rules (coordinator): it put them in each brief.

## Verify

`bash tests/trials/test-lane-concurrency-evidence.sh` checks both `SHA256SUMS` files, that the runner equals the one at the
controller commit, the four distinct sessions and their profiles, recomputes each worker's activity from its stamped
event stream and compares it with `activity.txt`, checks that each worker stayed in its worktree and ran Maven, the
drains and merges, and asks `lane-evidence.sh` for the verdict. It runs no agent, and CI runs it.
