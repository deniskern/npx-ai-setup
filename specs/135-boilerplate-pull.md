# Spec: Boilerplate Pull via gh CLI

> **Spec ID**: 135 | **Created**: 2026-03-21 | **Status**: in-review | **Branch**: main

## Goal
Let fresh installs pull system-specific config (skills, rules, MCP) directly from boilerplate repos via `gh` CLI.

## Context
After system code removal (Spec 115), ai-setup no longer bundles Shopify/Nuxt/etc. config. For new projects not created from a GitHub Template, users need a way to pull system config from the canonical boilerplate repo. `gh api` fetches files without cloning the entire repo. Requires Spec 115 completed. Part 3 of 3.

## Steps
- [x] Step 1: Create `lib/boilerplate.sh` with `pull_boilerplate_files()` function. Uses `gh api repos/<org>/<repo>/contents/<path>` to fetch files. Decodes base64 content and writes to target paths.
- [x] Step 2: Add `SYSTEM_BOILERPLATES` mapping to `lib/core.sh` (shopify→sp-shopify-boilerplate, shopware→sw-shopware-boilerplate, nuxt→sb-nuxt-boilerplate, next→sb-next-boilerplate, storyblok→sb-storyblok-boilerplate).
- [x] Step 3: Add interactive system selector to fresh install flow in `bin/ai-setup.sh` — "Pull system config? (Shopify / Shopware / Nuxt / Next / Storyblok / Skip)". Only shown when no system-specific files detected.
- [x] Step 4: Define which paths to pull: `.claude/skills/*/SKILL.md`, `.claude/rules/<system>*.md`, `.mcp.json` (merge, not overwrite).
- [x] Step 5: Add `gh` CLI availability check — if not installed, show manual instructions instead of failing.

## Acceptance Criteria
- [x] Fresh install offers system selection when no system config detected
- [x] `gh api` fetches files from correct boilerplate repo
- [x] `.mcp.json` is merged (not overwritten) when pulling
- [x] Graceful fallback when `gh` CLI is not available

## Files to Modify
- `lib/boilerplate.sh` — NEW: pull logic + system selector
- `lib/core.sh` — add SYSTEM_BOILERPLATES mapping
- `bin/ai-setup.sh` — wire boilerplate pull into fresh install

## Out of Scope
- Boilerplate repo modifications
- Pull during updates (only fresh install)
- Non-gh authentication methods
