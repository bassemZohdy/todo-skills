# Active Backlog

## 🌳 Task Tree
- [ ] **TASK-004** · P1 · low · Add Codex manifests so the repo installs as a Codex plugin (#8)
  - Done when: both Codex manifests exist and parse, and the nine skills resolve under the .agents/skills path (Codex does not read a top-level skills folder); `python3 -m json.tool .codex-plugin/plugin.json >/dev/null && python3 -m json.tool .agents/plugins/marketplace.json >/dev/null`
  - Links: Ref: README.md
- [ ] **TASK-005** · P1 · mid · Try the nine skills on Codex and state in the README which harnesses are tested (#9)
  - Done when: README names Codex and the version tried, with any skill that does not work there; `grep -n 'Codex' README.md`
  - Links: Depends: TASK-004
- [ ] **TASK-006** · P2 · low · Document `npx skills add bassemZohdy/todo-skills` in the README and confirm it lists all nine skills (#10)
  - Done when: README has the install line and the command lists nine skills; `grep -n 'npx skills add' README.md`
- [ ] **TASK-007** · P2 · low · Submit to the Anthropic plugin directory (owner action: portal login and terms) and record it (#11)
  - Done when: submission date and reference are recorded in docs/distribution.md; `test -f docs/distribution.md`
  - Links: Depends: TASK-005, TASK-006
