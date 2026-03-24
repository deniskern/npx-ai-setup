# Spec: Secure JSON layer — eliminate shell injection in Node.js fallbacks

> **Spec ID**: 568 | **Created**: 2026-03-24 | **Status**: in-progress | **Complexity**: medium | **Branch**: —

## Goal
Replace shell variable interpolation in inline Node.js code with `process.argv` passing to eliminate injection vectors in json.sh and setup.sh.

## Context
All 5 Node.js fallback functions in `lib/json.sh` embed shell variables directly in JS code (e.g. `'$file'`), enabling injection if values contain quotes or special chars. `lib/global-settings.sh:68` already demonstrates the safe pattern: single-quoted heredoc + `process.argv`. The fix applies this proven pattern consistently. API signatures remain unchanged — only internals change.

### Verified Assumptions
- Node.js fallback must be preserved (not all systems have jq) — Evidence: `lib/cli-tools.sh` | Confidence: High | If Wrong: could simplify to jq-only
- Safe pattern: `process.argv` + single-quoted heredoc — Evidence: `lib/global-settings.sh:68-84` | Confidence: High | If Wrong: need alternative escaping
- `_json_merge $merge` is most critical vector (raw JSON string interpolated) — Evidence: `lib/json.sh:56` | Confidence: High | If Wrong: lower severity
- API unchanged, only internals — Evidence: all callers use `_json_read FILE PATH` signatures | Confidence: High | If Wrong: breaking change

## Steps
- [x] Step 1: Rewrite `_json_read()` Node fallback — pass `$file` and `$keys` via `process.argv[1]`/`[2]`
- [x] Step 2: Rewrite `_json_valid()` Node fallback — pass `$file` via `process.argv[1]`
- [x] Step 3: Rewrite `_json_merge()` Node fallback — pass `$target` and `$merge` via `process.argv[1]`/`[2]`
- [x] Step 4: Rewrite `_json_build_metadata()` Node fallback — pass `$ver`, `$inst`, `$upd` via argv
- [x] Step 5: Rewrite `_json_set_file()` Node fallback — pass `$key` and `$val` via `process.argv`
- [ ] Step 6: Fix `setup.sh:252-260` Node fallback — pass `$settings` via `process.argv`
- [ ] Step 7: Run smoke tests (`tests/smoke.sh`) and verify json operations work with both jq and node
- [ ] Step 8: Sync templates (`cp lib/json.sh templates/lib/json.sh` etc.)

## Acceptance Criteria

### Truths
- [ ] `grep -n "'\$" lib/json.sh` returns zero matches (no shell interpolation in Node code)
- [ ] `tests/smoke.sh` passes
- [ ] File paths containing single quotes don't break `_json_read`

### Key Links
- [ ] `lib/json.sh` Node fallbacks use `process.argv` exclusively (no `'$var'` pattern)
- [ ] `lib/setup.sh:252-260` Node fallback uses `process.argv` for `$settings`

## Files to Modify
- `lib/json.sh` — rewrite all 5 Node.js fallback blocks
- `lib/setup.sh` — rewrite 1 Node.js fallback in `customize_settings_for_stack()`
- `templates/lib/json.sh` — sync from lib/json.sh
- `templates/lib/setup.sh` — sync from lib/setup.sh

## Out of Scope
- Removing Node.js fallback entirely (jq-only migration)
- Fixing callers of `_json_*` functions (they pass safe values)
- Other Node.js inline code in global-settings.sh (already safe)
