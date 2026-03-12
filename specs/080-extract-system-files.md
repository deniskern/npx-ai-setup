# Spec 080 — Extract System-Specific Logic into lib/systems/*.sh

**Status:** draft
**Created:** 2026-03-12

## Goal

Move all system-specific functions and logic from `generate.sh`, `setup.sh`, and `detect.sh` into per-system files under `lib/systems/`. The install flow, CLI interface, and user experience stay identical — this is a pure code-organization refactor.

## Context

`generate.sh` (1000+ lines) and `setup.sh` (300+ lines) contain system-specific blocks scattered throughout: Shopware context gathering, Shopify skill injection, system-skills switch-case, Shopware plugin detection. As more systems get features (e.g. Storyblok dump from spec 079), these files grow harder to navigate and debug. Extracting per-system files makes it easy to find and modify system-specific code without touching shared logic.

**What moves:**
- `detect.sh`: `detect_shopware_type()` → `lib/systems/shopware.sh`
- `generate.sh:13-190`: Shopware context functions → `lib/systems/shopware.sh`
- `generate.sh:922-1011`: System-skills switch-case → split into per-system files
- `setup.sh:303-310`: Agent skill injection (Shopify/Shopware) → respective system files
- `setup.sh:220-236`: `install_shopify_skills()` → `lib/systems/shopify.sh`
- `core.sh:56-67`: `SHOPIFY_SKILLS_MAP` → `lib/systems/shopify.sh`

**What stays the same:**
- `bin/ai-setup.sh` install flow and call order
- `--system` flag behavior
- `detect_system()` in `detect.sh` (sets `$SYSTEM`, used by all systems)
- Template mapping and update logic

## Steps

- [ ] **1. Create `lib/systems/` directory** and a loader function in `detect.sh` that sources `lib/systems/${SYSTEM}.sh` after `detect_system()` runs (with fallback no-op if file doesn't exist).
- [ ] **2. Create `lib/systems/shopify.sh`** — move `SHOPIFY_SKILLS_MAP`, `install_shopify_skills()`, and Shopify agent-injection block. Export functions with same names so callers don't change.
- [ ] **3. Create `lib/systems/shopware.sh`** — move `detect_shopware_type()`, `gather_shopware_context()`, `setup_shopware_mcp()`, Shopware agent-injection block, and Shopware system-skills entries.
- [ ] **4. Create `lib/systems/storyblok.sh`** — stub file with Storyblok system-skills entry (extracted from generate.sh switch-case). Ready for spec 079 to add `install_storyblok_scripts()`.
- [ ] **5. Refactor `generate.sh`** — replace system-skills switch-case with calls to per-system functions. Remove moved Shopware functions. Keep `$SYSTEM` in context-generation prompts (that's generic).
- [ ] **6. Refactor `setup.sh` and `core.sh`** — remove moved functions/maps. Add `source` calls if not handled by the loader.
- [ ] **7. Run `bash tests/smoke.sh`** — verify all files parse, functions exist, no syntax errors.

## Acceptance Criteria

- [ ] `lib/systems/shopify.sh`, `shopware.sh`, `storyblok.sh` exist
- [ ] Running `npx @onedot/ai-setup` produces identical output before and after refactor
- [ ] `generate.sh` no longer contains Shopware-specific function definitions
- [ ] `setup.sh` no longer contains `SHOPIFY_SKILLS_MAP` or `install_shopify_skills()`
- [ ] `core.sh` no longer contains `SHOPIFY_SKILLS_MAP`
- [ ] All system-specific skill lists are in their respective system files
- [ ] Smoke tests pass
- [ ] `--system shopify` and `--system shopware` still work correctly

## Files to Modify

- `lib/systems/shopify.sh` — **create** (extracted from core.sh + setup.sh)
- `lib/systems/shopware.sh` — **create** (extracted from generate.sh + detect.sh + setup.sh)
- `lib/systems/storyblok.sh` — **create** (stub, extracted from generate.sh)
- `lib/detect.sh` — add system-file loader after detect_system()
- `lib/generate.sh` — remove system-specific functions, use per-system calls
- `lib/setup.sh` — remove moved functions
- `lib/core.sh` — remove SHOPIFY_SKILLS_MAP

## Out of Scope

- Changing CLI interface or adding new commands
- Two-mode architecture (spec 077)
- Storyblok dump script (spec 079)
- Nuxt/Next/Laravel system files (create when needed)

## Complexity: medium
Touches 7 files but changes are mechanical (move, not rewrite). Run with Sonnet.
