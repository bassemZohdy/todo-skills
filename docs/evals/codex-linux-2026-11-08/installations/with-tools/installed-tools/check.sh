#!/usr/bin/env bash
set -eu
bash .todo/todo-lint.sh TODO.md CHANGELOG.md
python3 -m unittest discover -s tests
