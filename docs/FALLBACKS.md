# Fallbacks

What to do when something the skills rely on is missing or fails. Each row says how the skill notices, what it falls back to and what you lose. Nothing here needs the network.

| Situation | How it shows | Fallback | What you lose |
|---|---|---|---|
| Not a git repository | `git rev-parse --is-inside-work-tree` fails | **No-git mode**: one warning, progress in `State:`, no branches or commits. `git init` turns the full flow on | Isolation, history, claims, the diff-based self-review |
| `bash`, `awk` or `grep` missing (for example plain Windows) | Scripts do not run | Run `/todo` and the skills without scripts: the agent checks I1-I10 and the gates by reading and running the commands itself | The deterministic lint and gate |
| Gate script absent or crashes (not a `GATE ... FAIL`) | `todo-gate.sh` missing or exits 2 | Run the `Done when` and regression commands by hand per `reference/verification.md` and quote the counts | Zero-test and baseline-count detection |
| Lint script absent | `scripts/todo-lint.sh` missing | The agent checks the invariants by reading | Determinism |
| Test count not recognised | `GATE regression: NOTE test count not recognised` | Compare the counts printed by the runner against `baseline` by hand | Automatic baseline comparison |
| Base branch refuses the claim fast-forward (hook or protection, not because it moved) | `git merge --ff-only` is rejected | **Branch-only claim**: keep the claim commit on the root branch, say the claim is not published, and publish it by your usual flow (push, pull request) | Duplicate-work protection until the claim reaches the base |
| Lost a claim race | The fast-forward fails and the base shows another branch | Delete your unpublished branch, report the rival, continue with the next workable root | Nothing; no duplicate work |
| Stale claim (branch gone) | `/todo-status` shows `stale` | `/todo-update <ROOT-ID> --status ready` | Nothing |
| Working tree dirty | Ready check stops | Commit or stash your changes, or run `/todo-continue --worktree` so the node gets its own tree | Time |
| Base branch behind its remote | Warning from the ready check | `git pull` the base yourself, then rerun | Nothing, once pulled |
| No subagent tool | `--isolated` unavailable | Runs normally in the main thread | Independent review |
| No test command or no tests | `/todo-init` reports `unknown` | Name the command in README (`Tests:` line). With no tests at all the first node records `baseline none` and creates the harness | Regression protection until then |
| Baseline red (pre-existing failure) | Ready check blocks the node | Add a `FIX` root for the failure and do it first. To work meanwhile, give the node a `regression:` command that excludes the known failure; that is your explicit decision, written in the task | Full-suite protection |
| Full suite too slow | Slow ready checks | Give leaf nodes a scoped `regression:` (the package's own suite); the root still runs the full suite before it lands | Cross-package regressions are found at the root |
| Unfamiliar or risky test command | Lint W3 | Read the command; set `TODO_LINT_STRICT=1` to make W3 a failure | A stricter allowlist |
| Team flow with pull requests | No `--merge` | The root's branch is printed with the push and pull-request steps | Local auto-merge |
| Conflicting `TODO.md` or `CHANGELOG.md` merge | Git reports a conflict | Follow "Git conflicts" in `reference/git-flow.md` (union of entries, renumber collisions) | Manual care |
| A session dies mid-task | A branch with `[/]` or an unmerged `[x]` | The next `/todo-continue` finishes the merge or resumes first | Nothing |
| Hook cannot be registered (plugin install) | The stop hook never runs | Run `bash skills/todo/scripts/todo-lint.sh` as a pre-commit or CI step | The end-of-session check |
