#!/usr/bin/env bash
set -u
root="$(cygpath -m "$1")"
repo="$root/repo"
fs="{\":root\"=\"read\", \"$repo\"=\"write\", \"$root/auth\"=\"deny\", \"$root/evidence\"=\"deny\", \"$root/other\"=\"deny\"}"
export MSYS_NO_PATHCONV=1
codex -c windows.sandbox=mxc -c 'default_permissions="verify"' -c "permissions.verify.filesystem=$fs" -c permissions.verify.network.enabled=false sandbox -P verify -C "$repo" -- node --version
