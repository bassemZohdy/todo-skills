#!/usr/bin/env bash
# Runs todo-lint.sh and todo-stop-hook.sh against the static fixtures in tests/fixtures.
# A fixture named ok-*.md must pass. A fixture named I<n>-*.md must fail with "FAIL I<n>:". W<n>-*.md (W1-W7) must pass with "WARN W<n>:".
# ok-*.md fixtures must also print no WARN line.
# Usage: bash tests/run.sh      Needs bash, awk, grep, sed and python3. Creates files only in a temporary folder it removes.
set -u
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
lint="$root/tools/todo-lint.sh"
hook="$root/tools/todo-stop-hook.sh"
fx="$root/tests/fixtures"
changelog="$fx/changelog/CHANGELOG.md"
pass=0
fail=0

ok()  { pass=$((pass + 1)); printf 'PASS  %s\n' "$1"; }
bad() { fail=$((fail + 1)); printf 'FAIL  %s\n' "$1"; }

for f in "$fx"/*.md; do
  name="$(basename "$f" .md)"
  expect="${name%%-*}"
  out="$(bash "$lint" "$f" "$changelog" 2>&1)"
  rc=$?
  if [ "$expect" = "W1" ] || [ "$expect" = "W2" ] || [ "$expect" = "W3" ] || [ "$expect" = "W4" ] || [ "$expect" = "W5" ] || [ "$expect" = "W6" ] || [ "$expect" = "W7" ] || [ "$expect" = "W8" ]; then
    if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q "WARN $expect:"; then ok "$name"; else bad "$name: expected WARN $expect with rc=0, got rc=$rc: $out"; fi
  elif [ "$expect" = "ok" ]; then
    if [ "$rc" -eq 0 ]; then if printf '%s\n' "$out" | grep -q "^WARN"; then bad "$name: unexpected warning: $out"; else ok "$name"; fi; else bad "$name: expected OK, got: $out"; fi
  else
    if [ "$rc" -ne 0 ] && printf '%s\n' "$out" | grep -q "FAIL $expect:"; then ok "$name"; else bad "$name: expected FAIL $expect, got rc=$rc: $out"; fi
  fi
done

# The plugin version equals the newest released CHANGELOG version.
pv="$(sed -nE 's/.*"version" *: *"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' "$root/plugin/.claude-plugin/plugin.json" | head -1)"
cv="$(sed -nE 's/^## \[([0-9]+\.[0-9]+\.[0-9]+)\].*/\1/p' "$root/CHANGELOG.md" | head -1)"
if [ -n "$pv" ] && { [ -z "$cv" ] || [ "$pv" = "$cv" ]; }; then ok "plugin version $pv matches the changelog (${cv:-no release yet})"; else bad "plugin.json version '$pv' does not match newest CHANGELOG version '$cv'"; fi

# TASK-054: README cannot drift from the release. Every version README states equals both manifests and the newest
# CHANGELOG heading, every `cp -r todo-skills/<path>` install source exists and holds the nine skills, every relative link
# resolves, and one line names each agent with recorded trials together with its evidence files.
readme_bad="$(python3 - "$root" <<'PY'
import json, os, re, sys
root = sys.argv[1]
readme = open(os.path.join(root, 'README.md'), encoding='utf-8').read()
want = {json.load(open(os.path.join(root, 'plugin', d, 'plugin.json'), encoding='utf-8'))['version'] for d in ('.claude-plugin', '.codex-plugin')}
cl = re.search(r'^## \[(\d+\.\d+\.\d+)\]', open(os.path.join(root, 'CHANGELOG.md'), encoding='utf-8').read(), re.M)
if cl: want.add(cl.group(1))
said = set(re.findall(r'(?i)\bversion (\d+\.\d+\.\d+)', readme))
if len(want) != 1 or not said or said != want: print(f'versions: README {sorted(said)}, manifests and CHANGELOG {sorted(want)}')
for src in re.findall(r'cp -r todo-skills/(\S+?)/?\*', readme):
    d = os.path.join(root, src)
    n = sum(os.path.isfile(os.path.join(d, s, 'SKILL.md')) for s in os.listdir(d)) if os.path.isdir(d) else 0
    if n != 9: print(f'install path {src} holds {n} skills, not 9')
for target in re.findall(r'\]\(([^)#\s]+)(?:#[^)]*)?\)', readme):
    if not re.match(r'[a-z]+:', target) and not os.path.exists(os.path.join(root, target)): print(f'broken link {target}')
line = next((l for l in readme.splitlines() if 'Agents with recorded trials:' in l), '')
links = re.findall(r'\]\((docs/evals/[^)]+)\)', line)
if not line or 'Claude Code' not in line or 'Codex' not in line or not links: print('no line names each agent with recorded trials and its evidence')
PY
)"
if [ -z "$readme_bad" ]; then ok "README version, install path, links and agent evidence agree with the repository"; else bad "README drift: $readme_bad"; fi
# TASK-074: the agent-compatibility review line names the current release, the trial-report template names no concrete version,
# and the release steps in DEVELOPMENT.md name the pages that state a version.
verdrift() {   # <repo root>: prints one line per stale statement
python3 - "$1" <<'PY'
import json, os, re, sys
root = sys.argv[1]
def rd(*p): return open(os.path.join(root, *p), encoding='utf-8').read()
want = {json.load(open(os.path.join(root, 'plugin', d, 'plugin.json'), encoding='utf-8'))['version'] for d in ('.claude-plugin', '.codex-plugin')}
m = re.search(r'(?i)last reviewed [0-9-]+, against version (\d+\.\d+\.\d+)', rd('docs', 'agent-compatibility.md'))
if not m: print('docs/agent-compatibility.md has no "Last reviewed <date>, against version X.Y.Z" line')
elif {m.group(1)} != want: print(f'docs/agent-compatibility.md was reviewed against {m.group(1)}, the manifests say {sorted(want)}')
if re.search(r'todo-skills \d+\.\d+\.\d+', rd('.github', 'ISSUE_TEMPLATE', 'trial-report.md')): print('the trial-report template names a concrete todo-skills version')
rel = re.search(r'^## Releasing.*?(?=^## )', rd('docs', 'DEVELOPMENT.md'), re.M | re.S)
for page in ('agent-compatibility.md', 'distribution.md'):
    if not rel or page not in rel.group(0): print(f'the release steps in docs/DEVELOPMENT.md do not name {page}')
PY
}
vd_out="$(verdrift "$root")"
if [ -z "$vd_out" ]; then ok "the agent-compatibility review line names the released version and the release steps name the pages that state one"; else bad "version statements: $(printf '%s' "$vd_out" | tr '\n' ';')"; fi
vdt="$(mktemp -d)"; mkdir -p "$vdt/plugin/.claude-plugin" "$vdt/plugin/.codex-plugin" "$vdt/docs" "$vdt/.github/ISSUE_TEMPLATE"
printf '{"version":"0.5.0"}\n' | tee "$vdt/plugin/.claude-plugin/plugin.json" > "$vdt/plugin/.codex-plugin/plugin.json"
printf 'Last reviewed 2026-11-08, against version 0.4.0.\n' > "$vdt/docs/agent-compatibility.md"
printf '## Releasing\n\n1. tag it\n\n## Documentation\n' > "$vdt/docs/DEVELOPMENT.md"
printf 'Agent and version (todo-skills 0.1.0):\n' > "$vdt/.github/ISSUE_TEMPLATE/trial-report.md"
vd_t="$(verdrift "$vdt")"
if [ "$(printf '%s\n' "$vd_t" | grep -c .)" -eq 4 ]; then ok "the version check fails a stale review line, a concrete version in the template and release steps that omit the pages"; else bad "the version check missed a stale statement: $vd_t"; fi
rm -rf "$vdt"

# Every SKILL.md frontmatter is valid YAML (strict loaders such as the skills CLI skip a skill that is not).
if python3 -c 'import yaml' 2>/dev/null; then
  yamlbad="$(python3 - "$root" <<'PY'
import sys, glob, yaml
for f in sorted(glob.glob(sys.argv[1] + "/plugin/skills/*/SKILL.md")):
    try: yaml.safe_load(open(f, encoding="utf-8").read().split("---")[1])
    except Exception: print(f)
PY
)"
  if [ -z "$yamlbad" ]; then ok "SKILL.md frontmatter is valid YAML"; else bad "invalid YAML frontmatter: $yamlbad"; fi
fi

# The Codex manifest parses and carries the same version as the Claude plugin manifest.
cxv="$(sed -nE 's/.*"version" *: *"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/p' "$root/plugin/.codex-plugin/plugin.json" | head -1)"
if [ -n "$cxv" ] && [ "$cxv" = "$pv" ] && python3 -m json.tool "$root/plugin/.codex-plugin/plugin.json" >/dev/null 2>&1 && python3 -m json.tool "$root/.agents/plugins/marketplace.json" >/dev/null 2>&1; then ok "codex manifests parse and match version $pv"; else bad "codex manifests missing, invalid, or version '$cxv' differs from '$pv'"; fi
# FEAT-048: the Codex manifest carries the public-directory listing metadata within the documented limits
# (developers.openai.com/plugins/deploy/submission, read 2026-11-08) and declares no MCP servers, apps or hooks.
cxbad="$(python3 - "$root/plugin/.codex-plugin/plugin.json" <<'PY' 2>&1
import json, re, sys
m = json.load(open(sys.argv[1], encoding='utf-8')); i = m.get('interface') or {}; e = []
def text(k, n, d=i):
    v = d.get(k)
    if not isinstance(v, str) or not v.strip() or len(v) > n: e.append(f'{k}: required, at most {n} characters')
text('displayName', 30); text('shortDescription', 30); text('longDescription', 4000); text('developerName', 80); text('category', 80)
c = i.get('capabilities')
if not isinstance(c, list) or len(c) > 20 or not all(isinstance(x, str) and 0 < len(x) <= 120 for x in c): e.append('capabilities: at most 20 strings of at most 120 characters')
p = i.get('defaultPrompt', [])
p = [p] if isinstance(p, str) else p
if not isinstance(p, list) or len(p) > 3 or len(set(p)) != len(p) or not all(isinstance(x, str) and 0 < len(x) <= 128 and '@' not in x for x in p): e.append('defaultPrompt: at most 3 unique prompts of at most 128 characters, no @mentions')
for k in ('websiteURL', 'supportURL', 'privacyPolicyURL', 'termsOfServiceURL'):
    if k in i and not (isinstance(i[k], str) and i[k].startswith('https://') and len(i[k]) <= 1024): e.append(f'{k}: HTTPS, at most 1024 characters')
b = i.get('brandColor')
if b is not None:
    if not (isinstance(b, str) and re.fullmatch(r'#[0-9A-Fa-f]{6}', b)): e.append('brandColor: #RRGGBB')
    else:
        lin = lambda v: v / 12.92 if v <= 0.03928 else ((v + 0.055) / 1.055) ** 2.4
        L = sum(w * lin(int(b[k:k + 2], 16) / 255) for w, k in ((0.2126, 1), (0.7152, 3), (0.0722, 5)))
        if 1.05 / (L + 0.05) < 2: e.append('brandColor: contrast against white below 2:1')
if not re.fullmatch(r'[a-z0-9]+(-[a-z0-9]+)*', m.get('name', '')) or len(m['name']) > 64: e.append('name: at most 64 lowercase letters, digits and single hyphens')
text('description', 4000, m)
for k in ('hooks', 'mcpServers', 'apps'):
    if k in m: e.append(f'{k}: a skills-only package declares none')
print('; '.join(e))
PY
)"
if [ -z "$cxbad" ]; then ok "codex manifest carries listing metadata within the directory limits"; else bad "codex listing metadata: $cxbad"; fi
# FEAT-048: logo and composerIcon are ./-relative paths to square PNGs inside plugin/ (48 to 4096 px, at most 5 MiB), and
# the package has nothing the directory refuses: no hooks, no MCP server or app configuration.
cxicon="$(python3 - "$root/plugin" <<'PY' 2>&1
import json, os, struct, sys
root = os.path.realpath(sys.argv[1]); e = []
i = json.load(open(os.path.join(root, '.codex-plugin', 'plugin.json'), encoding='utf-8')).get('interface') or {}
for k in ('logo', 'composerIcon'):
    p = i.get(k)
    if not isinstance(p, str) or not p.startswith('./'): e.append(f'{k}: a ./-relative path is required'); continue
    f = os.path.realpath(os.path.join(root, p))
    if not f.startswith(root + os.sep) or not os.path.isfile(f): e.append(f'{k}: {p} is not a file inside plugin/'); continue
    head = open(f, 'rb').read(24)
    if head[:8] != b'\x89PNG\r\n\x1a\n' or head[12:16] != b'IHDR': e.append(f'{k}: {p} is not a PNG'); continue
    w, h = struct.unpack('>II', head[16:24])
    if w != h or not 48 <= w <= 4096 or os.path.getsize(f) > 5 * 1024 * 1024: e.append(f'{k}: {p} is {w}x{h}, {os.path.getsize(f)} bytes')
for d, dirs, files in os.walk(root):
    for n in dirs + files:
        if n in ('hooks', 'hooks.json', '.mcp.json', '.app.json'): e.append(f'{os.path.relpath(os.path.join(d, n), root)} is not allowed')
print('; '.join(e))
PY
)"
if [ -z "$cxicon" ]; then ok "codex logo and composer icon are square PNGs in the plugin; no hooks, MCP or app files"; else bad "codex listing assets: $cxicon"; fi
# FEAT-048: tests/build-codex-package.sh builds the directory ZIP from plugin/: the Codex manifest at its root, the nine
# skills, the icon it references and the README, nothing else (no Claude manifest, scripts or credentials), byte-identical
# on a rebuild. Built in a temporary folder that is removed again.
zt="$(mktemp -d)"
if bash "$root/tests/build-codex-package.sh" "$zt/a.zip" >/dev/null 2>"$zt/err" && bash "$root/tests/build-codex-package.sh" "$zt/b.zip" >/dev/null 2>&1; then
  zbad="$(python3 - "$root/plugin" "$zt/a.zip" "$zt/b.zip" <<'PY' 2>&1
import json, os, re, sys, zipfile
root, a, b = sys.argv[1:]; e = []
z = zipfile.ZipFile(a); names = z.namelist()
want = {'.codex-plugin/plugin.json', 'README.md', 'assets/icon.png'}
for d, _, files in os.walk(os.path.join(root, 'skills')):
    want |= {os.path.relpath(os.path.join(d, f), root).replace(os.sep, '/') for f in files}
if set(names) != want or len(names) != len(want): e.append(f'entries differ: extra {sorted(set(names) - want)}, missing {sorted(want - set(names))}')
skills = {n.split('/')[1] for n in names if re.fullmatch(r'skills/[^/]+/SKILL\.md', n)}
if len(skills) != 9: e.append(f'{len(skills)} skills, expected 9')
m = json.loads(z.read('.codex-plugin/plugin.json'))
if z.read('.codex-plugin/plugin.json') != open(os.path.join(root, '.codex-plugin', 'plugin.json'), 'rb').read().replace(b'\r\n', b'\n'): e.append('manifest differs from plugin/')
for k in ('logo', 'composerIcon'):
    if m['interface'][k][2:] not in names: e.append(f'{k} not in the ZIP')
for n in names:
    if re.search(r'(^|/)(\.env|auth\.json|credentials|id_rsa|[^/]*\.pem|[^/]*\.key)$', n) or n.startswith('/') or '..' in n.split('/'): e.append(f'unsafe entry {n}')
    if n.endswith(('.md', '.json')) and re.search(rb'(sk-[A-Za-z0-9]{20}|ghp_[A-Za-z0-9]{20}|-----BEGIN [A-Z ]*PRIVATE KEY)', z.read(n)): e.append(f'{n} looks like it holds a secret')
if z.testzip() is not None: e.append('corrupt entry')
if open(a, 'rb').read() != open(b, 'rb').read(): e.append('a rebuild is not byte-identical')
print('; '.join(e))
PY
)"
else zbad="the build failed: $(head -3 "$zt/err")"; fi
rm -rf "$zt"
if [ -z "$zbad" ]; then ok "the Codex directory ZIP holds the manifest, nine skills, the icon and README only, reproducibly"; else bad "codex directory ZIP: $zbad"; fi
# TASK-049: `--claude` builds the preferred import archive: the Claude manifest with a description, its icon, README and
# the nine skills, and nothing the import guide refuses (hooks, commands, agents, MCP, app or settings files, CLAUDE.md,
# a Codex manifest), byte-identical on a rebuild.
zt="$(mktemp -d)"
if bash "$root/tests/build-codex-package.sh" --claude "$zt/a.zip" >/dev/null 2>"$zt/err" && bash "$root/tests/build-codex-package.sh" --claude "$zt/b.zip" >/dev/null 2>&1; then
  cbad="$(python3 - "$root/plugin" "$zt/a.zip" "$zt/b.zip" <<'PY' 2>&1
import json, os, re, sys, zipfile
root, a, b = sys.argv[1:]; e = []
z = zipfile.ZipFile(a); names = z.namelist()
want = {'.claude-plugin/plugin.json', '.claude-plugin/icon.png', 'README.md'}
for d, _, files in os.walk(os.path.join(root, 'skills')):
    want |= {os.path.relpath(os.path.join(d, f), root).replace(os.sep, '/') for f in files}
if set(names) != want or len(names) != len(want): e.append(f'entries differ: extra {sorted(set(names) - want)}, missing {sorted(want - set(names))}')
if len({n.split('/')[1] for n in names if re.fullmatch(r'skills/[^/]+/SKILL\.md', n)}) != 9: e.append('expected 9 skills')
if not str(json.loads(z.read('.claude-plugin/plugin.json')).get('description', '')).strip(): e.append('empty description')
for n in names:
    if re.search(r'(^|/)(hooks|commands|agents|bin)(/|$)|(^|/)(\.mcp\.json|\.app\.json|settings[^/]*\.json|CLAUDE\.md|marketplace\.json)$|^\.codex-plugin/', n): e.append(f'{n} is not for a skills-only import')
    if n.endswith(('.md', '.json')) and re.search(rb'(sk-[A-Za-z0-9]{20}|ghp_[A-Za-z0-9]{20}|-----BEGIN [A-Z ]*PRIVATE KEY)', z.read(n)): e.append(f'{n} looks like it holds a secret')
if open(a, 'rb').read() != open(b, 'rb').read(): e.append('a rebuild is not byte-identical')
print('; '.join(e))
PY
)"
else cbad="the build failed: $(head -3 "$zt/err")"; fi
rm -rf "$zt"
if [ -z "$cbad" ]; then ok "the Claude import archive holds the Claude manifest, icon, README and nine skills only, reproducibly"; else bad "claude import archive: $cbad"; fi
# TASK-049: the OpenAI guide documents the preferred Claude import, the automatic manifest conversion, the native ZIP
# fallback, identity checks, scan findings and limitations, and where to record the submission.
dmiss=""
for h in "### Preferred: Claude plugin import" "### Automatic Codex manifest conversion" "### Fallback: native Codex ZIP" "### Identity and permissions" "### Scan and review findings" "### Limitations" "### Submission record"; do
  sed -n '/^## OpenAI Plugins Directory submission/,/^## [^O]/p' "$root/docs/distribution.md" | grep -qxF "$h" || dmiss="$dmiss '$h'"
done
if [ -z "$dmiss" ]; then ok "docs/distribution.md has the OpenAI Plugins Directory submission guide"; else bad "docs/distribution.md OpenAI submission guide lacks:$dmiss"; fi

# The report template keeps its four placeholders.
tpl="$root/tools/template.html"
if grep -q '>__META__<' "$tpl" && grep -q '>__TODO__<' "$tpl" && grep -q '>__CHANGELOG__<' "$tpl" && grep -q '>__PLAN__<' "$tpl"; then ok "report template placeholders"; else bad "report template placeholders missing"; fi

# Directory policy: the plugin folder ships only Markdown, text, JSON, YAML and PNG/JPEG/GIF/WebP/ICO files, none starting with #!, none with a NUL byte.
badtype="$(cd "$root/plugin" && find . -type f ! -name '*.md' ! -name '*.json' ! -name '*.yml' ! -name '*.yaml' ! -name '*.txt' ! -name '*.png' ! -name '*.jpg' ! -name '*.jpeg' ! -name '*.gif' ! -name '*.webp' ! -name '*.ico' ! -name LICENSE | head -5)"
badshebang="$(cd "$root/plugin" && find . -type f \( -name '*.md' -o -name '*.json' -o -name '*.yml' -o -name '*.yaml' -o -name '*.txt' \) -exec sh -c 'head -c2 "$1" | grep -q "^#!" && echo "$1"' _ {} \; | head -5)"
if [ -z "$badtype" ] && [ -z "$badshebang" ]; then ok "plugin folder ships only allowed file types and no #! files"; else bad "plugin folder has disallowed files: $badtype $badshebang"; fi
if [ -f "$root/plugin/.claude-plugin/plugin.json" ] && grep -q '"source": "./plugin"' "$root/.claude-plugin/marketplace.json" && grep -q '"path": "./plugin"' "$root/.agents/plugins/marketplace.json"; then ok "marketplaces point at the plugin folder"; else bad "a marketplace does not point at ./plugin"; fi
# The plugin folder has a README of at least 40 words outside code blocks (directory requirement).
words="$(sed '/^```/,/^```/d' "$root/plugin/README.md" 2>/dev/null | wc -w)"
if [ "${words:-0}" -ge 40 ]; then ok "plugin README has $words words"; else bad "plugin/README.md is missing or has fewer than 40 words"; fi
# The report template embedded in the skill (Markdown) equals tools/template.html.
emb="$(awk '{ sub(/\r$/, "") } /^````html$/{f=1;next} /^````$/{f=0} f' "$root/plugin/skills/todo-report/template.md")"
if [ "$emb" = "$(sed 's/\r$//' "$root/tools/template.html")" ]; then ok "embedded report template equals tools/template.html"; else bad "plugin/skills/todo-report/template.md differs from tools/template.html: regenerate it"; fi

# Every skill folder has a SKILL.md whose name matches the folder, and the core lists every command skill.
for d in "$root"/plugin/skills/*/; do
  n="$(basename "$d")"
  if grep -q "^name: $n\$" "$d/SKILL.md" 2>/dev/null; then ok "skill $n: name matches folder"; else bad "skill $n: SKILL.md missing or name mismatch"; fi
  if [ "$n" != todo ]; then grep -q "/$n\b" "$root/plugin/skills/todo/SKILL.md" && grep -q "/$n\b" "$root/README.md" || bad "skill $n is not listed in the core commands table and README"; fi
done

# The report generator encodes hostile text (no raw < from the data reaches the page).
tmp_out="$(cd "$fx/report" && printf 'project: x\n' | bash "$root/tools/todo-report.sh")"
if printf '%s' "$tmp_out" | grep -q '<img' || ! printf '%s' "$tmp_out" | grep -q '&lt;/Script>'; then bad "report generator does not encode the data"; else ok "report generator encodes hostile text"; fi

# The report generator refuses to run without a TODO.md in the current directory (FIX-003).
err="$(cd "$fx/changelog" && printf '' | bash "$root/tools/todo-report.sh" 2>&1 >/dev/null)"
rc=$?
if [ "$rc" -eq 1 ] && [ "${err#todo-report:}" != "$err" ]; then ok "report generator exits 1 without TODO.md"; else bad "report generator without TODO.md: expected rc=1 and stderr starting 'todo-report:', got rc=$rc: $err"; fi

# This repository's vendored lint (.todo/, from /todo-init --ci) stays identical to the core lint.
if [ ! -f "$root/.todo/todo-lint.sh" ] || cmp -s "$root/.todo/todo-lint.sh" "$lint"; then ok "vendored .todo/todo-lint.sh matches tools/todo-lint.sh"; else bad ".todo/todo-lint.sh differs from skills/todo/scripts/todo-lint.sh: copy it again"; fi

# The repository's own backlog must follow its own rules.
out="$(cd "$root" && bash "$lint" TODO.md CHANGELOG.md 2>&1)"
if [ $? -eq 0 ]; then ok "this repository's TODO.md and CHANGELOG.md lint clean"; else bad "repo backlog: $out"; fi

# Optional RTM (FEAT-008): docs/RTM.md wins, else README "## RTM", else none; neither is required.
rtm="$root/tools/todo-rtm.sh"
rx="$root/tests/fixtures-rtm"
rtm_is() { out="$(bash "$rtm" "$rx/$1" 2>&1)"; rc=$?; if [ "$rc" -eq "$2" ] && [ "$(printf '%s\n' "$out" | head -1)" = "RTM: $3" ]; then ok "rtm $1: $3 (rc $2)"; else bad "rtm $1: expected 'RTM: $3' rc=$2, got rc=$rc: $out"; fi; }
rtm_is docs-only 0 docs/RTM.md
rtm_is readme-only 0 README.md
rtm_is both 0 docs/RTM.md
rtm_is neither 0 none
rtm_is stale 1 docs/RTM.md
out="$(bash "$rtm" "$rx/stale" 2>&1)"
if printf '%s\n' "$out" | grep -q "FAIL R1:.*GHOST-999" && printf '%s\n' "$out" | grep -q "FAIL R2:.*R-002"; then ok "rtm flags a stale task link (R1) and an archived row without verification (R2)"; else bad "rtm stale checks: $out"; fi
out="$(bash "$rtm" "$rx/readme-only" 2>&1)"
if printf '%s\n' "$out" | grep -q FAIL; then bad "rtm: a table outside the README RTM section was checked: $out"; else ok "rtm: README tables outside ## RTM are ignored; a completed task with verification passes"; fi
rtm_is duplicate 1 docs/RTM.md
out="$(bash "$rtm" "$rx/duplicate" 2>&1)"
if printf '%s\n' "$out" | grep -q "FAIL R3:.*R-001"; then ok "rtm flags a requirement mapped twice (R3)"; else bad "rtm duplicate check: $out"; fi
rtm_is archived-ok 0 docs/RTM.md
out="$(bash "$rtm" "$rx/archived-ok" 2>&1)"
if [ "$(printf '%s\n' "$out" | grep -c FAIL)" -eq 0 ]; then ok "rtm: archived tasks (bullet and Includes) with verification are consistent, open work needs none"; else bad "rtm archived-ok: $out"; fi
out="$(bash "$rtm" "$rx/both" 2>&1)"
if printf '%s\n' "$out" | head -1 | grep -q 'docs/RTM.md' && ! printf '%s' "$out" | grep -q 'README'; then ok "rtm: docs/RTM.md takes precedence over a README RTM section"; else bad "rtm precedence: $out"; fi
out="$(bash "$rtm" "$fx/changelog" 2>&1)"
if [ "$out" = "RTM: none" ]; then ok "rtm: a folder with no README or docs has no RTM"; else bad "rtm without files: $out"; fi
if grep -q 'reference/rtm.md' "$root/plugin/skills/todo/SKILL.md" && grep -q 'rtm.md' "$root/plugin/skills/todo-plan/SKILL.md" && grep -q 'rtm.md' "$root/plugin/skills/todo-add/SKILL.md" && grep -q 'rtm.md' "$root/plugin/skills/todo-continue/SKILL.md" && [ -f "$root/plugin/skills/todo/reference/rtm.md" ]; then ok "plan, add and continue point at the RTM rules"; else bad "an RTM reference is missing from the core, plan, add or continue skill"; fi

# Verification classifier (TASK-009): zero-test runs, missing targets, masked failures; valid runners stay accepted.
vf="$root/tools/todo-verify.sh"
vcase() { want="$1"; rc_in="$2"; cmd="$3"; text="$4"; out="$(cd "$root" && printf '%s\n' "$text" | bash "$vf" "$rc_in" "$cmd" 2>&1)"; if [ "${out%% *}" = "$want" ]; then ok "verify $want: $cmd [$text]"; else bad "verify expected $want for '$cmd' [$text], got: $out"; fi; }
vcase ACCEPT 0 'bash tests/run.sh' '65 passed, 0 failed'
vcase ACCEPT 0 'python3 -m unittest tests.test_calc' 'Ran 3 tests in 0.01s'
vcase ACCEPT 0 'npx jest' 'Tests:       4 passed, 4 total'
vcase ACCEPT 0 'go test ./...' 'ok  	example.com/pkg	0.01s'
vcase ACCEPT 0 'cargo test' 'test result: ok. 3 passed; 0 failed
test result: ok. 0 passed; 0 failed'
vcase ACCEPT 0 'make check' 'done'
vcase REJECT 0 'pytest' 'collected 0 items'
# FIX-068: a run that executed no test is rejected whatever it prints; mixed outputs with a real pass still count.
vcase REJECT 0 'pytest --co -q' '3 tests collected in 0.01s'
vcase REJECT 0 'pytest' '5 skipped in 0.01s'
vcase REJECT 0 'mvn test' 'Tests run: 0, Failures: 0, Errors: 0, Skipped: 0'
vcase REJECT 0 'dotnet test' 'No test is available in x.dll'
vcase ACCEPT 0 'pytest' '1 passed, 4 skipped in 0.01s'
vcase ACCEPT 0 'mvn test' 'Tests run: 0, Failures: 0, Errors: 0, Skipped: 0
Tests run: 3, Failures: 0, Errors: 0, Skipped: 0'
vcase ACCEPT 0 'dotnet test' 'Passed!  - Failed:     0, Passed:     3, Skipped:     0'
vcase REJECT 0 'python3 -m unittest' 'Ran 0 tests in 0.00s'
vcase REJECT 0 'npx jest' 'No tests found, exiting with code 0'
vcase REJECT 0 'npm test' 'Tests: 0 total'
vcase REJECT 0 'rspec' '0 examples, 0 failures'
vcase REJECT 0 'bash tests/missing-test.sh' '3 passed'
vcase REJECT 0 'pytest tests/nope.py::test_x' '1 passed'
vcase REJECT 0 'bash tests/run.sh || true' '65 passed'
vcase REJECT 0 'bash tests/run.sh; exit 0' '65 passed'
vcase REJECT 1 'bash tests/run.sh' '1 failed'
vcase REJECT x 'bash tests/run.sh' '1 passed'

# FIX-076: after "cd <dir> &&" a glob is matched in <dir>, never in the repository root.
vg="$(mktemp -d)"; mkdir -p "$vg/tests" "$vg/pkg/tests" "$vg/pkg/none"
: > "$vg/tests/root_only.py"; : > "$vg/pkg/tests/a.py"
vgcase() { want="$1"; cmd="$2"; out="$(cd "$vg" && printf '3 passed
' | bash "$vf" 0 "$cmd" 2>&1)"; if [ "${out%% *}" = "$want" ]; then ok "verify $want: $cmd (glob after cd)"; else bad "verify $want: $cmd (glob after cd) gave: $out"; fi; }
vgcase ACCEPT 'cd pkg && pytest tests/*.py'
vgcase REJECT 'cd pkg/none && pytest tests/*.py'
vgcase REJECT 'cd pkg && pytest tests/root_only.py'
vgcase ACCEPT 'pytest tests/*.py'
rm -rf "$vg"

# Strict mode (TASK-012): opt-in; default mode keeps accepting count-less runners.
vstrict() { want="$1"; rc_in="$2"; cmd="$3"; text="$4"; out="$(cd "$root" && printf '%s\n' "$text" | bash "$vf" --strict "$rc_in" "$cmd" 2>&1)"; if [ "${out%% *}" = "$want" ]; then ok "verify --strict $want: $cmd [$text]"; else bad "verify --strict expected $want for '$cmd' [$text], got: $out"; fi; }
vstrict ACCEPT 0 'bash tests/run.sh' '65 passed, 0 failed'
vstrict ACCEPT 0 'python3 -m unittest tests.test_calc' 'Ran 3 tests in 0.01s'
vstrict ACCEPT 0 'go test ./...' 'ok  	example.com/pkg	0.01s'
vstrict ACCEPT 0 'set -o pipefail; bash tests/run.sh | tail -3' '65 passed'
vstrict REJECT 0 'make check' 'done'
vstrict REJECT 0 'bash tests/run.sh | tail -3' '65 passed'
vstrict REJECT 0 'bash tests/run.sh 2>&1 | grep passed' '65 passed'
vstrict REJECT 0 'set +e; bash tests/run.sh' '65 passed'
vstrict REJECT 0 'bash tests/run.sh || echo failed' '65 passed'
vstrict REJECT 0 'pytest' 'collected 0 items'
vstrict REJECT 1 'bash tests/run.sh' '1 failed'
vstrict REJECT 0 'bash tests/run.sh || true' '65 passed'
out="$(cd "$root" && printf 'done\n' | bash "$vf" 0 'make check' 2>&1)"
if [ "$out" = "ACCEPT" ]; then ok "verify default mode still accepts a count-less runner"; else bad "default mode changed: $out"; fi

# Optional independent reviews (TASK-016 design review, FEAT-057 root review): one shared reference, optional, never
# required, offered only for high or risky roots; the root review gets the whole root diff, the plan doc and the Ref, and
# without a subagent tool a new-session review is offered. todo-plan and todo-continue point to it; the core lists it.
pl="$root/plugin/skills/todo-plan/SKILL.md"; rvw="$root/plugin/skills/todo/reference/review.md"; ct="$root/plugin/skills/todo-continue/SKILL.md"
rr_bad=""
[ -f "$rvw" ] || rr_bad="$rr_bad review.md(missing)"
for s in 'never a required stage' 'never block a plan on it' 'EGM' 'neither bundles nor requires' '## Design review' '## Root review' \
         'whole root diff' 'git diff <base>...<root branch>' 'the plan doc' 'never offered for a `low` or `mid` root' 'new session'; do
  grep -qF -- "$s" "$rvw" 2>/dev/null || rr_bad="$rr_bad review.md('$s')"
done
grep -qF 'reference/review.md' "$pl" || rr_bad="$rr_bad todo-plan(pointer)"
grep -qF 'reference/review.md' "$ct" && grep -qF 'root review' "$ct" || rr_bad="$rr_bad todo-continue(pointer)"
grep -qF '`reference/review.md`' "$root/plugin/skills/todo/SKILL.md" || rr_bad="$rr_bad core(reference table)"
# Ambiguity pass and stop triggers (FEAT-058): one reference, loaded only for an unclear request, with the checklist, the
# three stop triggers, the 3-question cap per round, and parking in the plan doc or a [!] node, never a new TODO.md section.
cl="$root/plugin/skills/todo/reference/clarify.md"; cl_bad=""
for s in 'Undefined terms' 'acceptance criteria' 'actors' 'Error and boundary cases' 'Out of scope' 'business rule' 'incompatible implementations' 'authorization' 'at most 3' 'trade-off' 'Skip this' '**Open questions**' '`[!]`' 'never a new section'; do
  grep -qF -- "$s" "$cl" 2>/dev/null || cl_bad="$cl_bad clarify.md('$s')"
done
for f in todo-plan todo-add; do grep -qF 'reference/clarify.md' "$root/plugin/skills/$f/SKILL.md" || cl_bad="$cl_bad $f(pointer)"; done
grep -qF '`reference/clarify.md`' "$root/plugin/skills/todo/SKILL.md" || cl_bad="$cl_bad core(reference table)"
if [ -z "$cl_bad" ]; then ok "an unclear request gets the ambiguity checklist and stop triggers from reference/clarify.md"; else bad "ambiguity pass:$cl_bad"; fi
if [ -z "$rr_bad" ]; then ok "optional design and root reviews share reference/review.md, offered only for high or risky roots"; else bad "optional reviews:$rr_bad"; fi
# Negative-case warning (FEAT-060): documented where the warnings and the Done when guidance live.
w5_bad=""
grep -qE '^\| W5 \|' "$root/docs/REFERENCE.md" || w5_bad="$w5_bad REFERENCE(row)"
for f in plugin/skills/todo/reference/verification.md docs/VERIFICATION.md docs/TOOLS.md; do grep -qF 'W5' "$root/$f" || w5_bad="$w5_bad $f"; done
if [ -z "$w5_bad" ]; then ok "W5 (no negative case on a high or security node) is documented"; else bad "W5 docs:$w5_bad"; fi
# W6 (FEAT-066): a command that may download and run remote code is documented where the warnings and the replay live.
w6_bad=""
grep -qE '^\| W6 \|' "$root/docs/REFERENCE.md" || w6_bad="$w6_bad REFERENCE(row)"
grep -qF 'W6' "$root/docs/TOOLS.md" || w6_bad="$w6_bad TOOLS"
grep -qE '^\| W7 \|' "$root/docs/REFERENCE.md" || w6_bad="$w6_bad REFERENCE(W7 row)"
if [ -z "$w6_bad" ]; then ok "W6 (a command that may download and run remote code) is documented"; else bad "W6 docs:$w6_bad"; fi
if grep -q -- '--strict' "$root/plugin/skills/todo/reference/verification.md"; then ok "verification reference documents --strict"; else bad "verification reference lacks --strict"; fi
# A Done when that cannot run for an environmental reason (TASK-027).
vr="$root/plugin/skills/todo/reference/verification.md"
if grep -q '^## A Done when that cannot run' "$vr" && grep -q 'before any test executes' "$vr" && grep -qi 'never edit `Done when`' "$vr" && grep -q 'empty `__init__.py`' "$vr" && grep -q 'Adjacent problems' "$vr" && grep -q 'Done when cannot run' "$vr"; then ok "verification reference says what to do when a Done when cannot run"; else bad "verification reference lacks the cannot-run rule"; fi
# Two-verdict review (FEAT-056): one reviewer call returns spec compliance, then quality; every place that documents the
# Reviewed trailer uses the same form, keeps the self-review fallback, and none keeps the old one-verdict form.
rv_new='Reviewed: subagent, spec <ok|fail> quality <ok|fail>, <n> findings fixed'; rv_self='Reviewed: self, <n> findings fixed'
rv_bad=""
for f in plugin/skills/todo-continue/SKILL.md plugin/skills/todo/reference/git-flow.md docs/VERIFICATION.md docs/GIT-FLOW.md; do
  grep -qF -- "$rv_new" "$root/$f" && grep -qF -- "$rv_self" "$root/$f" || rv_bad="$rv_bad $f(missing)"
  grep -qF -- 'Reviewed: <subagent|self>' "$root/$f" && rv_bad="$rv_bad $f(old form)"
done
grep -q 'spec compliance first' "$root/plugin/skills/todo-continue/SKILL.md" && grep -q 'one call' "$root/plugin/skills/todo-continue/SKILL.md" || rv_bad="$rv_bad todo-continue(order or single call)"
if [ -z "$rv_bad" ]; then ok "review records spec compliance and quality from one reviewer call, with the self-review fallback"; else bad "two-verdict review:$rv_bad"; fi

# Resume, blocked verification and missing optional CI files, all without services (TASK-010).
out="$(bash "$lint" "$fx/ok-resume.md" "$fx/changelog/no-such-CHANGELOG.md" 2>&1)"
if [ $? -eq 0 ]; then ok "lint works without a CHANGELOG.md"; else bad "lint failed without CHANGELOG.md: $out"; fi
out="$(bash "$lint" "$fx/no-such-TODO.md" 2>&1)"
if [ $? -eq 2 ] && printf '%s' "$out" | grep -q '^FAIL: .*not found'; then ok "lint exits 2 without a TODO.md"; else bad "lint without TODO.md: $out"; fi
out="$(printf '{}' | TODO_FILE="$fx/ok-resume.md" CHANGELOG_FILE="$fx/no-such-CHANGELOG.md" bash "$hook")"
if [ -z "$out" ]; then ok "hook allows the stop on an interrupted [/] node with no CHANGELOG.md"; else bad "hook blocked a resumable backlog: $out"; fi
out="$(printf '{}' | TODO_FILE="$fx/ok-blocked-verification.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook allows the stop when verification is blocked"; else bad "hook blocked a blocked-verification backlog: $out"; fi
if [ ! -d "$root/tests/fixtures-rtm/neither/.todo" ]; then ok "a project without .todo/ or CI files is a valid fixture (checks are optional)"; else bad "fixture unexpectedly has .todo/"; fi

# Documentation drift (TASK-011): file:line references, interface changes only, never a new tool.
dd="$root/plugin/skills/todo-continue/SKILL.md"
if grep -q '<file>:<line>: <name>' "$dd" && grep -q 'grep -rnF' "$dd" && grep -q 'changed no interface skips this' "$dd" && grep -q 'never blocks it' "$dd"; then ok "documentation drift reports file:line references and does not block unrelated nodes"; else bad "todo-continue documentation drift rules are incomplete"; fi
drift="$(grep -rnF -- 'todo-lint.sh' "$root/README.md" "$root/docs" 2>/dev/null | head -1)"
if printf '%s' "$drift" | grep -Eq '^[^:]+:[0-9]+:'; then ok "the documented grep -rnF form yields file:line hits"; else bad "grep -rnF drift form gave no file:line: $drift"; fi

# Progress line (FEAT-042): leaves are the unit, roots drained into [Unreleased] count as done, 10 cells (# done, ! blocked).
pf="$fx/progress"
want='Progress: [######!---] 6/9 leaves · 1 active · 1 blocked · 2 roots open · 2 drained in [Unreleased]'
out="$(cd "$pf" && bash "$lint" --progress TODO.md CHANGELOG.md 2>&1)"; rc=$?
if [ "$rc" -eq 0 ] && printf '%s\n' "$out" | grep -q '^OK: invariants' && printf '%s\n' "$out" | grep -qxF "$want"; then ok "lint --progress prints the progress line"; else bad "lint --progress: expected rc=0 and '$want', got rc=$rc: $out"; fi
out="$(bash "$lint" --progress "$fx/I1-two-active.md" "$changelog" 2>&1)"; rc=$?
if [ "$rc" -eq 1 ] && printf '%s\n' "$out" | grep -q '^FAIL I1:' && printf '%s\n' "$out" | grep -q '^Progress: \['; then ok "lint --progress keeps the lint exit code"; else bad "lint --progress on an invalid backlog: rc=$rc: $out"; fi
out="$(bash "$lint" --progress "$fx/ok-valid.md" "$fx/changelog/no-such-CHANGELOG.md" 2>&1)"
if printf '%s\n' "$out" | grep -q '^Progress: \[.*\] [0-9]*/[0-9]* leaves .* 0 drained in \[Unreleased\]$'; then ok "lint --progress works without a CHANGELOG.md"; else bad "lint --progress without CHANGELOG.md: $out"; fi

# The status page computes the same line (its progressLine function, run under node when node is installed).
if command -v node >/dev/null 2>&1; then
  js="$(sed -n '/^\/\/ ---- progress/,/^\/\/ ---- end progress/p' "$root/tools/template.html")"
  got="$(cd "$pf" && printf '%s\n%s\n' "$js" 'const fs=require("fs");process.stdout.write(progressLine(fs.readFileSync("TODO.md","utf8"),fs.readFileSync("CHANGELOG.md","utf8")))' | node 2>&1)"
  if [ -n "$js" ] && [ "$got" = "$want" ]; then ok "status page progressLine matches lint --progress"; else bad "status page progressLine: expected '$want', got '$got'"; fi
  grep -q "\$('progress').textContent=progressLine(" "$root/tools/template.html" && ok "status page shows the progress line" || bad "status page does not render the progress line"
fi
st="$root/plugin/skills/todo-status/SKILL.md"
if grep -q '^## Progress' "$st" && grep -qF 'todo-lint.sh --progress' "$st" && grep -qF 'drained in [Unreleased]' "$st" && grep -qF '`!`' "$st" && grep -q 'per lane' "$st" && grep -qi 'never written to TODO.md' "$st"; then ok "todo-status shows progress bars with the lint's definition, never in TODO.md"; else bad "todo-status progress section missing or incomplete"; fi
# FEAT-042.4: the docs describe the three progress views and the issue 5 decision.
d="$root/docs"
if grep -qF 'todo-lint.sh --progress' "$d/TOOLS.md" && grep -qF 'drained in [Unreleased]' "$d/TOOLS.md" && grep -qF -- '--progress' "$d/COMMANDS.md" && grep -q 'progress line' "$d/COMMANDS.md" && grep -q 'Issue #5.*FEAT-042' "$d/REFERENCE.md" && grep -q 'never written to `TODO.md`' "$d/REFERENCE.md"; then ok "docs describe the progress views and the issue 5 decision"; else bad "docs do not describe the progress views or the issue 5 decision"; fi

# Stop hook: valid backlog allows the stop (no output).
out="$(printf '{"stop_hook_active": false}' | TODO_FILE="$fx/ok-valid.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook allows stop on a valid backlog"; else bad "hook printed output on a valid backlog: $out"; fi

# Stop hook: invalid backlog blocks.
out="$(printf '{"stop_hook_active": false}' | TODO_FILE="$fx/I1-two-active.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if printf '%s' "$out" | grep -q '"decision":"block"'; then ok "hook blocks on an invalid backlog"; else bad "hook did not block: $out"; fi

# Stop hook: never blocks twice in a row (loop guard).
out="$(printf '{"stop_hook_active": true}' | TODO_FILE="$fx/I1-two-active.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook honours stop_hook_active"; else bad "hook ignored stop_hook_active: $out"; fi
# FIX-069: the loop guard reads the flag whatever the JSON whitespace (spaces, tabs, a pretty-printed document), and only true.
hook_with() { printf '%b' "$1" | TODO_FILE="$fx/I1-two-active.md" CHANGELOG_FILE="$changelog" bash "$hook"; }
hg_bad=""
for form in '{"stop_hook_active" : true}' '{"stop_hook_active"\t:\ttrue}' '{\n  "stop_hook_active":\n    true\n}' '{ "other": 1, "stop_hook_active" :true }'; do
  [ -z "$(hook_with "$form")" ] || hg_bad="$hg_bad [$form]"
done
for form in '{"stop_hook_active" : false}' '{"stop_hook_active":\n false}' '{"stop_hook_active": "true"}'; do
  hook_with "$form" | grep -q '"decision":"block"' || hg_bad="$hg_bad (blocks: $form)"
done
if [ -z "$hg_bad" ]; then ok "hook loop guard tolerates JSON whitespace and still blocks when the flag is not true"; else bad "hook loop guard:$hg_bad"; fi

# Stop hook: no TODO.md means nothing to enforce.
out="$(printf '{}' | TODO_FILE="$fx/does-not-exist.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook is silent without a TODO.md"; else bad "hook printed output without TODO.md: $out"; fi

# Replaying newly drained Validated commands (FEAT-059): todo-replay.sh lists, and with --run runs, the Validated commands
# of CHANGELOG entries added since a revision. A command that fails the lint's I3/I10 rules or is an unknown runner (W3) is
# shown and refused, never run (exit 3); a failing replay fails (exit 1); without a revision or new entries nothing runs.
replay="$root/tools/todo-replay.sh"; rt="$(mktemp -d)"
if [ -f "$replay" ]; then
  ( cd "$rt" && git init -q && git config user.email t@example.invalid && git config user.name t && git config core.autocrlf false
    mkdir tests && printf 'exit 0\n' > tests/ok.sh && printf 'exit 1\n' > tests/bad.sh
    printf '# Changelog\n\n## [Unreleased]\n\n### Added\n\n- **FEAT-001** (feat): Old. Validated: `bash tests/bad.sh`.\n' > CHANGELOG.md
    git add -A && git commit -qm base ) >/dev/null 2>&1
  cl_add() { printf '%s\n' "$1" >> "$rt/CHANGELOG.md"; }
  rp() { (cd "$rt" && bash "$replay" "$@" 2>&1); }
  out="$(rp HEAD)"; rc=$?
  [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'nothing to replay' && ok "replay: no entry added since the revision runs nothing" || bad "replay without new entries: rc=$rc $out"
  out="$(rp)"; rc=$?
  [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'nothing to replay' && ok "replay: without a revision it is a no-op" || bad "replay without a revision: rc=$rc $out"
  cl_add '- **FEAT-002** (feat): New. Ref: docs/x.md. Validated: `bash tests/ok.sh`. Docs: updated README.md.'
  out="$(rp HEAD)"; rc=$?
  [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'SAFE  FEAT-002: bash tests/ok.sh' && ! printf '%s' "$out" | grep -q 'FEAT-001' && ok "replay: lists only the new entry's Validated command, without running it" || bad "replay listing: rc=$rc $out"
  out="$(rp --run HEAD)"; rc=$?
  [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'PASS  FEAT-002: bash tests/ok.sh' && ok "replay --run: a passing command passes" || bad "replay run: rc=$rc $out"
  cl_add '- **FIX-003** (fix): Broke. Validated: `bash tests/bad.sh`.'
  out="$(rp --run HEAD)"; rc=$?
  [ "$rc" -eq 1 ] && printf '%s' "$out" | grep -q 'FAIL  FIX-003: bash tests/bad.sh' && ok "replay --run: a failing Validated command fails the check (exit 1)" || bad "replay failure: rc=$rc $out"
  sed -i.bak '/FIX-003/d' "$rt/CHANGELOG.md"
  cl_add '- **TASK-004** (chore): Unsafe. Validated: `sudo touch ran-sudo`; `touch ran-unknown`; `python3 -m unittest x | tail -1`.'
  out="$(rp --run HEAD)"; rc=$?
  [ "$rc" -eq 3 ] && [ "$(printf '%s\n' "$out" | grep -c '^REFUSED  TASK-004')" -eq 3 ] && [ ! -e "$rt/ran-sudo" ] && [ ! -e "$rt/ran-unknown" ] && printf '%s' "$out" | grep -q 'PASS  FEAT-002' \
    && ok "replay: forbidden, unknown-runner and piped commands are shown and refused, never run (exit 3); safe ones still run" || bad "replay refusal: rc=$rc $out"
  # FIX-064: downloaded or generated code that reaches a shell (process substitution, a download then run) is refused, never run.
  cl_add "- **TASK-005** (chore): Download. Validated: \`bash <(curl -s http://127.0.0.1:9/x.sh)\`; \`bash <(printf 'touch ran-procsubst')\`; \`curl -sO http://127.0.0.1:9/x.sh && bash x.sh\`."
  out="$(rp --run HEAD)"; rc=$?
  [ "$rc" -eq 3 ] && [ "$(printf '%s\n' "$out" | grep -c '^REFUSED  TASK-005')" -eq 3 ] && [ ! -e "$rt/ran-procsubst" ] \
    && ok "replay: a download run through process substitution or a download then run is refused, never run" || bad "replay download refusal: rc=$rc $out"
  # FIX-065: every command of a chain is vetted, and a redirect outside the repository is refused; none of them runs.
  cl_add "- **TASK-006** (chore): Chain. Validated: \`bash tests/ok.sh; touch ran-chain\`; \`bash tests/ok.sh && touch ran-chain2\`; \`bash tests/ok.sh > $rt/ran-redirect\`."
  out="$(rp --run HEAD)"; rc=$?
  [ "$rc" -eq 3 ] && [ "$(printf '%s\n' "$out" | grep -c '^REFUSED  TASK-006')" -eq 3 ] && [ ! -e "$rt/ran-chain" ] && [ ! -e "$rt/ran-chain2" ] && [ ! -e "$rt/ran-redirect" ] \
    && ok "replay: an unknown command later in a chain and a redirect outside the repository are refused, never run" || bad "replay chain refusal: rc=$rc $out"
  # FIX-066: a command that may download and run remote code (W6) is refused too.
  cl_add "- **TASK-007** (chore): Fetch. Validated: \`uvx --version\`."
  out="$(rp --run HEAD)"; rc=$?
  [ "$rc" -eq 3 ] && printf '%s\n' "$out" | grep -q '^REFUSED  TASK-007: uvx --version (W6:' \
    && ok "replay: a command that may download and run remote code (W6) is refused, never run" || bad "replay W6 refusal: rc=$rc $out"
fi
[ -f "$replay" ] || bad "tools/todo-replay.sh is missing"
rm -rf "$rt"
# Load budget (TASK-061): the "## Load budget" table in docs/DEVELOPMENT.md lists, per command, the files it always loads
# (under plugin/skills/) and a byte and word budget. Print each command's load, and fail when one is over its budget, when
# a listed file is missing, or when a SKILL.md is in no row. Bytes are counted with LF line endings on every platform.
loadcheck() {   # <doc>: prints LOAD and OVER lines; returns 1 when a row is over, a file is missing or no row parses
  local doc="$1" n=0 over=0 cmd files bb wb b w f
  while IFS='|' read -r _ cmd files bb wb _; do
    cmd="$(printf '%s' "$cmd" | tr -d '`' | sed -e 's/^ *//' -e 's/ *$//')"; bb="$(printf '%s' "$bb" | tr -dc '0-9')"; wb="$(printf '%s' "$wb" | tr -dc '0-9')"
    [ -n "$bb" ] && [ -n "$wb" ] || continue
    n=$((n + 1)); b=0; w=0
    for f in $(printf '%s\n' "$files" | awk -F'`' '{ for (i = 2; i <= NF; i += 2) print $i }'); do
      if [ ! -f "$root/plugin/skills/$f" ]; then echo "OVER $cmd: missing file $f"; over=1; continue; fi
      b=$((b + $(tr -d '\r' < "$root/plugin/skills/$f" | wc -c))); w=$((w + $(wc -w < "$root/plugin/skills/$f")))
    done
    echo "LOAD $cmd: $b bytes, $w words (budget $bb, $wb)"
    if [ "$b" -gt "$bb" ] || [ "$w" -gt "$wb" ]; then echo "OVER $cmd: $b bytes, $w words exceeds $bb, $wb"; over=1; fi
  done < <(tr -d '\r' < "$doc" | awk '/^## Load budget/ { on = 1; next } /^## / { on = 0 } on && /^\| `\// { print }')
  [ "$n" -gt 0 ] && [ "$over" -eq 0 ]
}
lb_out="$(loadcheck "$root/docs/DEVELOPMENT.md")"; lb_rc=$?
printf '%s\n' "$lb_out" | grep '^LOAD' | sed 's/^/      /'
lb_bad="$(printf '%s\n' "$lb_out" | grep '^OVER' | tr '\n' ';')"
lb_rows="$(tr -d '\r' < "$root/docs/DEVELOPMENT.md" | awk '/^## Load budget/ { on = 1; next } /^## / { on = 0 } on')"
for s in "$root"/plugin/skills/*/SKILL.md; do
  rel="${s#"$root/plugin/skills/"}"
  printf '%s\n' "$lb_rows" | grep -qF "\`$rel\`" || lb_bad="$lb_bad $rel is in no row;"
done
if [ "$lb_rc" -eq 0 ] && [ -z "$lb_bad" ]; then ok "every command's always-loaded files fit its budget in docs/DEVELOPMENT.md"; else bad "load budget: ${lb_bad:-no budget row parsed}"; fi
# The check itself must fail a row over its budget.
lbt="$(mktemp -d)"
printf '## Load budget\n\n| Command | Files | Bytes | Words |\n|---|---|---|---|\n| `/todo` | `todo/SKILL.md` | 10 | 10 |\n' > "$lbt/doc.md"
if loadcheck "$lbt/doc.md" | grep -q '^OVER /todo:'; then ok "the load budget check fails a command over its budget"; else bad "the load budget check accepted a command over its budget"; fi
rm -rf "$lbt"
# Safety docs and layout (TASK-071): every script in tools/ is named in SECURITY.md and in the DEVELOPMENT.md layout, and
# every file in plugin/skills/todo/reference/ is named in that layout, so a new script or reference cannot go unlisted.
docslist() {   # <security> <development> <tools dir> <reference dir>: prints one MISSING line per unlisted file
  local sec="$1" dev="$2" f n layout
  layout="$(tr -d '\r' < "$dev" | awk '/^## Layout/ { on = 1; next } /^## / { on = 0 } on')"
  for f in "$3"/*.sh; do
    [ -e "$f" ] || continue
    n="$(basename "$f")"
    grep -qF "$n" "$sec" || echo "MISSING $n in SECURITY.md"
    printf '%s\n' "$layout" | grep -qF "${n%.sh}" || echo "MISSING $n in the DEVELOPMENT.md layout"
  done
  for f in "$4"/*.md; do
    [ -e "$f" ] || continue
    n="$(basename "$f")"
    printf '%s\n' "$layout" | grep -qF "$n" || echo "MISSING reference/$n in the DEVELOPMENT.md layout"
  done
}
dl_out="$(docslist "$root/SECURITY.md" "$root/docs/DEVELOPMENT.md" "$root/tools" "$root/plugin/skills/todo/reference")"
if [ -z "$dl_out" ]; then ok "SECURITY.md and the DEVELOPMENT.md layout name every script in tools/ and every reference file"; else bad "docs omit files: $(printf '%s' "$dl_out" | tr '\n' ';')"; fi
dlt="$(mktemp -d)"; mkdir -p "$dlt/tools" "$dlt/ref"
printf 'x\n' > "$dlt/tools/todo-new.sh"; printf 'x\n' > "$dlt/ref/extra.md"
printf '# Security\ntodo-lint.sh\n' > "$dlt/sec.md"; printf '## Layout\n\ntodo-lint\n\n## Next\n\ntodo-new extra.md\n' > "$dlt/dev.md"
dl_t="$(docslist "$dlt/sec.md" "$dlt/dev.md" "$dlt/tools" "$dlt/ref")"
if [ "$(printf '%s\n' "$dl_t" | grep -c '^MISSING')" -eq 3 ]; then ok "the docs check fails a script missing from SECURITY.md and from the layout, and a reference file missing from the layout"; else bad "the docs check missed an unlisted file: $dl_t"; fi
rm -rf "$dlt"
# Workflow bounds (TASK-072): test.yml runs on Windows too, and every workflow has a concurrency group and a timeout on each job.
wfcheck() {   # <workflow file> [need-windows]: prints one WF line per missing property
  local f="$1" jobs timeouts
  tr -d '\r' < "$f" | grep -q '^concurrency:' || echo "WF $(basename "$f"): no concurrency group"
  jobs="$(tr -d '\r' < "$f" | awk '/^jobs:/ { on = 1; next } on && /^  [A-Za-z0-9_-]+:/ { n++ } END { print n + 0 }')"
  timeouts="$(tr -d '\r' < "$f" | grep -c '^    timeout-minutes: [0-9]')"
  [ "$jobs" -gt 0 ] && [ "$timeouts" -ge "$jobs" ] || echo "WF $(basename "$f"): $timeouts timeout-minutes for $jobs jobs"
  if [ -n "${2:-}" ]; then tr -d '\r' < "$f" | grep -q 'windows-' || echo "WF $(basename "$f"): no Windows runner"; fi
}
wf_out="$(wfcheck "$root/.github/workflows/test.yml" windows; for w in "$root"/.github/workflows/*.yml; do [ "$(basename "$w")" = test.yml ] || wfcheck "$w"; done)"
if [ -z "$wf_out" ]; then ok "test.yml runs on Windows and every workflow has a concurrency group and a timeout on each job"; else bad "workflows: $(printf '%s' "$wf_out" | tr '\n' ';')"; fi
wft="$(mktemp -d)"
printf 'name: t\njobs:\n  test:\n    runs-on: ubuntu-latest\n    steps: []\n' > "$wft/bare.yml"
wf_t="$(wfcheck "$wft/bare.yml" windows)"
if [ "$(printf '%s\n' "$wf_t" | grep -c '^WF')" -eq 3 ]; then ok "the workflow check fails a missing Windows runner, timeout and concurrency group"; else bad "the workflow check missed a gap: $wf_t"; fi
rm -rf "$wft"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
