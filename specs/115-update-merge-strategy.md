# Spec: Update & Merge Strategy — Boilerplate-First Architecture

> **Spec ID**: 115 | **Created**: 2026-03-21 | **Status**: draft | **Branch**: —

<!-- Absorbs Spec 077 (Base/System Split). The Two-Mode idea is replaced by a Boilerplate-First approach where system-specific config lives in boilerplate repos, not in ai-setup. -->

## Goal
Restructure ai-setup so system-specific config lives in boilerplate repos, not in the package. ai-setup becomes a pure base layer that merges updates without overwriting project-specific or boilerplate-provided files.

## Context
Projects are created from boilerplate repos (sp-shopify-boilerplate, sb-nuxt-boilerplate, etc.) that already contain system-specific `.claude/skills/`, rules, agents, settings, and MCP config. Today ai-setup duplicates this: `lib/systems/*.sh` installs the same skills the boilerplate already provides, and `_install_or_update_file()` can overwrite boilerplate customizations. The fix: ai-setup provides only the generic base, boilerplates own system-specific config, and the update flow merges intelligently.

**From Spec 077:** The original Two-Mode Split (base-only vs. system-only runs) was rejected as over-engineering. Instead, every run is a combined run that respects what's already present.

## Open Questions (to resolve before implementation)
1. Should `--system` flag be deprecated or kept as fallback for non-boilerplate projects?
2. Should ai-setup detect boilerplate origin (e.g. via `.ai-setup.json` or git remote)?
3. How should settings.json merge work — deep merge, or section-by-section?
4. Should `lib/systems/*.sh` be removed entirely, or kept as optional fallback?
5. What happens when ai-setup adds a new command that the boilerplate doesn't have yet?
6. How does `--regenerate` work without system-specific prompts (CTX_SHOPWARE etc.)?

## Acceptance Criteria
- [ ] Running `npx @onedot/ai-setup` in a boilerplate-based project preserves all user/boilerplate modifications
- [ ] New files from ai-setup updates are added without conflict
- [ ] Updated template files are offered as diff or skipped, not silently applied
- [ ] System-specific config is documented as boilerplate responsibility
- [ ] Strategy is documented in WORKFLOW-GUIDE.md

## Files to Modify
- `bin/ai-setup.sh` — simplify flow, potentially remove `--system`
- `lib/setup.sh` — improve `_install_or_update_file()` merge logic
- `lib/systems/*.sh` — deprecate or remove
- `lib/generate.sh` — decouple from system-specific prompts
- `lib/core.sh` — remove system-specific maps if deprecated

## Out of Scope
- Auto-pull from boilerplate repos via GitHub API (future feature)
- Remote system plugin discovery
- Boilerplate repo modifications (separate task per boilerplate)

## Complexity: high
