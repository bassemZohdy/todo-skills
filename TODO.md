# Active Backlog

## 🌳 Task Tree
- [ ] **TASK-045** · P1 · mid · Repeat the Windows Codex lifecycle batch with the default isolated verifier
  - Done when: every scenario is scored PASS, FAIL or INFRA_ERROR with its cause recorded, assertions ran through windows-assert-exec.sh, and the published evidence passes its checker; `bash tests/trials/test-windows-codex-evidence.sh`
  - Links: Ref: docs/evals/fix-041.md
- [ ] **FEAT-048** · P1 · mid · Prepare the existing skills-only Codex plugin for OpenAI public-directory submission
  - Done when: the native Codex package includes valid public listing metadata and assets without MCP, hooks or duplicated skills; `bash tests/run.sh`
  - Links: Ref: docs/distribution.md
  - [ ] **FEAT-048.1** · mid · Add required Codex interface metadata to the existing plugin manifest
    - Done when: interface defines displayName, shortDescription, longDescription, developerName, category and capabilities with documented limits; `bash tests/run.sh`
  - [ ] **FEAT-048.2** · mid · Package referenced listing logo and composer icon with minimal assets
    - Done when: manifest logo and composerIcon paths resolve to permitted image assets inside plugin/ and the package excludes scripts and hooks; `bash tests/run.sh`
  - [ ] **FEAT-048.3** · mid · Build and validate a skills-only ZIP from the current plugin directory
    - Done when: clean ZIP contains the manifest, all nine skills and assets, excludes credentials, passes local regression and records any portal-only checks; `bash tests/run.sh`
- [ ] **TASK-049** · P1 · low · Document OpenAI Plugins Directory submission and security disclosures
  - Done when: docs/distribution.md records packaging, developer verification, permissions, skills-only limitations, portal checks and how to handle review findings; `test -f docs/distribution.md`; `bash tests/run.sh`
  - Links: Ref: docs/distribution.md · Depends: FEAT-048
- [ ] **TASK-046** · P2 · mid · Publish durable, checksummed evidence for FIX-035 to FIX-041 and verify it in CI
  - Done when: docs/evals holds the evidence with SHA256SUMS and the Ubuntu and macOS CI jobs run its checker; `bash tests/trials/test-fix-evidence.sh`
  - Links: Ref: docs/evals/codex-linux-2026-11-08/ci-verification.md
- [ ] **TASK-047** · P2 · low · Release 0.4.0 once the evidence tasks are done and regression checks pass
  - Done when: CHANGELOG has a dated 0.4.0 section and both plugin manifests carry 0.4.0; `grep -q '^## \[0.4.0\] - ' CHANGELOG.md`; regression: `bash tests/run.sh`
  - Links: Depends: TASK-043, TASK-044, TASK-045, TASK-046
- [ ] **TASK-050** · P2 · low · Submit the validated Codex package for OpenAI directory review and record its outcome
  - Done when: actual portal submission reference, package version, submission date and review status or documented owner blocker are recorded in docs/distribution.md; `test -f docs/distribution.md`
  - Links: Ref: docs/distribution.md · Depends: TASK-049, TASK-047
