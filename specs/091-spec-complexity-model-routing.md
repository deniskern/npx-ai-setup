# Spec: Complexity-based Model Routing in spec-work

> **Spec ID**: 091 | **Created**: 2026-03-15 | **Status**: in-progress | **Complexity**: low | **Branch**: —

## Goal
Route spec execution to Haiku, Sonnet, or Opus based on a `**Complexity**` field in the spec header, saving tokens on simple specs and using stronger models only when warranted.

## Context
spec-work currently always runs on Sonnet regardless of spec complexity. Simple one-file specs (config tweaks, text changes) waste Sonnet budget, while complex architectural specs could benefit from Opus. The spec-work template already uses `**Complexity**: high` for two checks (steps 4 and 8) but has no systematic model routing. Adding a formal three-tier complexity field enables consistent routing across all spec types.

`spec.md` runs on Opus — so Opus sets the Complexity field automatically when creating new specs. Without updating `spec.md`, the embedded template won't include the field and Opus won't have instructions for how to choose.

## Complexity Definitions
- **low**: mechanical, clearly-defined changes — no judgment required (e.g. add field to template, copy pattern, add smoke test, rename across files)
- **medium**: changes requiring judgment — logic, conventions, edge cases (default when unset)
- **high**: architectural changes, new systems, complex refactors

## Steps
- [ ] Step 1: Add `**Complexity**` field to `specs/TEMPLATE.md` header with values `low | medium | high`; add the three-tier definition table from this spec's "Complexity Definitions" section as a comment below the template
- [ ] Step 2: Update `templates/commands/spec.md` — add `**Complexity**` field to the embedded spec template (line ~104-147) and instruct Opus to automatically determine and set the correct complexity level based on the Complexity Definitions
- [ ] Step 3: Update `templates/commands/spec-work.md` — after step 11 (resume check), read `**Complexity**` field; spawn a model-routed subagent for step 12 implementation (Haiku for `low`, Sonnet for `medium`/unset, Opus for `high`)
- [ ] Step 4: Mirror the routing logic to `.claude/skills/spec-work/SKILL.md` (note: SKILL.md uses different step numbers — resume check is step 8, execute is step 9)
- [ ] Step 5: Add smoke test asserting `specs/TEMPLATE.md` contains `Complexity`

## Acceptance Criteria
- [x] `specs/TEMPLATE.md` header contains `**Complexity**: low | medium | high` with definitions documented
- [x] `templates/commands/spec.md` embedded template includes `**Complexity**` field and Opus receives instructions to set it automatically
- [x] `templates/commands/spec-work.md` routes step 12 to Haiku/Sonnet/Opus by complexity; unset defaults to Sonnet
- [x] `.claude/skills/spec-work/SKILL.md` mirrors the routing logic
- [x] Smoke tests pass (`./tests/smoke.sh`)

## Files to Modify
- `specs/TEMPLATE.md` — add `**Complexity**` field + definitions table
- `templates/commands/spec.md` — add Complexity field to embedded template + Opus instruction
- `templates/commands/spec-work.md` — add model routing after step 11
- `.claude/skills/spec-work/SKILL.md` — mirror routing logic (adjust for SKILL.md step numbers)
- `tests/smoke.sh` — add Complexity field assertion

## Out of Scope
- Changing the spec-work frontmatter `model:` field (Sonnet stays as orchestrator)
- Routing steps 1–11 or 13–18 to different models (only implementation step 12)
- Backfilling existing specs with Complexity field
