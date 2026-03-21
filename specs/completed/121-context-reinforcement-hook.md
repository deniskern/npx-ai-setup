# Spec: Context Reinforcement Hook After Compaction

> **Spec ID**: 121 | **Created**: 2026-03-21 | **Status**: in-review | **Branch**: —

## Goal
Add a SessionStart hook that re-injects critical rules after context compaction to prevent rule drift.

## Context
After compaction, Claude sometimes forgets enforcement rules (skill-first, read-before-modify, human approval gates). Octopus solves this with a `context-reinforcement.sh` SessionStart hook that re-injects "Iron Laws" via additionalContext. Our rules in `.claude/rules/` are loaded at session start but lost after compaction. This hook ensures they survive.

## Steps
- [x] Step 1: Create `templates/claude/hooks/context-reinforcement.sh` — rules hardcoded, outputs `additionalContext` JSON
- [x] Step 2: Select which rules to reinforce (max 5 — read-before-modify, skill-first, human-approval-gates, verify-before-done, no-sandbox-bypass)
- [x] Step 3: Add hook to `templates/claude/settings.json` under SessionStart event
- [x] Step 4: Hook completes in <50ms — no runtime file reads, no API calls, rules are hardcoded
- [x] Step 5: Test: `bash context-reinforcement.sh | python3 -m json.tool` → Valid JSON confirmed

## Acceptance Criteria
- [x] Hook fires on SessionStart and injects top 5 rules as additionalContext
- [x] Hook execution <50ms
- [x] Rules survive context compaction (hardcoded, no external dependencies)
- [x] No duplicate injection if rules already in context (idempotent — stateless output)

## Files to Modify
- `templates/hooks/context-reinforcement.sh` — new
- `templates/claude/settings.json` — add SessionStart hook entry

## Out of Scope
- Changing which rules exist in `.claude/rules/`
- Output quality gates (separate concern)
