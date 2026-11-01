# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `todo` core skill and the `todo-init`, `todo-add`, `todo-continue` and `todo-update` command skills.
- Self-review gate in `todo-continue`: every changed hunk must trace to the task's Scope before the drain.
- README with install steps, task format and known limits.
