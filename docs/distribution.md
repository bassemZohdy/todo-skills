# Distribution

| Channel | Status | How |
|---|---|---|
| Claude Code plugin marketplace (this repo) | Available | `/plugin marketplace add bassemZohdy/todo-skills` |
| Codex plugin marketplace (this repo) | Available, verified on codex-cli 0.167.0 | `codex plugin marketplace add bassemZohdy/todo-skills` |
| skills CLI | Available (discovery of all nine skills verified from the repository root and from `plugin/`, 2026-11-07) | `npx skills add bassemZohdy/todo-skills` |
| OpenAI Plugins Directory (Codex) | Not submitted: package checked for 0.4.0, upload blocked on the owner (TASK-050); Claude skills-only import preferred | `bash tests/build-codex-package.sh --claude todo-skills-claude.zip`, then an owner upload at platform.openai.com/plugins that converts the manifest; the native Codex ZIP (without `--claude`) is the fallback. See below |
| Anthropic plugin directory | Resubmitted 2026-11-07 from the `plugin` folder, awaiting the automatic check (0.3.1) | Owner action at claude.ai/directory/manage (login and terms) |

Keep `plugin/.claude-plugin/plugin.json` and `plugin/.codex-plugin/plugin.json` on the same version as the newest CHANGELOG release; `tests/run.sh` checks it. Codex caches an install by that version, so bump it on every release.

## Anthropic directory submission

First submission, refused by directory policy (source was the repository root): 2026-11-07 · https://claude.ai/directory/manage/plugins/1aa64a1d-da6d-4226-bcaa-a5d444c86cd9
Submitted: 2026-11-07 · Reference: https://claude.ai/directory/manage/plugins/66a20c4e-d892-44f4-be45-0c174c7365e2 (plugin path `plugin`, version 0.3.1)

Validation of `main @ 29817a3` passed with 4 warnings and 6 policy holds. Handled since: listing icon added (a square PNG in the `.claude-plugin` folder), the `todo-release` wording that could read as a skill command line, and a disclosure of what the plugin runs, reads, writes and sends (README, SECURITY.md). Left for the reviewer: the credential-read hold (the safety rules name credential paths only to refuse them) and the name-resemblance hold. Validation of `main @ 318e230` passed with 3 warnings and 12 policy holds, all reviewer-confirmable: five name look-alikes (Nodo, Qodo, Todo4, qodo-skills, Topo), the credential-read hold (the lint regexes and the safety rules name forbidden commands such as `eval`, `sh -c` and credential paths in text only; nothing reads the environment or sends data), the download-and-execute pattern (the same rules text and the test helper `tests/trials/assert.sh`), and the unread-asset hold for the icon. This repository's own `.todo/check.sh` lost its `#!` line (it is run with `bash`). Re-validate before submitting; the report covers only the commit it read.

### Checklist (owner action)

Prepared from the repository; the portal's own fields may differ, so check them as you fill the form.

- [ ] Sign in at claude.ai/directory/manage and accept the directory terms.
- [ ] Plugin: `todo-skills`, manifest `plugin/.claude-plugin/plugin.json`, license MIT, author Bassem Zohdy, homepage https://github.com/bassemZohdy/todo-skills.
- [ ] Version: the newest release in CHANGELOG.md (0.5.0 today). `[Unreleased]` holds unreleased work, so run `/todo-release` first if the submission should include it, then keep both manifests on that version.
- [ ] `bash tests/run.sh` passes on the commit you submit.
- [ ] Short description: "A lean, file-native backlog for coding agents: a task tree in TODO.md, a branch per task, tests plus regression before anything merges, and an append-only CHANGELOG.md."
- [ ] Install check from a clean client: `/plugin marketplace add bassemZohdy/todo-skills`, then confirm the nine skills (todo, todo-add, todo-continue, todo-init, todo-plan, todo-release, todo-report, todo-status, todo-update) are listed.
- [ ] Security notes for the reviewer: no network access by the skills, no required tooling beyond git/bash, see SECURITY.md.
- [ ] After submitting, record below: `Submitted: <YYYY-MM-DD> · Reference: <id or URL from the portal>`, and set the table row above to "Submitted".

## OpenAI Plugins Directory submission

Official guidance: [submit a Claude plugin](https://developers.openai.com/plugins/guides/submit-claude-plugin), the
[submission instructions](https://developers.openai.com/plugins/deploy/submission) and [building Codex plugins](https://developers.openai.com/codex/plugins/build),
read on 2026-11-08. The owner submits at platform.openai.com/plugins; nothing in this repository uploads anything. Follow the
portal's current fields where they differ from this page.

### Preferred: Claude plugin import

`todo-skills` already ships a working Claude Code skills-only plugin, so upload that instead of maintaining a second
hand-authored submission format:

1. Release first (`/todo-release`), so both manifests carry the version you submit, then on that commit run
   `bash tests/run.sh` and `bash tests/build-codex-package.sh --claude todo-skills-claude.zip`. Keep the printed SHA-256.
   The archive root is the plugin root: `.claude-plugin/plugin.json` (with its nonempty `description`) and `icon.png`,
   `README.md`, and all nine `skills/<name>/SKILL.md` with their `reference/` files and the report template. `tests/run.sh`
   checks that it holds nothing else: no hooks, commands, agents, `bin/`, MCP, app or settings files, `CLAUDE.md`, marketplace
   file or credential-like content, and that a rebuild gives the same bytes. The Codex manifest is left out on purpose (see
   the next section).
2. In the portal choose **Create plugin → Skills only** and upload the archive.
3. Review the converted manifest (next section), complete the listing and review fields, and provide listing assets only
   when the portal asks for them; do not duplicate skills.
4. Test the imported skills in a clean supported environment: all nine are discoverable, relative references resolve, and
   local Git and file operations work where the surface supports local execution. Local execution depends on the
   environment; it is not guaranteed on every ChatGPT surface.
5. Resolve every scan result, submit for review and record the result below. Approval in the Claude directory does not
   transfer to OpenAI.

### Automatic Codex manifest conversion

The portal converts `.claude-plugin/plugin.json` into `.codex-plugin/plugin.json`, "adds missing interface defaults and
normalizes text fields". The guide does not list which fields it generates, and does not say what it does with an
archive that already holds a `.codex-plugin/plugin.json`, so the `--claude` archive has none. Compare the generated
`interface` with the hand-checked one in `plugin/.codex-plugin/plugin.json`, which is within the documented limits
(`tests/run.sh` checks them):

| Field | Ours | Limit |
|---|---|---|
| `displayName` | Todo Skills | 30 characters |
| `shortDescription` | File-native backlog for agents | 30 characters |
| `longDescription` | the nine skills, who they are for, and their limits | 4000 characters |
| `developerName` | Bassem Zohdy | 80 characters; must match the verified identity |
| `category` | Developer Tools | a category title the dashboard offers; no published list |
| `capabilities` | Interactive, Read, Write | at most 20 of 120 characters; allowed values not published |
| `defaultPrompt` | three starter prompts | at most 3 of 128 characters, no @mentions |
| `brandColor` | `#115E59` | `#RRGGBB`, at least 2:1 contrast on white |
| `logo`, `composerIcon` | `./assets/icon.png`, 1024 px | square PNG/JPEG/WebP/SVG, 48 to 4096 px, at most 5 MiB |

If a generated value is wrong or empty, correct it in the portal using the values above.

### Fallback: native Codex ZIP

`bash tests/build-codex-package.sh todo-skills-codex.zip` builds the native Codex package (FEAT-048), for manual
distribution or for a conversion problem: `.codex-plugin/plugin.json` with the listing `interface`, `README.md`, the nine
skills and `assets/icon.png`; no Claude manifest, scripts, hooks, MCP or app files. Text is stored with LF endings,
sorted, with a fixed date, so a commit gives the same bytes on every OS. `tests/run.sh` builds it twice and checks the
entries, skills, icon and the absence of credentials. A throwaway Codex home installed all nine skills from the extracted
ZIP (codex-cli 0.167.0). It does not need to be rebuilt just for the import path.

### Identity and permissions

- **Submitter:** the organization owner, or a member with "Apps Management" write access, in the owning OpenAI organization.
- **Identity:** complete individual or business identity verification first. The listing's developer name (`Bassem Zohdy`)
  must match the identity it is published under; if not, change `interface.developerName` and rebuild.
- **What the plugin does** (the same disclosure as [SECURITY.md](../SECURITY.md#what-it-runs-reads-writes-and-sends)), for the
  review form and the `Interactive`, `Read`, `Write` capabilities: it runs `git` (branch, commit, merge, worktree; never
  fetch, pull, push, tag, reset hard or clean) and the project's own test, lint and build commands; it reads the backlog,
  docs, project marker and CI files and the source a task needs, never credentials, tokens, `~/.ssh` or `~/.aws`; it writes
  `TODO.md`, `CHANGELOG.md`, a task's source and tests and, only after the user agrees, README lines, plan docs, CI files and
  a `pre-push` hook; it sends nothing. The skills limit `Done when` to test, lint, typecheck and build commands and refuse
  deletes, `sudo`, downloaded code, pushes, deploys, paths outside the repository and credential reads. These are
  instructions the agent follows, not a sandbox: say so in the review form.

### Scan and review findings

- The upload runs the Metadata and Skills scans; fix every finding before submitting. Every plugin then goes through
  OpenAI review, and only one review can be active per plugin.
- Record each finding as a backlog task (`/todo-add "<finding>" --type fix`) with the finding's wording, and work it like
  any other task. A change to the skills, a manifest or the icon needs a new version and a new archive.
- Findings that need no change (for example a hold on a name resemblance) are answered in the portal; a rejection can be
  appealed by replying to the rejection email. Record the answer below.

### Limitations

- Skills only: no MCP server, app or hook, so no review test cases, demo recording or reviewer credentials are needed, and
  the website, support, privacy and terms URLs are optional. The optional Stop hook and scripts in `tools/` are not
  packaged; users copy them by hand ([TOOLS.md](TOOLS.md)).
- The skills need a Git repository with a working test command and local execution; without them they stop and say so. The
  guide asks to contact an OpenAI partner first when a plugin's core value needs local execution or arbitrary file access,
  which this one does: raise it with the submission if the portal flags it.
- In `codex exec`, `/todo-*` is not a guaranteed entry point; `$todo-status` (an explicit skill mention) and plain language
  are ([evidence](evals/codex-2026-11-07/summary.md)). Inside Codex's Windows sandbox, Git may be unable to create branches,
  so lifecycle runs there can stop at the claim step ([evidence](evals/codex-2026-11-07/summary.md)).
- The skills never name Claude, so the guide's request for provider-neutral wording needs no change.

### Submission record

One line per upload (TASK-050):

`Submitted: <YYYY-MM-DD> · Path: <Claude import | native ZIP> · Reference: <portal id or URL> · Version: <x.y.z> · Source commit: <sha> · Archive SHA-256: <hash> · Status: <in review | approved | rejected: reason | blocked: reason>`

Checked: 2026-11-08 · Path: Claude import · Reference: none · Version: 0.4.0 · Source commit: 8b5a2fd (last change under `plugin/`) · Archive SHA-256: e1141ebebaa342563d1088c8ec0c621a48eee61f24e1178661892d7614aee75d · Status: blocked: the upload needs the owner's OpenAI account at the portal, which an agent must not use

What was checked (TASK-050): `bash tests/build-codex-package.sh --claude` gives 18 entries, the nine skills and a `.claude-plugin/plugin.json` with a description at version 0.4.0; the native ZIP (SHA-256 `7dd71ccb02cd8a769567f745e6d728f8a762dc17b4948f0b22ac600d3a2d5f1d`) has the same skills and a `.codex-plugin/plugin.json` within the listing limits. Neither has scripts, hooks, MCP or app files. The portal's converted manifest can only be checked after the owner's upload; record that upload as a `Submitted:` line above this one.

## Directory policy refusal of v0.3.0

The directory refused v0.3.0 (f74f542) because the plugin folder held scripts and an HTML file, which only Verified organizations may ship. From 0.3.1 the plugin is the `plugin/` folder, Markdown and JSON plus the icon only (`tests/run.sh` checks the file types and that nothing starts with `#!`). Submit or point the portal at the `plugin` folder (the folder holding `.claude-plugin/plugin.json`). Scripts and tests stay in the repository root as developer tools.
