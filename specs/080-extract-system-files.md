# Spec 080 — Extract System-Specific Logic into lib/systems/*.sh

> **Spec ID**: 080 | **Created**: 2026-03-12 | **Status**: in-progress | **Branch**: —

## Goal
Move all remaining system-specific functions and data from shared modules into per-system files under `lib/systems/`. Pure code-organization refactor — identical output before and after.

## Context
Spec 111 extracted Shopware functions to `lib/shopware.sh` and skills functions to `lib/setup-skills.sh`. But system-specific logic is still scattered: `SHOPIFY_SKILLS_MAP` in core.sh, `detect_shopware_type()` in detect.sh, system-skills switch-case (60 LOC) in generate.sh, hardcoded Shopify/Shopware agent injection in setup-skills.sh. This spec completes the extraction into `lib/systems/` with a loader pattern.

## Steps
- [x] Step 1: Create `lib/systems/` directory. Add loader function `load_system_plugins()` in `lib/_loader.sh` that sources `lib/systems/${SYSTEM}.sh` if it exists (silent no-op otherwise). Call it from `bin/ai-setup.sh` after `detect_system()` and after system validation.
- [x] Step 2: Create `lib/systems/shopware.sh` — move `lib/shopware.sh` content here + `detect_shopware_type()` from detect.sh. Add `system_get_default_skills()` returning the Shopware skills array from generate.sh:709-752. Remove old `lib/shopware.sh`.
- [x] Step 3: Create `lib/systems/shopify.sh` — move `SHOPIFY_SKILLS_MAP` from core.sh, Shopify agent-injection block from `_inject_agent_skills()` in setup-skills.sh, and Shopify system-skills entries from generate.sh. Add `system_get_default_skills()`.
- [x] Step 4: Create `lib/systems/nuxt.sh`, `next.sh`, `laravel.sh`, `storyblok.sh` — each with `system_get_default_skills()` containing the respective skills arrays from generate.sh:709-758.
- [ ] Step 5: Refactor `lib/generate.sh` — replace the system-skills switch-case (lines 709-758) with a call to `system_get_default_skills` (if function exists). Remove `SHOPIFY_SKILLS_MAP` references.
- [ ] Step 6: Refactor `lib/setup-skills.sh` — replace hardcoded Shopify/Shopware blocks in `_inject_agent_skills()` with a `system_inject_agent_skills()` call dispatched from the system plugin. Remove `SHOPIFY_SKILLS_MAP` from core.sh.
- [ ] Step 7: Syntax-check all files (`bash -n lib/systems/*.sh lib/*.sh`), run E2E test with `--system shopware` and `--system shopify`.

## Acceptance Criteria
- [ ] `lib/systems/shopware.sh`, `shopify.sh`, `nuxt.sh`, `next.sh`, `laravel.sh`, `storyblok.sh` exist
- [ ] `generate.sh` contains no system-skills switch-case
- [ ] `core.sh` contains no `SHOPIFY_SKILLS_MAP`
- [ ] `setup-skills.sh:_inject_agent_skills()` contains no hardcoded system names
- [ ] `detect.sh` contains no `detect_shopware_type()`
- [ ] `--system shopware` and `--system shopify` produce identical output as before

## Files to Modify
- `lib/_loader.sh` — add `load_system_plugin()`
- `lib/systems/shopware.sh` — new (from lib/shopware.sh + detect.sh + generate.sh)
- `lib/systems/shopify.sh` — new (from core.sh + setup-skills.sh + generate.sh)
- `lib/systems/nuxt.sh` — new (from generate.sh)
- `lib/systems/next.sh` — new (from generate.sh)
- `lib/systems/laravel.sh` — new (from generate.sh)
- `lib/systems/storyblok.sh` — new (from generate.sh)
- `lib/generate.sh` — remove system-skills switch-case
- `lib/setup-skills.sh` — remove hardcoded system blocks from _inject_agent_skills
- `lib/core.sh` — remove SHOPIFY_SKILLS_MAP
- `lib/detect.sh` — remove detect_shopware_type()
- `lib/shopware.sh` — delete (moved to systems/)
- `bin/ai-setup.sh` — replace `source_lib "shopware.sh"` with `load_system_plugin` call

## Out of Scope
- Two-mode architecture (spec 077)
- New system detection logic
- Changing CLI interface

## Complexity: medium
