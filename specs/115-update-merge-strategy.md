# Spec: Boilerplate-First Architecture with Release Migrations

> **Spec ID**: 115 | **Created**: 2026-03-21 | **Status**: draft | **Branch**: —

<!-- Absorbs Spec 077 (Base/System Split). System-specific config moves to boilerplate repos. Updates via release migrations. System setup via gh pull from boilerplate. -->

## Goal
Remove system-specific code from ai-setup. Fresh installs pull system config from boilerplate repos via `gh` CLI. Updates apply incremental migrations instead of template overwrite.

## Context
Projects are either created from GitHub Template repos (already have system config) or are existing projects that need system config added. Instead of bundling system-specific code in ai-setup, we pull it directly from the boilerplate repos via `gh` CLI (available on all team machines). This keeps system config in one authoritative place (the boilerplate) and eliminates duplication.

## Architecture

### Fresh Install Flow
```
npx @onedot/ai-setup
├── 1. Copy base templates (hooks, commands, agents, settings, rules)
├── 2. Interactive system selector:
│     "Which system? (Shopify / Shopware / Nuxt / Next / Storyblok / Skip)"
├── 3. If system selected: pull system files from boilerplate via gh CLI
│     gh api repos/<org>/<boilerplate>/contents/.claude/skills → copy
│     gh api repos/<org>/<boilerplate>/contents/.claude/rules  → merge
│     gh api repos/<org>/<boilerplate>/contents/.mcp.json      → merge
├── 4. Write version + checksums to .ai-setup.json
└── 5. Auto-Init (Claude generates CLAUDE.md, STACK.md, ARCHITECTURE.md)
```

### Update Flow (`.ai-setup.json` exists)
```
npx @onedot/ai-setup
├── 1. Read version from .ai-setup.json
├── 2. Find migrations > installed version
├── 3. Apply each migration sequentially
└── 4. Update version in .ai-setup.json
```

### Boilerplate-Project Flow (from GitHub Template)
```
npx @onedot/ai-setup
├── 1. Detect .ai-setup.json → update mode
├── 2. Apply migrations only
└── 3. Skip system pull (already present from template)
```

### System → Boilerplate Mapping
```bash
SYSTEM_BOILERPLATES=(
  "shopify:onedot-digital-crew/sp-shopify-boilerplate"
  "shopware:onedot-digital-crew/sw-shopware-boilerplate"
  "nuxt:onedot-digital-crew/sb-nuxt-boilerplate"
)
```

### Files Pulled from Boilerplate
- `.claude/skills/*/SKILL.md` — system-specific skills
- `.claude/rules/<system>*.md` — system-specific rules (e.g. liquid-performance.md)
- `.mcp.json` — system MCP servers (merged, not overwritten)

### Migration Helpers
- `_add_file <src> <target>` — install only if target missing
- `_update_file <src> <target>` — overwrite only if not user-modified
- `_patch_line <file> <old> <new>` — sed-style replace, skip if old not found
- `_settings_add_permission <pattern>` — add to allow list if not present
- `_settings_add_hook <event> <hook>` — add hook entry if not present
- `_remove_file <target>` — delete if matches template checksum

## Steps
- [ ] Step 1: Create `lib/migrations/` dir and migration runner in `lib/update.sh` with helper functions.
- [ ] Step 2: Create `pull_boilerplate_files()` in new `lib/boilerplate.sh` — uses `gh api` to fetch `.claude/skills/`, `.claude/rules/`, `.mcp.json` from a given repo. Includes interactive system selector.
- [ ] Step 3: Add `SYSTEM_BOILERPLATES` mapping to `lib/core.sh`. Wire `pull_boilerplate_files()` into fresh install flow in `bin/ai-setup.sh`.
- [ ] Step 4: Delete `lib/systems/` (6 files). Remove `load_system_plugins()`, `--system` flag, system-guarded calls.
- [ ] Step 5: Simplify `generate.sh` — remove system-specific prompt variables. Claude reads project directly.
- [ ] Step 6: Create first migration `lib/migrations/1.4.0.sh` with all changes since v1.3.5.
- [ ] Step 7: Modify update flow in `bin/ai-setup.sh` — when `.ai-setup.json` version < current, run migrations instead of full template copy.
- [ ] Step 8: Clean up remaining system refs in `core.sh`, `setup-skills.sh`, `detect.sh`.
- [ ] Step 9: Syntax-check + E2E test: fresh install with system pull + update in boilerplate project.

## Acceptance Criteria
- [ ] Fresh install offers interactive system selection and pulls from boilerplate
- [ ] `gh` CLI is used for pull (no git clone)
- [ ] Update applies only migrations, never full template copy
- [ ] `lib/systems/` does not exist
- [ ] `--system` flag is removed
- [ ] Boilerplate projects are detected (`.ai-setup.json` present) and only get migrations

## Files to Modify
- `lib/boilerplate.sh` — new: system selector + gh pull logic
- `lib/migrations/` — new: migration files + runner
- `lib/update.sh` — migration runner integration
- `bin/ai-setup.sh` — new fresh install flow, remove --system
- `lib/systems/*.sh` — delete all
- `lib/_loader.sh` — remove load_system_plugins()
- `lib/generate.sh` — remove system prompts
- `lib/core.sh` — add SYSTEM_BOILERPLATES, remove VALID_SYSTEMS
- `lib/setup-skills.sh` — remove system functions
- `lib/detect.sh` — remove/simplify system detection

## Out of Scope
- Boilerplate repo modifications (separate per-repo task)
- Rollback mechanism for migrations
- Non-gh authentication (assumes gh auth login done)

## Complexity: high
