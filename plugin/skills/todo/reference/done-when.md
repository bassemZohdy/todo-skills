# Writing a Done when

Read by the commands that write a `Done when`: `/todo-add`, `/todo-plan`, and `/todo-continue` when it breaks a node down. Part of the `todo` core skill.

- Criteria first, then at least one **runnable shell command** in backticks. Write identifiers and calls bare in the criteria; only the command goes in backticks.
- It must run tests that exercise the behavior. `grep` or `test -f` alone is weak (lint W1); a backticked command that is only `ls`, `echo`, `true` or `exit 0` (after any `cd … &&`) is vacuous (I3).
- A `high` or security node also names a negative or boundary case (invalid input rejected, unauthorized request denied), in its criteria or as a child node (lint W5).
- Target a test id or file path, not a name filter, which can exit 0 with zero tests (lint W2): `python3 -m unittest tests.test_calc.CalcTest.test_x`, `pytest tests/test_x.py::test_y`.
- A command may start with `cd <dir> &&` (a package in a monorepo). Add `; regression: \`cmd\`` only when the full suite is the wrong guard, for example a package's own suite. The root always runs the full suite.
- Only a test, lint, typecheck or build command is ever run ("Command safety" in `reference/verification.md`; read that section before you run a command yourself).
