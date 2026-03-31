# Spec: Setup Consistency Hardening

> **Spec ID**: 598 | **Created**: 2026-03-29 | **Status**: completed | **Complexity**: medium | **Branch**: spec/598-setup-consistency-hardening

## Goal
Make the setup CLI consistent across runtime behavior, recovery hints, and test coverage so documented paths match actual execution.

## Context
The current review found four linked issues: documented flags that are not implemented, `jq`-optional messaging that conflicts with hard `jq` calls, stale `--regenerate` recovery hints, and tests/docs that overstate coverage. Relevant skills: `spec`, `spec-validate`.

### Verified Assumptions
- Unknown flags should fail fast instead of being ignored — Evidence: `README.md` documents explicit flag behavior | Confidence: High | If Wrong: CLI docs must be changed to declare permissive flag parsing.
- `jq` is intended to be optional when Node.js is present — Evidence: `lib/setup.sh`, `README.md` | Confidence: High | If Wrong: requirement handling, docs, and tests should be simplified to require `jq`.
- Regeneration now belongs to the interactive update flow, not a standalone flag — Evidence: `bin/ai-setup.sh`, `lib/update.sh` | Confidence: High | If Wrong: a non-interactive regenerate flag must be reintroduced.

## Steps
- [x] Step 1: Tighten CLI argument handling in `bin/ai-setup.sh` so unsupported flags fail with a clear error, and either implement or remove any documented flags that are currently advertised but not supported.
- [x] Step 2: Replace direct `jq` gating in `bin/ai-setup.sh` with the existing JSON wrapper path so update detection and statusline checks honor the documented Node fallback.
- [x] Step 3: Update regeneration and recovery messaging in `AGENTS.md`, `templates/AGENTS.md`, and `lib/generate.sh` to point users to the real update/regenerate flow instead of the removed `--regenerate` flag.
- [x] Step 4: Align public documentation in `README.md` with the actual CLI surface, including flags, test coverage, and any operational caveats that remain after the runtime fixes.
- [x] Step 5: Expand `tests/integration.sh` to cover the supported JSON fallback mode without `jq`, and wire the intended integration coverage into `package.json` test scripts.
- [x] Step 6: Run smoke and integration verification for the updated paths and ensure the new failure/help messages are observable and deterministic.

## Acceptance Criteria
- [x] Running `bash bin/ai-setup.sh --audit` or another unsupported flag exits non-zero with a clear unsupported-flag message and does not continue into install flow.
- [x] A fresh run on a system with Node.js but no `jq` can still pass the supported setup/test path covered by `tests/integration.sh`.
- [x] No file in the maintained docs or generated recovery hints instructs users to run `npx @onedot/ai-setup --regenerate`.
- [x] `npm test` covers both smoke and integration checks, or the README explicitly documents the exact narrower scope if integration remains separate.

## Files to Modify
- `bin/ai-setup.sh` - harden flag parsing and remove direct `jq` assumptions in entry flow
- `lib/generate.sh` - fix stale regenerate remediation hints
- `README.md` - align CLI, fallback, and test documentation with real behavior
- `AGENTS.md` - remove invalid regenerate guidance for this repo
- `templates/AGENTS.md` - remove invalid regenerate guidance for installed projects
- `tests/integration.sh` - verify Node-only JSON fallback path
- `package.json` - wire intended verification commands

## Out of Scope
- Adding new installer features beyond consistency fixes for the current documented surface
- Refactoring the broader update/migration architecture
- Changing template content unrelated to flag handling, fallback behavior, or recovery guidance
