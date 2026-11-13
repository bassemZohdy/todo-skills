# Test failures, blocking, and a Done when that cannot run

Read on demand from `/todo-continue` ("Test failures"), only when a verification run fails or a `Done when` cannot run. Part of the `todo` core skill.

## Test failures

- Diagnose first: reproduce, read the first failing assertion, write one hypothesis in `State:` (`hyp:`), make the smallest change that tests it, rerun.
- At most **3** attempts across sessions (`State:` counter). An attempt is a failed verification run after implementing started; the red run of step 7 (the new test failing before the implementation) is not one.
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
