# Spec: System Plugin Architecture — Shopware Extraction

> **Spec ID**: 077 | **Created**: 2026-03-10 | **Status**: draft | **Branch**: —

<!-- Status lifecycle: draft → in-progress → in-review → completed (or blocked at any stage) -->

## Goal
Extract Shopware-specific logic from `generate.sh` and `detect.sh` into `lib/systems/shopware.sh`, define a standard system-plugin interface, and update the loader. This proves the pattern before extracting Shopify and Generic in spec 078.

## Context
`generate.sh` is 1027 lines — ~260 lines are Shopware-only (`gather_shopware_context`, `setup_shopware_mcp`). `detect.sh` has `detect_shopware_type()`. Adding a new system today means modifying 3+ files. The goal is a `lib/systems/<system>.sh` plugin model where each system file is self-contained and the main scripts are system-agnostic.

**System plugin interface** — each `lib/systems/<system>.sh` must implement:
- `system_detect()` — returns 0 if this system is active, 1 otherwise
- `system_gather_context()` — sets `CTX_SYSTEM`, `SYSTEM_INSTRUCTION`, `SYSTEM_RULE` (replaces CTX_SHOPWARE etc.)
- `system_setup_mcp()` — configures MCP servers (no-op if none)
- `system_get_agent_skills()` — echoes skill names for agent injection

## Steps

- [ ] Step 1: Create `lib/systems/shopware.sh` — move `gather_shopware_context()`, `detect_shopware_type()`, and `setup_shopware_mcp()` from `generate.sh` and `detect.sh` into this file. Rename internal vars: `CTX_SHOPWARE` → `CTX_SYSTEM`, `SHOPWARE_INSTRUCTION` → `SYSTEM_INSTRUCTION`, `SHOPWARE_RULE` → `SYSTEM_RULE`. Add `system_detect()` wrapper (checks `$SYSTEM = shopware`), `system_gather_context()` (calls `gather_shopware_context`), `system_setup_mcp()` (calls `setup_shopware_mcp`), `system_get_agent_skills()` (echoes `shopware6-best-practices`).
- [ ] Step 2: Create `lib/systems/generic.sh` — stub implementing the same 4 functions as no-ops (for shopify and all non-shopware systems for now). `system_get_agent_skills()` returns empty.
- [ ] Step 3: In `lib/_loader.sh`, after sourcing all libs, source the correct system plugin: `source "$SCRIPT_DIR/lib/systems/${SYSTEM:-generic}.sh" 2>/dev/null || source "$SCRIPT_DIR/lib/systems/generic.sh"`.
- [ ] Step 4: In `lib/generate.sh`, replace all references to `gather_shopware_context`, `setup_shopware_mcp`, `CTX_SHOPWARE`, `SHOPWARE_INSTRUCTION`, `SHOPWARE_RULE` with the interface calls (`system_gather_context`, `system_setup_mcp`, `CTX_SYSTEM`, `SYSTEM_INSTRUCTION`, `SYSTEM_RULE`). Remove the moved function bodies from generate.sh.
- [ ] Step 5: In `lib/detect.sh`, remove `detect_shopware_type()` (now in shopware.sh). Update `detect_system()` if needed.
- [ ] Step 6: Add `lib/systems/shopware.sh` and `lib/systems/generic.sh` to smoke tests (existence + syntax checks). Add `system_gather_context` and `system_detect` to function-presence checks in shopware.sh.
- [ ] Step 7: Run `bash tests/smoke.sh && bash tests/integration.sh` — both must pass.

## Acceptance Criteria
- [ ] `lib/systems/shopware.sh` exists and contains all Shopware-specific logic
- [ ] `lib/systems/generic.sh` exists as a no-op fallback
- [ ] `generate.sh` contains no Shopware-specific variable names (`CTX_SHOPWARE`, `SHOPWARE_RULE`, etc.)
- [ ] A Shopware project still generates context correctly (system_gather_context called)
- [ ] A Shopify or generic project uses generic.sh without error
- [ ] Both test suites pass

## Files to Modify
- `lib/systems/shopware.sh` — new file (extracted from generate.sh + detect.sh)
- `lib/systems/generic.sh` — new file (stub)
- `lib/_loader.sh` — source system plugin after detection
- `lib/generate.sh` — remove Shopware blocks, use interface vars
- `lib/detect.sh` — remove detect_shopware_type()
- `tests/smoke.sh` — add system file checks

## Out of Scope
- Extracting Shopify-specific logic (spec 078)
- Dynamic system plugin discovery from external sources
- Changing the --system CLI flag behavior
- Shopify agent skill injection (stays in setup.sh until spec 078)

## Complexity: high
Requires careful extraction to avoid regressions. Run with `claude --model claude-opus-4-6` or `/gsd:set-profile quality`.
