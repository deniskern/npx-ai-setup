# Spec: Fast --patch flag for syncing specific template files

> **Spec ID**: 093 | **Created**: 2026-03-15 | **Status**: in-progress | **Complexity**: medium | **Branch**: —

## Goal
Add a `--patch <pattern>` flag to `bin/ai-setup.sh` that copies only matching template files to the project without running the full update flow — for quick syncing of specific files during development.

## Context
When iterating on templates (e.g. `spec-work.md`, `SKILL.md`), running the full update (version check, menu, scan all templates) is slow. A patch command matches templates by filename pattern and copies them directly. Uses the existing `TEMPLATE_MAP` + skills map; skips checksums, prompts, and regeneration. Requires `.ai-setup.json` to exist (project must be initialized).

## Steps
- [x] Step 1: Add `run_patch()` to `lib/update.sh` — accepts a pattern string, filters all template mappings (TEMPLATE_MAP + SHOPIFY_SKILLS_MAP + spec skills), copies matching files directly to their target paths, prints each copied file, exits 0
- [x] Step 2: Add `--patch <pattern>` flag parsing to `bin/ai-setup.sh` — detect flag, call `run_patch "$pattern"`, exit. Must run before the version-check/menu flow.
- [x] Step 3: Document `--patch` flag in `README.md` under the Flags section (Commands in templates/CLAUDE.md is auto-generated; README.md is the canonical flags reference)

## Acceptance Criteria
- [ ] `lib/update.sh` contains `run_patch()` function that filters by pattern and copies matching templates
- [ ] `bin/ai-setup.sh` handles `--patch <pattern>` flag and routes to `run_patch()`
- [ ] `templates/CLAUDE.md` documents the `--patch` flag
- [ ] Smoke tests pass (`./tests/smoke.sh`)

## Files to Modify
- `lib/update.sh` — add `run_patch()` function
- `bin/ai-setup.sh` — add `--patch` flag parsing
- `templates/CLAUDE.md` — document flag in Commands section

## Out of Scope
- Partial skills map builds (uses already-built TEMPLATE_MAP)
- Interactive confirmation prompts (always overwrites)
- Backup creation (raw copy, no backup)
- Syncing to multiple projects at once
