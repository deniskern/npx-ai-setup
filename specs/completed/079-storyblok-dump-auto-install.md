# Spec 079 — Storyblok Dump Script Auto-Install

**Status:** completed
**Created:** 2026-03-12

## Goal

Automatically install a `storyblok-dump` script into Storyblok projects during ai-setup, giving Claude a local cache of all stories for token-efficient MCP workflows.

## Context

The storyblok-dump script fetches all Storyblok stories (draft version) and writes a token-optimized JSONL file with a summary header. This eliminates blind MCP roundtrips: Claude reads the dump for IDs/slugs, then makes only targeted `storyblok_get_story(id)` calls.

ai-setup already detects Storyblok projects (`detect.sh:31`) and installs system-specific skills (`generate.sh:964`). The `install_shopify_skills()` pattern in `lib/setup.sh:220` serves as the model for system-specific file installation.

## Steps

- [x] **1. Create template script** `templates/scripts/storyblok-dump.ts` — the TSX script that fetches all stories via Storyblok CDN API and writes JSONL to `scripts/storyblok-dump.json`. Supports `STORYBLOK_TOKEN` and `STORYBLOK_REGION` from `.env`.
- [x] **2. Add `install_storyblok_scripts()` to `lib/setup.sh`** — following the `install_shopify_skills()` pattern. When `SYSTEM` contains `storyblok`: (a) copy `storyblok-dump.ts` to target `scripts/`, (b) add `"storyblok-dump": "tsx scripts/storyblok-dump.ts"` to package.json scripts if not present.
- [x] **3. Add template mapping** for the storyblok-dump script in the appropriate mapping array (scripts/ excluded from TEMPLATE_MAP in core.sh, handled by install_storyblok_scripts explicitly).
- [x] **4. Call `install_storyblok_scripts`** from `bin/ai-setup.sh` after `install_shopify_skills` (line ~145).
- [x] **5. Add `scripts/storyblok-dump.json` to `.gitignore` template** — the dump output should not be committed.
- [x] **6. Test idempotency** — jq check prevents duplicate npm script entry; idempotency preserved.

## Acceptance Criteria

- [x] `templates/scripts/storyblok-dump.ts` exists and matches the provided script
- [x] Running ai-setup on a Storyblok project copies the script to `scripts/storyblok-dump.ts`
- [x] `package.json` gets `storyblok-dump` script entry pointing to `tsx scripts/storyblok-dump.ts`
- [x] Running setup twice does not duplicate the script entry
- [x] Non-Storyblok projects are unaffected (function exits early)
- [x] `scripts/storyblok-dump.json` is gitignored
- [x] Script handles missing `STORYBLOK_TOKEN` gracefully (exits with error message)

## Files to Modify

- `templates/scripts/storyblok-dump.ts` — **create** (new template)
- `lib/setup.sh` — add `install_storyblok_scripts()` function
- `bin/ai-setup.sh` — call `install_storyblok_scripts` in install flow

## Out of Scope

- WORKFLOW-GUIDE documentation (covered by spec 078)
- Shopify equivalent dump script
- Component-level content extraction (only story metadata)
