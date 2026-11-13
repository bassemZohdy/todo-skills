# Model routing

Read on demand from the core ("Model routing"), only when the README has a `Models:` line and a subagent tool exists. Part of the `todo` core skill.

- `/todo-continue --delegate` and lane runs give each node (or lane root, at its highest complexity) a subagent on the mapped model.
- The reviewer runs at the node's tier or higher.
- **Escalation:** after a failed verification attempt the next attempt runs one tier higher (`low` → `mid` → `high`), recorded in `State:` as `tier:`. A wrong `low` label costs one cheap attempt, not a blocked node.
