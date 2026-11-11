# Contributing

Thanks for trying todo-skills. The project is deliberately small: a change that makes the skills longer, adds a required tool, or adds a second way to do something needs a strong reason. The design rules are in [docs/REFERENCE.md](docs/REFERENCE.md#design-rules); the repository layout, the tests and the release steps are in [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## Report what you saw

The most useful contribution is a trial report. Run the skills on a real project and open an issue (template: *Trial report*) with the command you ran, what you expected, what happened, and the line of skill text you think misled the agent. Bugs in the scripts or docs use the *Bug* template. Scenarios you can reproduce are in `tests/trials/`.

## Change the skills

1. Fork, branch, and keep one change per pull request.
2. Skills are plain Markdown in `plugin/skills/`. Keep each `SKILL.md` frontmatter (`name`, `description`, `argument-hint`) accurate, and keep wording short and literal: a model must be able to follow it step by step.
3. If you change a rule, change it in one place and fix every mention (`grep` for the old wording). The core `plugin/skills/todo/SKILL.md` owns the schema, invariants and guardrails; command skills must not redefine them.
4. Keep the plugin folder to Markdown, JSON and images ([packaging rules](docs/DEVELOPMENT.md#packaging-rules)). Scripts go in `tools/`; the status page template is edited in `tools/template.html` and copied into `plugin/skills/todo-report/template.md`.
5. If you change the lint, add a fixture in `tests/fixtures/` (`ok-*.md` must pass, `I<n>-*.md` must fail with that invariant, `W<n>-*.md` must warn).
6. Run `bash tests/run.sh`. It needs bash, awk, grep, sed and python3, and must report `0 failed`. If you touched `tests/trials/`, also run `bash tests/trials/selftest.sh` and the agent-free `tests/trials/test-*.sh` checks, as CI does (`test-codex-isolation.sh` and `test-codex-invocation.sh` need a logged-in Codex, `test-linux-boundary.sh` needs Docker with the Codex image, so they are run by hand; `test-windows-verifier-isolation.sh` runs only on native Windows, in its own workflow).
7. For behavior changes, run the matching scenario in `tests/trials/README.md` with a fresh agent and check it with `tests/trials/assert.sh`. Keep what you saw as evidence (prompt, log, exit codes, assertion output, checksums) as `docs/evals/` does, and say what was not verified.
8. Add a line under `## [Unreleased]` in `CHANGELOG.md`. Versions follow the policy in [docs/REFERENCE.md](docs/REFERENCE.md#versioning).
9. Update the documentation the change touches; [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md#documentation) lists which page covers what.

## Ground rules

- The skills never touch the network, tag, or push. A pull request that adds that will be declined.
- No new required dependencies. Scripts stay optional and read-only (`todo-replay.sh --run` is the one that runs commands, and only ones the lint accepts).
- Be kind in issues and reviews (see `CODE_OF_CONDUCT.md`).
