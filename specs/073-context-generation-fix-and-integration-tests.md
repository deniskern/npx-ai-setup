# Spec: Generation Reliability Fix and Integration Tests

> **Spec ID**: 073 | **Created**: 2026-03-10 | **Status**: draft | **Branch**: —

<!-- Status lifecycle: draft → in-progress → in-review → completed (or blocked at any stage) -->

## Goal
Fix insufficient `--max-turns` across all 3 generation calls and add an integration test that catches install regressions locally.

## Context
Users report only 1 of 3 `.agents/context/` files on fresh installs. Root cause: `--max-turns 4` is too tight — Claude uses a turn for text output, leaving <3 turns for Write calls. Audit of all `claude -p` calls found the same problem in CLAUDE.md (`--max-turns 3`) and AGENTS.md (`--max-turns 3`) — both have 0 buffer for retry. None of the 3 calls have retry logic. The project only has static smoke tests — no test runs the actual installer.

## Steps
- [ ] Step 1: In `lib/generate.sh`, increase `--max-turns` for all 3 generation calls: CLAUDE.md 3→5, AGENTS.md 3→5, context files 4→8
- [ ] Step 2: In `lib/generate.sh`, add a retry block for partial context generation (~line 562): if `CTX_COUNT < 3` and exit was 0, retry once with `--max-turns 12`, re-check, update `CTX_COUNT`
- [ ] Step 3: In `lib/generate.sh`, add retry blocks for CLAUDE.md and AGENTS.md: if verification fails (checksum unchanged) and exit was 0, retry once with `--max-turns 6`
- [ ] Step 4: Create `tests/integration.sh` — temp dir with minimal `package.json`, runs `bin/ai-setup.sh` non-interactively (skip claude-dependent generation), verifies all expected files/dirs exist
- [ ] Step 5: In `tests/integration.sh`, add template-sync check: every `templates/commands/*.md` must have a matching `.claude/commands/*.md` installed
- [ ] Step 6: Add `install_workflow_guide` to function-presence checks in `tests/smoke.sh`
- [ ] Step 7: Verify both test suites pass: `bash tests/smoke.sh && bash tests/integration.sh`

## Acceptance Criteria
- [ ] All 3 `claude -p` calls have sufficient `--max-turns` (>=5 for edits, >=8 for writes)
- [ ] All 3 generation calls have a single-retry fallback on failure
- [ ] `tests/integration.sh` runs in <5s without network or API dependencies
- [ ] Both `tests/smoke.sh` and `tests/integration.sh` pass green

## Files to Modify
- `lib/generate.sh` - increase max-turns, add retry logic for all 3 calls
- `tests/integration.sh` - new integration test script
- `tests/smoke.sh` - add install_workflow_guide check

## Out of Scope
- Testing context generation via claude CLI (requires API key)
- CI pipeline integration (separate task)
- Mocking the claude CLI for offline generation tests
