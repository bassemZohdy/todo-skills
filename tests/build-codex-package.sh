#!/usr/bin/env bash
# Builds a skills-only ZIP of plugin/ for the OpenAI Plugins Directory. A release tool, not part of the plugin.
#   --claude (preferred, TASK-049): the Claude plugin archive the portal imports and converts itself:
#            .claude-plugin/plugin.json (and its icon.png), README.md and skills/. The Codex manifest and its assets are left
#            out, so the portal's conversion is the only Codex manifest (its guide does not say how it treats an existing one).
#   default  (fallback, FEAT-048): the native Codex package: .codex-plugin/plugin.json, README.md, skills/ and the images
#            its interface references (logo, composerIcon and their dark variants). The Claude manifest is left out.
# The ZIP root is the plugin root. Text files are written with LF line endings, entries are sorted with a fixed date and
# mode, so a rebuild of the same commit is byte-identical on every OS. Prints the ZIP's SHA-256.
# Usage: bash tests/build-codex-package.sh [--claude] <out.zip>      Needs python3. Writes only <out.zip>.
set -eu
mode=codex; [ "${1:-}" != --claude ] || { mode=claude; shift; }
out="${1:?usage: build-codex-package.sh [--claude] <out.zip>}"
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
python3 - "$root/plugin" "$out" "$mode" <<'PY'
import hashlib, json, os, sys, zipfile
plugin, out, mode = sys.argv[1:]
files = {'README.md'}
for d, _, names in os.walk(os.path.join(plugin, 'skills')):
    files |= {os.path.relpath(os.path.join(d, n), plugin).replace(os.sep, '/') for n in names}
if mode == 'claude':
    manifest = json.load(open(os.path.join(plugin, '.claude-plugin', 'plugin.json'), encoding='utf-8'))
    if not str(manifest.get('description', '')).strip(): sys.exit('.claude-plugin/plugin.json needs a nonempty description')
    files.add('.claude-plugin/plugin.json')
    if os.path.isfile(os.path.join(plugin, '.claude-plugin', 'icon.png')): files.add('.claude-plugin/icon.png')
else:
    manifest = json.load(open(os.path.join(plugin, '.codex-plugin', 'plugin.json'), encoding='utf-8'))
    files.add('.codex-plugin/plugin.json')
    interface = manifest.get('interface') or {}
    for key in ('logo', 'logoDark', 'composerIcon', 'composerIconDark'):
        path = interface.get(key)
        if path:
            if not path.startswith('./'): sys.exit(f'{key} must be a ./-relative path: {path}')
            files.add(os.path.normpath(path[2:]).replace(os.sep, '/'))
for name in files:
    full = os.path.realpath(os.path.join(plugin, name))
    if not full.startswith(os.path.realpath(plugin) + os.sep) or not os.path.isfile(full): sys.exit(f'not a file inside plugin/: {name}')
with zipfile.ZipFile(out, 'w', zipfile.ZIP_DEFLATED) as z:
    for name in sorted(files):
        data = open(os.path.join(plugin, name), 'rb').read()
        if name.endswith(('.md', '.json', '.txt', '.yml', '.yaml')): data = data.replace(b'\r\n', b'\n')
        info = zipfile.ZipInfo(name, (1980, 1, 1, 0, 0, 0)); info.external_attr = 0o644 << 16; info.compress_type = zipfile.ZIP_DEFLATED
        z.writestr(info, data)
print(hashlib.sha256(open(out, 'rb').read()).hexdigest(), out)
PY
