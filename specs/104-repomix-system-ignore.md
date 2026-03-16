# Spec: Repomix System-Specific Ignore Patterns

> **Spec ID**: 104 | **Created**: 2026-03-16 | **Status**: draft | **Branch**: — | **Complexity**: low

## Goal
Generate a `.repomixignore` file with framework-specific exclusions so repomix snapshots stay within token budgets.

## Context
`repomix --compress` helps but large frameworks (Shopware, Nuxt, Laravel) still produce oversized snapshots due to caches, compiled assets, and vendor dirs. The SYSTEM variable is already detected — we can map it to ignore patterns automatically.

## Steps
- [ ] Step 1: Create `templates/repomixignore-patterns.sh` — associative array mapping each SYSTEM to ignore globs (e.g. shopware: `var/cache/`, `public/bundles/`; nuxt: `.nuxt/`, `.output/`; laravel: `bootstrap/cache/`, `storage/`)
- [ ] Step 2: In `lib/setup.sh` `generate_repomix_snapshot()` — source patterns file, write `.repomixignore` from base patterns + SYSTEM-specific patterns before running repomix
- [ ] Step 3: Add `.repomixignore` to gitignore (machine-local artifact)
- [ ] Step 4: Test: run setup with `--system shopware`, verify `.repomixignore` contains shopware-specific globs

## Acceptance Criteria
- [ ] `.repomixignore` is generated with system-specific patterns
- [ ] Snapshot size decreases measurably for Shopware/Nuxt/Laravel projects
- [ ] Base patterns (node_modules, .git, dist) always included regardless of system

## Files to Modify
- `templates/repomixignore-patterns.sh` — create pattern definitions per system
- `lib/setup.sh` — generate `.repomixignore` before snapshot

## Out of Scope
- Custom user-defined ignore patterns (manual `.repomixignore` edits are preserved)
- Changing repomix config format (stays XML compressed)
