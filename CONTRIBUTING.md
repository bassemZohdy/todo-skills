# Contributing

Thanks for trying todo-skills. The project is deliberately small: a change that makes the skills longer, adds a required tool, or adds a second way to do something needs a strong reason. The design rules are in the README ("Design rules").

## Report what you saw

The most useful contribution is a trial report. Run the skills on a real project and open an issue (template: *Trial report*) with the command you ran, what you expected, what happened, and the line of skill text you think misled the agent. Scenarios you can reproduce are in `tests/trials/`.

## Change the skills

1. Fork, branch, and keep one change per pull request.
2. Skills are plain Markdown in `skills/`. Keep each `SKILL.md` frontmatter (`name`, `description`, `argument-hint`) accurate, and keep wording short and literal: a model must be able to follow it step by step.
3. If you change a rule, change it in one place and fix every mention (`grep` for the old wording). The core `skills/todo/SKILL.md` owns the schema, invariants and guardrails; command skills must not redefine them.
4. If you change the lint, add a fixture in `tests/fixtures/` (`ok-*.md` must pass, `I<n>-*.md` must fail with that invariant, `W<n>-*.md` must warn).
5. Run `bash tests/run.sh`. It needs only bash, awk, grep and sed, and must report `0 failed`.
6. For behaviour changes, run the matching scenario in `tests/trials/README.md` with a fresh agent and check it with `tests/trials/assert.sh`.
7. Add a line under `## [Unreleased]` in `CHANGELOG.md`. Versions follow the policy in the README.

## Ground rules

- The skills never touch the network, tag, or push. A pull request that adds that will be declined.
- No new required dependencies. Scripts stay optional and read-only.
- Be kind in issues and reviews (see `CODE_OF_CONDUCT.md`).
