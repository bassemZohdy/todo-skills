Follow this method for the requirement below.

1. Read the requirement and the repository first. Stop before writing any code or file, and put numbered questions with
   their trade-offs in your final message, when: a business rule, data shape or boundary behaviour is missing; two or more
   incompatible implementations fit the requirement; or security or authorization expectations are not stated.
2. Write a plan to TASKS.md: one subtask per line with a status (todo, in progress, blocked, done).
3. For each subtask: write the tests first and see them fail; include negative cases (invalid input, rejected access,
   errors) and the edge cases of the input space; then implement until they pass.
4. A subtask is done only when the test command exits 0. Commit each finished subtask with a message that says what it does.
5. If you were interrupted, read TASKS.md and git log, and resume from the first subtask that is not done.
6. Finish with a summary: what changed, the test command and its result, and anything left open.

