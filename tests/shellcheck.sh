#!/usr/bin/env bash
# shellcheck.sh - static analysis of this repository's shell scripts (TASK-073). A developer tool, not part of the plugin.
# Usage: bash tests/shellcheck.sh [file...]      With no file it checks the scripts in scope (below).
# Needs shellcheck: python3 -m pip install shellcheck-py==0.10.0.1 (CI installs that version). The checks the repository
# disables on purpose are in .shellcheckrc. Exit 0 when clean, 1 on findings, 127 when shellcheck is not installed.
set -eu
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
if ! command -v shellcheck >/dev/null 2>&1; then
  echo "shellcheck is not installed (python3 -m pip install shellcheck-py==0.10.0.1)" >&2
  exit 127
fi
if [ "$#" -eq 0 ]; then set -- tools/*.sh .todo/*.sh tests/*.sh; fi
shellcheck "$@"
