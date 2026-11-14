# A variant of the todo-skills arm (FEAT-129): the same skills and the same instructions, plus the optional lifecycle
# helper tools/todo-flow.sh copied to .todo/, as a project has it whose owner copied that script. It lives outside arms/
# because it is not a methodology of its own: pass this folder to run.sh as the arm.
# Usage: bash setup.sh <scratch-repo> <harness-repository-root>
set -eu
repo="$1"; root="$2"
bash "$root/tests/benchmark/arms/todo-skills/setup.sh" "$repo" "$root"
mkdir -p "$repo/.todo"; cp "$root/tools/todo-flow.sh" "$repo/.todo/todo-flow.sh"
