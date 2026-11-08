# lean-baseline

A single-prompt methodology, used to test whether todo-skills' overhead earns its keep. `arm.md` is a clean rewrite
of a third-party "lean single-file prompt". The original text was not available to this repository; the rewrite
follows the summary in `docs/evals/update-review.md`: an ambiguity stop protocol, tests first, negative and edge cases,
a task file with one status per subtask, a commit per subtask, an exit-0 gate, a resume procedure and a final summary.
It runs in a scratch repository, so its task file does not conflict with a TODO.md backlog. Its known gaps, which the
benchmark is meant to quantify rather than assume: no regression baseline, no independent review and no backlog.
