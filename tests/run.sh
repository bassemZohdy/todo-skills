#!/usr/bin/env bash
# Runs todo-lint.sh and todo-stop-hook.sh against the static fixtures in tests/fixtures.
# A fixture named ok-*.md must pass. A fixture named I<n>-*.md must fail with "FAIL I<n>:". W<n>-*.md (W1-W4) must pass with "WARN W<n>:".
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
  if [ "$expect" = "W1" ] || [ "$expect" = "W2" ] || [ "$expect" = "W3" ] || [ "$expect" = "W4" ]; then
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

# Optional independent design review (TASK-016): documented, optional, never required.
pl="$root/plugin/skills/todo-plan/SKILL.md"
if grep -q 'Independent design review (optional, never a required stage)' "$pl" && grep -q 'never block a plan on it' "$pl" && grep -q 'EGM' "$pl" && grep -q 'neither bundles nor requires' "$pl"; then ok "todo-plan documents an optional fresh-context or external design review"; else bad "todo-plan design review section missing or implies it is required"; fi
if grep -q -- '--strict' "$root/plugin/skills/todo/reference/verification.md"; then ok "verification reference documents --strict"; else bad "verification reference lacks --strict"; fi
# A Done when that cannot run for an environmental reason (TASK-027).
vr="$root/plugin/skills/todo/reference/verification.md"
if grep -q '^## A Done when that cannot run' "$vr" && grep -q 'before any test executes' "$vr" && grep -qi 'never edit `Done when`' "$vr" && grep -q 'empty `__init__.py`' "$vr" && grep -q 'Adjacent problems' "$vr" && grep -q 'Done when cannot run' "$vr"; then ok "verification reference says what to do when a Done when cannot run"; else bad "verification reference lacks the cannot-run rule"; fi

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

# Stop hook: no TODO.md means nothing to enforce.
out="$(printf '{}' | TODO_FILE="$fx/does-not-exist.md" CHANGELOG_FILE="$changelog" bash "$hook")"
if [ -z "$out" ]; then ok "hook is silent without a TODO.md"; else bad "hook printed output without TODO.md: $out"; fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
