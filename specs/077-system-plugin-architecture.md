# Spec: Base/System Split — Two-Mode Setup Architecture

> **Spec ID**: 077 | **Created**: 2026-03-10 | **Status**: backlog | **Branch**: —

<!-- Backlog: Großes Architektur-Vorhaben. Erst diskutieren/brainstormen bevor implementiert wird. Voraussetzung: 080 als Vorstufe. -->

## Goal
Split the setup script into two distinct modes: **Base** (always runs, system-agnostic) and **System** (runs on demand, system-specific). Extract all system-specific logic into `lib/systems/<system>.sh` plugins. Result: `npx @onedot/ai-setup` = generic foundation; `npx @onedot/ai-setup shopware` = Shopware addon on top.

## Context
Today `bin/ai-setup.sh` mixes base and system-specific setup in one flow. Adding a new system requires modifying `generate.sh` (1027 lines), `setup.sh` (867 lines), and `detect.sh`. The fix: a plugin model where each system is a self-contained file, and `bin/ai-setup.sh` dispatches based on the first positional argument.

**Two modes:**
- `npx @onedot/ai-setup` — Base only: Hooks, Commands, Agents, Rules, Skills (generic)
- `npx @onedot/ai-setup shopware` — System only: MCP, context generation, system skills, system hooks/rules

**System plugin interface** — each `lib/systems/<system>.sh` implements:
- `system_gather_context()` — sets `CTX_SYSTEM`, `SYSTEM_INSTRUCTION`, `SYSTEM_RULE`
- `system_setup_mcp()` — configures MCP servers (no-op if none)
- `system_get_skills()` — echoes skill names to install
- `system_get_hooks()` — echoes hook filenames to install (no-op if none)

## Steps

- [ ] Step 1: In `bin/ai-setup.sh`, add positional argument parsing: if first arg is a known system name (`shopware`, `shopify`), set `MODE=system SYSTEM=$1`; otherwise set `MODE=base`. Pass `$MODE` through to the setup flow.
- [ ] Step 2: Create `lib/systems/shopware.sh` — move `gather_shopware_context()`, `detect_shopware_type()`, and `setup_shopware_mcp()` from `generate.sh` and `detect.sh`. Rename vars: `CTX_SHOPWARE`→`CTX_SYSTEM`, `SHOPWARE_INSTRUCTION`→`SYSTEM_INSTRUCTION`, `SHOPWARE_RULE`→`SYSTEM_RULE`. Implement the 4 interface functions. `system_get_skills()` echoes `shopware6-best-practices`. `system_get_hooks()` is a no-op.
- [ ] Step 3: Create `lib/systems/shopify.sh` — move Shopify-specific logic from `setup.sh` (agent skill injection for shopify-liquid, shopify-theme-dev; liquid-linter agent). Implement the 4 interface functions. `system_get_skills()` echoes `shopify-liquid shopify-theme-dev`. `system_get_hooks()` echoes hook filenames for Shopify if any.
- [ ] Step 4: Create `lib/systems/generic.sh` — no-op stubs for all 4 interface functions (fallback for unknown systems).
- [ ] Step 5: In `lib/_loader.sh`, after `detect_system()`, source the correct system plugin: `source "$SCRIPT_DIR/lib/systems/${SYSTEM:-generic}.sh" 2>/dev/null || source "$SCRIPT_DIR/lib/systems/generic.sh"`.
- [ ] Step 6: In `lib/setup.sh` and `lib/generate.sh`, gate all system-specific blocks on `[ "$MODE" = "system" ]`. Replace hardcoded Shopware/Shopify references with interface calls (`system_gather_context`, `system_setup_mcp`, `CTX_SYSTEM`, `SYSTEM_INSTRUCTION`, `SYSTEM_RULE`). Remove function bodies that moved to system plugins.
- [ ] Step 7: In `lib/setup.sh`, add `show_system_hints()` — called at the end of base setup. Auto-detects available systems (`detect_system` result) and prints an interactive selector (arrow+space) listing available system setups with a description. Selected system runs immediately (`bin/ai-setup.sh <system>`); "Skip for now" exits cleanly. If no system is detected, show all available options.
- [ ] Step 8: Update `tests/smoke.sh` — add existence and syntax checks for `lib/systems/*.sh`; add interface function presence checks for shopware.sh and shopify.sh. Update integration test to cover both `base` and `system shopware` modes.
- [ ] Step 9: Run `bash tests/smoke.sh && bash tests/integration.sh` — both pass.

## Acceptance Criteria
- [ ] `npx @onedot/ai-setup` (no args) runs base only — no MCP setup, no system context, no system skills
- [ ] After base setup, user sees an interactive system selector with detected/available systems
- [ ] `npx @onedot/ai-setup shopware` runs system setup — MCP, context, skills, no base re-install
- [ ] `lib/systems/shopware.sh`, `shopify.sh`, `generic.sh` exist and implement the 4-function interface
- [ ] `generate.sh` and `setup.sh` contain no hardcoded `CTX_SHOPWARE`, `SHOPWARE_RULE`, `SHOPIFY_SKILLS_MAP` references
- [ ] Both test suites pass

## Files to Modify
- `bin/ai-setup.sh` — add positional arg parsing, MODE dispatch
- `lib/systems/shopware.sh` — new (extracted from generate.sh + detect.sh)
- `lib/systems/shopify.sh` — new (extracted from setup.sh)
- `lib/systems/generic.sh` — new (no-op stubs)
- `lib/_loader.sh` — source system plugin
- `lib/generate.sh` — remove system-specific blocks, use interface vars
- `lib/setup.sh` — remove Shopify-specific blocks, use interface
- `lib/detect.sh` — remove `detect_shopware_type()` (moved to shopware.sh)
- `lib/setup.sh` — add `show_system_hints()` with interactive selector
- `tests/smoke.sh` — system file checks
- `tests/integration.sh` — base + system mode tests

## Out of Scope
- Combining base + system in a single uninterrupted run
- Remote/external system plugin discovery

## Complexity: high
Touches 9+ files. Run with `claude --model claude-opus-4-6` or `/gsd:set-profile quality` before `/spec-work 077`.
