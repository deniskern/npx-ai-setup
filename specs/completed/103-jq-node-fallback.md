# Spec: jq-to-Node Fallback Wrapper

> **Spec ID**: 103 | **Created**: 2026-03-16 | **Status**: completed | **Branch**: — | **Complexity**: high

## Goal
Eliminate the hard jq dependency by creating a `_json` wrapper function that uses jq when available and falls back to Node.js one-liners when not.

## Context
30+ jq calls across 5 shell modules. jq is not pre-installed on many systems (macOS ships without it, CI images vary). Node.js (>= 18) is already a prerequisite for npx. A wrapper reduces installation friction without rewriting every call site at once — migration can happen incrementally.

## Steps
- [x] Step 1: Create `lib/json.sh` with `_json` wrapper function — detects jq availability once at load time, exports `_JSON_CMD` (jq or node); provides `_json_read` (extract field), `_json_merge` (merge objects), `_json_build` (construct JSON from args)
- [x] Step 2: Replace 5 most common jq patterns in `lib/core.sh` with `_json_read` / `_json_build` calls (version read, metadata write, ai-setup.json parsing)
- [x] Step 3: Replace jq calls in `lib/detect.sh` and `lib/generate.sh` dependency extraction with `_json_read`
- [x] Step 4: Replace jq calls in `lib/plugins.sh` settings merge with `_json_merge`
- [x] Step 5: Replace jq calls in `lib/setup.sh` storyblok script injection with `_json_merge`
- [x] Step 6: Add `lib/json.sh` to `_loader.sh` source chain
- [ ] Step 7: Test: run setup on a system without jq installed, verify complete setup succeeds with Node.js fallback
- [ ] Step 8: Add smoke test asserting `lib/json.sh` exists and exports `_json_read`

## Acceptance Criteria
- [ ] Setup completes successfully on a system without jq (Node.js fallback used)
- [ ] Setup still uses jq when available (faster, preferred path)
- [ ] All existing functionality preserved (metadata, detection, plugins, skills cache)
- [ ] `_json` wrapper adds < 50 lines of shell code

## Files to Modify
- `lib/json.sh` — create new module with fallback wrapper
- `lib/_loader.sh` — add `json.sh` to source chain
- `lib/core.sh` — replace jq calls with wrapper
- `lib/detect.sh` — replace jq calls with wrapper
- `lib/generate.sh` — replace jq calls with wrapper
- `lib/plugins.sh` — replace jq calls with wrapper
- `lib/setup.sh` — replace jq calls with wrapper

## Out of Scope
- Removing jq entirely from the codebase (it remains the preferred path when available)
- Replacing jq in templates or hooks (only lib/ shell modules)
