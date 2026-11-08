#!/bin/sh
set -eu
exec codex exec --ephemeral --ignore-user-config \
  -c 'default_permissions="trial"' \
  -c 'permissions.trial.filesystem.":root"="read"' \
  -c 'permissions.trial.filesystem."/root/.codex"="deny"' \
  -c 'permissions.trial.filesystem."/runner.sh"="deny"' \
  -c 'permissions.trial.filesystem."/prompt.txt"="deny"' \
  -c 'permissions.trial.filesystem."/work"="write"' \
  -c 'permissions.trial.filesystem."/work/.git"="write"' \
  -c 'permissions.trial.network.enabled=false' \
  -C /work --json - < /prompt.txt