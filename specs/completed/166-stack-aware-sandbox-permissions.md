# Spec 166 — Stack-Aware Sandbox Permissions

**Status:** completed

## Goal
Make the `permissions.deny` list in `.claude/settings.json` framework-aware so that
pre-commit hooks (ESLint, build tools) can run inside the Claude Code sandbox.

## Context
- `templates/claude/settings.json` has a static deny list blocking `Read(.nuxt/**)`, `Read(.next/**)`, `Read(.env*)`, etc.
- These entries become Bash sandbox filesystem restrictions — subprocesses (git hooks → ESLint) also can't read them.
- Nuxt ESLint imports from `.nuxt/eslint.config.mjs` → blocked → pre-commit hook fails.
- `SELECTED_SYSTEM` is set in `select_boilerplate_system()` (ai-setup.sh:111), but `install_settings()` runs earlier (line 94).
- Framework detection already exists in `boilerplate.sh:170` (`shopify shopware nuxt next storyblok`).

## Steps

### Step 1 — Add `customize_settings_for_stack()` to `lib/setup.sh` ✅
New function that runs AFTER `select_boilerplate_system`. Uses `SELECTED_SYSTEM` to
remove framework-specific entries from `.claude/settings.json` deny list via `jq`:
- **nuxt:** remove `Read(.nuxt/**)`, `Read(.output/**)`
- **next:** remove `Read(.next/**)`
- No-op for other frameworks or empty `SELECTED_SYSTEM`.

### Step 2 — Call from `bin/ai-setup.sh` after `select_boilerplate_system` ✅
Insert `customize_settings_for_stack` call at line ~112 (after `select_boilerplate_system`).

### Step 3 — Auto-detect framework when `SELECTED_SYSTEM` is empty ✅ (merged into Step 1)
For update runs where the user skips framework selection, detect from existing files:
- `nuxt.config.*` → nuxt
- `next.config.*` → next
Fallback: no customization (keep static deny list).

### Step 4 — Add smoke test case ✅
Extend `tests/smoke.sh`: after a simulated nuxt setup, verify that `.claude/settings.json`
does NOT contain `Read(.nuxt/**)` in the deny list.

### Step 5 — Document in WORKFLOW-GUIDE ✅
Add a note that sandbox permissions are auto-adjusted per framework. If hooks still fail,
users can commit with `! git commit -m "msg"`.

## Acceptance Criteria

### Truths
- `customize_settings_for_stack` is idempotent — running twice produces the same result
- Static deny list in template stays unchanged (generic defaults)
- Frameworks without special needs get no modification

### Artifacts
- `lib/setup.sh` contains `customize_settings_for_stack()` function
- `bin/ai-setup.sh` calls it after `select_boilerplate_system`
- `tests/smoke.sh` verifies nuxt deny-list customization

### Scenarios
- WHEN framework is nuxt THEN `.claude/settings.json` deny list omits `Read(.nuxt/**)`
- WHEN framework is next THEN `.claude/settings.json` deny list omits `Read(.next/**)`
- WHEN no framework selected AND `nuxt.config.ts` exists THEN auto-detects and customizes
- WHEN no framework detected THEN deny list stays unchanged

## Files to Modify
- `lib/setup.sh` — add `customize_settings_for_stack()`
- `bin/ai-setup.sh` — call after `select_boilerplate_system`
- `tests/smoke.sh` — add framework-aware deny test

## Out of Scope
- Removing `Read(.env*)` from deny (security concern — separate decision needed)
- Modifying the template `settings.json` itself (stays generic)
- Sandbox network host customization per framework
