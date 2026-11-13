# Verification

How a node is proven done, what blocks it, and which commands an agent may run. The rules the model follows are in [`plugin/skills/todo/reference/verification.md`](../plugin/skills/todo/reference/verification.md), in [`done-when.md`](../plugin/skills/todo/reference/done-when.md) (writing a `Done when`) and [`failures.md`](../plugin/skills/todo/reference/failures.md) (read only when a run fails) beside it, and in `/todo-continue` ("Review", "Verify", "Documentation drift").

## The protocol

A node closes only through these steps.

1. **Baseline.** Before work starts, the regression command runs on the branch the node will start from. Green: the pass count goes into `State:` as `baseline <n> passing`. A project with no tests records `baseline none`; its first node creates the test harness, and its regression gate is only that its own `Done when` runs at least one test and passes. **Red stops the node** before any branch or file change, with one exception: a `FIX` node whose `Done when` runs at least one of the failing tests may start with `baseline red: <ids>`, and its gate is then a fully green regression. Otherwise the report names the failing tests and suggests `/todo-add "fix the failing baseline: …" --type fix --priority P0`. A failing test id is written as the fullest name the runner's summary prints, without a line number: `test_calc.CalcTest.test_add` (unittest), `AddTest.adds` (Surefire), `add (tests/add.test.ts)` (`node --test`).
2. **Red.** Tests first. `FIX` and `FEAT` leaves must fail for the expected reason: an assertion about the new behavior or a missing-symbol error for the new thing under test. A test that already passes stops the node (the work may be done already). `TASK` refactors get characterization tests that pass before and after.
3. **Green.** Implement only what the task line says. Adjacent findings go into the report, not into the code or `TODO.md`. No new `TODO`/`FIXME`.
4. **Refactor** with the tests green.
5. **Review** (below).
6. **Done when**, in full, exactly as written.
7. **Regression.** The node's `regression:` command, or the project's full suite: the README `Tests:` line, otherwise the command `/todo-init` would detect. No fewer passing tests than the baseline, none deleted or skipped. A suite of several packages counts the passing tests of all of them. If the command itself cannot run, the node stops as for a red baseline.
8. **Gates:** each item of the project's [Definition of Done](REFERENCE.md#definition-of-done-optional), the RTM Verification cell when an RTM exists, and documentation drift (below).

**Parents** (the integration step, once every child is `[x]`): run the parent's `Done when` and the regression; add one test only if the children's tests do not already cover the combined behavior; no feature code. A root's integration step, refresh from the base, last gate and drain happen in one invocation, with the full suite last.

**Last gate before a root lands:** when `.todo/check.sh` exists, the agent reads it (only a shebang, comments, `set -eu`, `cd`, the lint line and test commands that pass command safety are accepted; anything else is shown and asked about) and runs it after the refresh from the base. Red blocks the root.

## What does not count

- A run that executed zero tests ("0 tests", "no tests found", "collected 0 items", "NO TESTS RAN").
- A failure masked by `|| true`, `; exit 0` or an unchecked pipe.
- A test file or path named by the command that does not exist.
- Deleted, skipped or weakened tests, loosened assertions, or a narrower command than the one written.

The optional [`tools/todo-verify.sh`](TOOLS.md#todo-verifysh) classifies a finished run by these rules, and the lint rejects a `Done when` that masks failures (I3).

## Writing a Done when

- Criteria first, then `; ` and at least one **runnable shell command** in backticks. Write identifiers and calls bare in the criteria (calc.power(2, 3) returns 8); only the command goes in backticks. Never `manual` or `n/a`.
- The command must run tests that exercise the behavior. `grep` or `test -f` alone is weak (W1); a command that is only `ls`, `echo`, `true` or `exit 0` is vacuous and fails I3.
- A `high` node, or one about authentication, tokens, secrets or permissions, also proves what must not happen: an invalid input rejected, an unauthorized request denied, a failure raised. Put it in the criteria (a valid file loads and an invalid one raises ConfigError) or in a child node of its own. The lint warns (W5) when the criteria name no such case; the check reads only words, so it can miss or over-match.
- Target a test id or file path, not a name filter, which can exit 0 with zero tests (W2): `python3 -m unittest tests.test_calc.CalcTest.test_power`, `pytest tests/test_x.py::test_y`, `npx jest tests/auth/rotate.test.ts`, `mvn -Dtest=SubtractTest -Dsurefire.failIfNoSpecifiedTests=true test`.
- If the test does not exist yet, name the file or id the node will create. If an existing test already covers the criterion, the work is not new (except a `FIX` naming a test that exists and fails now).
- A command may start with `cd <dir> &&` (a package in a monorepo). Add `; regression: \`cmd\`` only when the full suite is the wrong guard, for example a package's own suite. A root always runs the full suite.
- Containers get their own `Done when`: the integration test or, when the children cover it, the regression command. A parent's `Done when` may pass at baseline; only leaves must start red.
- When a `Done when` names an exact test id, keep that name and put the task ID in the test's docstring or a comment; otherwise the ID goes into the test name.
- Environment assignments are allowed (`SERVICE_URL=127.0.0.1:17233 pytest -q`). Prefer a reviewed, self-contained test entry script that starts and stops the services it needs.

### Deliverables without a natural unit test

Pick a focused, safe, executable check: for a shell script, run it in a controlled fixture and assert its exit status and output; for CI YAML, parse the workflow and assert the required jobs and steps; for documentation, run a link or anchor checker on the changed pages; for configuration, a local validation or smoke command with an assertion. The red state is the missing deliverable or the specific assertion failing, never an unrelated syntax, setup or network error.

### A Done when that cannot run

If the command fails before any test executes for a reason outside the task (a dotted test path resolving to a foreign package, a missing runtime or tool, an absent service), the node is not red and the failure is not an attempt. The `Done when` is never edited and the node is never closed with another command. If one empty or declarative file inside the node's own folders fixes it (an empty `__init__.py`), the agent adds it, names it in the commit body and reports it. Otherwise it stops with "Done when cannot run", the command and its first error. Fixing the host is your call. An unavailable service is never called a passing baseline.

## Review

Between build and verify, `/todo-continue` reviews the whole diff (`git diff`; in no-git mode, the files in `State: files:`), spec compliance first, then quality:

- **Spec:** every hunk traces to the task line and nothing it asks for is missing; the tests assert the `Done when` criteria (not vacuous, nothing weakened) and carry the task ID.
- **Quality:** no debug output, commented-out code, new `TODO`/`FIXME`, unrelated reformatting, generated files, secrets or `.env` in the diff or in backlog text.

With a subagent tool, a fresh-context reviewer does both in one call, given only the task lines, the `Ref` path and the diff (at the node's tier or higher with a `Models:` line), and returns a verdict for each (`ok` or `fail`) with its findings; it never edits files or runs tests. Without one, the agent reviews its own diff. Valid findings are fixed, at most 2 rounds; findings still valid after that block the node. The node commit records the first round's verdicts as `Reviewed: subagent, spec <ok|fail> quality <ok|fail>, <n> findings fixed`, or `Reviewed: self, <n> findings fixed` for a self-review. Separate verdicts show whether findings were about building the wrong thing or building it badly.

## Test failures and blocking

- Diagnose first: reproduce, read the first failing assertion, write one hypothesis into `State:` (`hyp:`), make the smallest change that tests it, rerun.
- At most **3 attempts** across sessions, counted in `State:` (`attempts n/3`). An attempt is a failed verification run after implementing started; the first red run is not one.
- **Escalation:** with a `Models:` line and work in a subagent (`--delegate`, lanes), each failed attempt raises the next one a tier (`low` → `mid` → `high`), recorded as `tier:`. Without routing, the report says a stronger model might help.
- Allowed: changing code and the tests this node creates, within the task line. Forbidden: editing `Done when`; deleting, skipping or weakening tests; `|| true`; loosened assertions; a narrower command.
- A failure outside the node (a flaky test, a regression beyond the task line), a Definition of Done item that is missing, review findings still valid after 2 rounds, or the third failed attempt **blocks the node**: `[!]`, with `State:` replaced by `Blocked: <reason> → <command> <error> → <action required>` (secrets redacted), committed as `chore(backlog): block <ID>` with the node's changed files. The agent stops. `/todo-update <ID> --status ready` unblocks it with a fresh attempt counter.

## Documentation drift

- If the implementation must deviate from the `Ref` doc, the agent stops and lets you choose: change the code, or update the doc in this node.
- Only when the node changed a public interface (a command, flag, endpoint, config key or exported symbol: added, renamed, removed or with a changed meaning), it searches README and `docs/` (not `docs/plans/`) for each changed name with `grep -rnF -- '<name>' README.md docs`, and reports each hit as `<file>:<line>: <name> - <what to change>`.
- Hits that fit within the task line are updated in the node and listed as `Docs: updated <file>` in the CHANGELOG entry; the rest become `/todo-add "update <file>:<line> for <name>" --type task --from <ID>` commands in the report. Only a hit that the `Done when` or the Definition of Done names blocks the node, and drift that already existed never does.
- README setup or test instructions that disagree with the commands that passed are reported.

## Command safety

`Done when` text can be influenced by docs and pull requests, so the agent treats it like untrusted input.

- It runs a command only if it is a test, lint, typecheck or build command. The same applies to the regression command (README `Tests:` line, CI config or detected command) in every invocation.
- When a command runs a script or target (`bash <file>`, `./<file>`, `make <target>`, `npm test`, `npm run <script>` and the like), the agent reads what it executes first and applies these rules to that too; it blocks if it cannot read it.
- `npx`, `bunx`, `uvx` and `pnpm dlx` run only packages already in the lockfile (`npx --no-install` preferred).
- Refused and blocked: anything that deletes files, uses `sudo`, runs downloaded code without review, pushes or publishes, deploys, touches paths outside the repository and its todo worktrees, or reads credentials.

The lint's I10 rejects the obvious cases and W3 flags unfamiliar runners, but neither is a sandbox. Read a task before you let an agent run it.
