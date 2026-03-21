# Spec: Split generate.sh and setup.sh into focused modules

> **Spec ID**: 111 | **Created**: 2026-03-21 | **Status**: in-progress | **Branch**: —

## Goal
Extract logically independent code from the two largest lib modules (generate.sh 1081 LOC, setup.sh 979 LOC) into focused sub-modules for better maintainability.

## Context
The lib/ directory already has 12 modules, but generate.sh and setup.sh grew into catch-alls. generate.sh contains ~270 LOC of Shopware-specific code unrelated to generation. setup.sh mixes template installation with skills management, compatibility layers, and config tooling. Extracting these into focused modules makes each file single-purpose and easier to navigate.

## Steps
- [x] Step 1: Extract `gather_shopware_context()` + `setup_shopware_mcp()` from `lib/generate.sh` → new `lib/shopware.sh`. Add `source_lib "shopware.sh"` to `bin/ai-setup.sh`.
- [ ] Step 2: Extract skills/agents functions from `lib/setup.sh` → new `lib/setup-skills.sh`: `install_shopify_skills`, `install_storyblok_scripts`, `install_spec_skills`, `install_agents`, `_inject_agent_skills`, `merge_skills_dir_into_canonical`, `repair_canonical_skill_links`, `ensure_skills_alias`, `ensure_codex_skills_alias`, `ensure_opencode_skills_alias`. Add `source_lib`.
- [ ] Step 3: Extract compat/config functions from `lib/setup.sh` → new `lib/setup-compat.sh`: `generate_opencode_config`, `_oc_model`, `install_claudeignore`, `install_repomix_config`, `install_repomixignore`, `generate_repomix_snapshot`, `install_statusline_project`, `install_copilot`. Add `source_lib`.
- [ ] Step 4: Verify all function calls in `bin/ai-setup.sh` still resolve. Run `./bin/ai-setup.sh --help` or dry-run to confirm no breakage.
- [ ] Step 5: Run `npx @onedot/ai-setup` in a test project to verify full setup works end-to-end.

## Acceptance Criteria
- [ ] `lib/generate.sh` contains only generation logic (< 850 LOC)
- [ ] `lib/setup.sh` contains only core template installation (< 450 LOC)
- [ ] Three new modules exist: `shopware.sh`, `setup-skills.sh`, `setup-compat.sh`
- [ ] Full setup (`npx @onedot/ai-setup`) completes without errors

## Files to Modify
- `lib/generate.sh` — remove Shopware functions
- `lib/setup.sh` — remove skills + compat functions
- `lib/shopware.sh` — new, Shopware-specific context + MCP
- `lib/setup-skills.sh` — new, skills/agents installation
- `lib/setup-compat.sh` — new, OpenCode/Repomix/Copilot compat
- `bin/ai-setup.sh` — add 3 new `source_lib` calls

## Out of Scope
- Refactoring function internals (pure extraction, no logic changes)
- Splitting any other lib modules
- Changing the public API or CLI flags
