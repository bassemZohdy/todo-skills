# Test classes (optional)

Read from `reference/verification.md` only when the README has a `Smoke:` line: a test command, like `Tests:`, that runs the smoke class (and from `/todo-init`, "Detecting a smoke command", when it has none). With no `Smoke:` line nothing changes: the regression is the whole suite for every node. Part of the `todo` core skill.

## Classes

- **sanity**: the tests that a node's `Done when` names. They prove the node.
- **smoke**: broad, shallow, fast. A few cheap tests across the areas of the project, run by the `Smoke:` command. They show that a node broke nothing obvious.
- **regression**: broad, deep, the full suite (the `Tests:` command, smoke included).

## Tags

Every new test gets one class tag, `smoke` or `regression`, written the way the project's own runner selects tests: a pytest marker, a JUnit `@Tag`, a Jest project or name pattern, a Maven profile, a folder. Sanity is no tag. Tag a test `smoke` only when it is fast and covers something wide; when unsure, `regression`. A new test without a tag fails the review (spec). A `regression` test that `Done when` does not name first runs at the integration step, so name it in `Done when` when it proves the node.

## Where each class runs

- **The first node of a tree** also runs the full suite once at its start, and its start commit writes that count into the root's `State:` as `baseline <n> passing`, before `branch`. This is the tree's full count.
- **A child node** takes the `Smoke:` command as its baseline and regression: its own `baseline <n> passing` is the smoke count. Its verification is `Done when`, then smoke. A node's `regression:` command replaces smoke. A node that changes the test setup, a shared fixture or the `Smoke:` line takes its baseline and verification from the full suite instead. The test setup is the runner's configuration or a shared fixture: a new test file or a package marker such as `__init__.py` does not change the test setup, so a node whose only setup-like change is one of them keeps smoke. Otherwise a child node does not run the full suite: it runs only its `Done when` and smoke (or its `regression:` command), and the full suite runs at the first node's start and at the parent's integration step.
- **A parent's integration step** (the root's too) runs the full suite as its baseline and again last. A red baseline there is not the usual red-baseline stop: the children caused it, so follow "Finding the node". The final count must not fall below the tree's full count in the root's `State:`.
- **A leaf root** runs the full suite at its start and its end, as without `Smoke:`.

Each class is compared with its own count: smoke with the smoke count at the node's start, the full suite with the full count. No fewer passing tests, none deleted, skipped or weakened (protocol step 6, "No cheating").

## Finding the node

A full suite that is red at a parent's integration step although every child's smoke passed does not say which child broke it. Do not guess. Take the failing test ids, without those listed in the root's `baseline red:`, and walk the merges of the parent's branch (`Merge <ID> into <PARENT>`), oldest first, after checking the claim commit:

1. Run the project's own test command, limited to those ids the way `Done when` limits it (`reference/done-when.md`), on each commit in a temporary detached worktree (`git worktree add --detach`, removed with `git worktree remove`, as in `reference/git-flow-edge.md`, "`--worktree`"). It is the project's test command: read it and its setup first ("Command safety" in `reference/verification.md`), and install what it needs in the worktree as the README says; when that cannot be done, block with that reason, not with a guess.
2. A run that finds none of those tests (a later child added them) is neither red nor green: go to the next merge. They fail at the claim commit: the baseline was red, stop as for a red baseline.
3. The first merge where they run and fail names the node. A count that falls with no failing test is a deleted or skipped test: compare the test counts of the merges instead.

Block the root (`[!]`) with ``Blocked: full suite red at the integration step, <ID> broke it → `<test command>` <failing ids> → fix <ID>``, and suggest `/todo-add "<what failed>" --type fix --from <ID>`.

## Detecting a smoke command

Read by `/todo-init` when the README has no `Smoke:` line. Look for a command the project already has; the first match wins, and nothing is run:

- a pytest marker `smoke` that at least one test uses (`grep -rl mark.smoke` over the tests; a name only registered in `pytest.ini`, `pyproject.toml` or `setup.cfg` selects nothing): `pytest -m smoke`, with the `Tests:` prefix (`uv run pytest -m smoke` when `uv.lock` exists);
- a Maven profile `smoke` in `pom.xml`: `./mvnw test -Psmoke` when the wrapper exists, else `mvn test -Psmoke`;
- a `package.json` script `test:smoke` or `smoke`: `<package manager> run <name>`, the package manager chosen by lockfile as for `Tests:`;
- a `Makefile` target `smoke`: `make smoke`.

Name the source. Read the script or target it runs first ("Command safety" in `reference/verification.md`) and offer it only if it passes. The offer, its place in README and the yes follow the `Tests:` line. The `Smoke:` line is a backlog file (core). Never invent a command and never tag a test for the user.
