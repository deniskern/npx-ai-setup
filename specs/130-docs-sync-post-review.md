# Spec: Sync all documentation after Specs 108–128

> **Spec ID**: 130 | **Created**: 2026-03-21 | **Status**: in-progress | **Complexity**: low | **Branch**: —

## Goal
Update all developer-facing documentation to reflect the current state after Specs 108–128.

## Context
Specs 108–128 added new commands, removed /grill (merged into /review), added 3 agents, and added quality rules. README, CHANGELOG, and WORKFLOW-GUIDE have stale counts, incomplete tables, and missing entries. WORKFLOW-GUIDE is the primary developer reference and most critical to update.

## Steps
- [x] Step 1: Update WORKFLOW-GUIDE.md — commands table (remove /grill, add missing), agents table (5→11), hooks list (4→12)
- [ ] Step 2: Update README.md — header counts, command table (remove /grill, add missing), agent table (add 3 new)
- [ ] Step 3: Update README.md hooks description to use actual hook filenames
- [ ] Step 4: Add missing CHANGELOG entries for Specs 108–128 under [Unreleased]
- [ ] Step 5: Verify all counts match actual file counts in templates/

## Acceptance Criteria
- [ ] WORKFLOW-GUIDE lists all commands, all 11 agents, all 12 hooks
- [ ] README counts match `ls templates/commands/*.md` and `ls templates/agents/*.md`
- [ ] CHANGELOG [Unreleased] has entries for all specs 108–128

## Files to Modify
- `templates/claude/WORKFLOW-GUIDE.md` — commands, agents, hooks sections
- `README.md` — counts, command table, agent table, hooks description
- `CHANGELOG.md` — add missing spec entries

## Out of Scope
- .claude/commands/ mirroring (templates are source of truth)
- Content changes to commands or agents themselves
