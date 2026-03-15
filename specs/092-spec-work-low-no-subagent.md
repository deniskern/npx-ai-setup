# Spec: spec-work low complexity executes directly without subagent

> **Spec ID**: 092 | **Created**: 2026-03-15 | **Status**: in-progress | **Complexity**: low | **Branch**: —

## Goal
Remove subagent spawn overhead for `low` complexity specs — execute directly, spawn subagent only for `medium` and `high`.

## Context
Spec 091 introduced model routing but spawning any subagent (even Haiku) adds initialization overhead that negates the benefit for trivial specs. For `low` complexity, the orchestrating model should execute steps directly. Subagents only pay off when the work is large enough to justify the spawn cost (`medium` → Sonnet subagent, `high` → Opus subagent).

## Steps
- [x] Step 1: Update `templates/commands/spec-work.md` step 11a — change `low` from "spawn Haiku subagent" to "execute directly (no subagent)"; keep `medium` → Sonnet subagent and `high` → Opus subagent
- [ ] Step 2: Mirror the change to `.claude/skills/spec-work/SKILL.md` step 8a

## Acceptance Criteria
- [ ] `templates/commands/spec-work.md` step 11a states `low` executes directly without subagent
- [ ] `.claude/skills/spec-work/SKILL.md` step 8a mirrors the same logic
- [ ] Smoke tests pass (`./tests/smoke.sh`)

## Files to Modify
- `templates/commands/spec-work.md` — update step 11a routing for `low`
- `.claude/skills/spec-work/SKILL.md` — mirror step 8a

## Out of Scope
- Changing routing for `medium` or `high`
- Any other spec-work changes
