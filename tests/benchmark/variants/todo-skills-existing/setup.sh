# A variant of the todo-skills arm (TASK-139.1): the same skills, in a project whose backlog is already set up. After the arm's own
# setup it leaves what /todo-init writes on a yes in a project without a backlog: TODO.md with the Lanes section and an empty Task
# Tree, and CHANGELOG.md with an empty [Unreleased]. run.sh puts them in the start commit, so the agent starts at todo-add and a cell
# pays only the per-task part of the method. No .todo/check.sh (plain init without --ci does not write it), no plan doc and no status
# page; the scenarios' README.md already holds the Tests line init would offer. It lives outside arms/ because it is not a
# methodology of its own: pass this folder to run.sh as the arm.
# Usage: bash setup.sh <scratch-repo> <harness-repository-root>
set -eu
repo="$1"; root="$2"
bash "$root/tests/benchmark/arms/todo-skills/setup.sh" "$repo" "$root"
printf '%s\n' '# Active Backlog

## 🛤️ Lanes

- main: the default track

## 🌳 Task Tree' > "$repo/TODO.md"
printf '%s\n' '# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]' > "$repo/CHANGELOG.md"
