# Spec: Aggressive .claudeignore Template

> **Spec ID**: 106 | **Created**: 2026-03-16 | **Status**: in-review | **Branch**: — | **Complexity**: low

## Goal
Expand the `.claudeignore` template from 3 entries to a comprehensive blocklist that prevents Claude from indexing known token-wasting files.

## Context
Current `.claudeignore` has only `node_modules/`, `dist/`, `.ai-setup-backup/`. Claude Code reads `.claudeignore` natively to exclude files from auto-indexing — zero runtime cost. Dozens of common token-wasters (source maps, binary assets, lock files, build caches, framework output dirs) are missing, causing unnecessary token consumption during codebase exploration.

## Steps
- [x] Step 1: Expand `templates/.claudeignore` with universal patterns — build output (`.next/`, `.nuxt/`, `.output/`, `build/`, `coverage/`, `.turbo/`), caches (`.cache/`, `.parcel-cache/`, `.eslintcache`), source maps (`*.map`), binary assets (`*.woff2`, `*.ttf`, `*.ico`, `*.png`, `*.jpg`, `*.gif`, `*.svg`, `*.mp4`), vendor dirs (`vendor/`, `public/bundles/`)
- [x] Step 2: Add lock files to `.claudeignore` (`package-lock.json`, `pnpm-lock.yaml`, `yarn.lock`, `bun.lockb`, `composer.lock`) — these are already protected from edits by `protect-files.sh` but still get indexed
- [x] Step 3: Add SYSTEM-specific patterns via `lib/setup.sh` — append framework-specific entries (shopware: `var/cache/`, `public/bundles/`; nuxt: `.nuxt/`; next: `.next/`; laravel: `bootstrap/cache/`, `storage/framework/`) when installing `.claudeignore`
- [x] Step 4: Preserve existing user entries — if `.claudeignore` already exists, merge new patterns without duplicating

## Acceptance Criteria
- [x] `.claudeignore` contains 30+ patterns covering builds, caches, maps, binaries, locks
- [x] System-specific patterns added when SYSTEM is detected
- [x] Existing user-added entries preserved on re-run (idempotent merge)

## Files to Modify
- `templates/.claudeignore` — expand with universal patterns
- `lib/setup.sh` — append system-specific patterns during install

## Out of Scope
- `.repomixignore` (covered by Spec 104)
- Runtime hooks or API calls (this is a static file)
