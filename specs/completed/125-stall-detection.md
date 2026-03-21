# Spec: Add Stall Detection to /spec-work

> **Spec ID**: 125 | **Created**: 2026-03-21 | **Status**: in-review | **Complexity**: medium | **Branch**: —

## Goal

Prevent infinite iteration loops in `/spec-work` by adding per-step retry limits and consecutive no-change detection that auto-abort or warn when progress stalls.

## Context

Both `/loop` and `/spec-work` can get stuck repeating the same actions without making progress, burning tokens. Adding stall detection (max retries + progress checks) protects against infinite loops.

## Steps

- [x] Step 1: Read the current `templates/commands/spec-work.md` and `.claude/commands/spec-work.md`
- [x] Step 2: Add per-step retry limit to both command files: if same step is retried >3 times without completing, mark as blocked and move to next step
- [x] Step 3: Add progress tracking to both command files: after each step, check if git diff shows actual file changes. If 2 consecutive steps produce no changes, warn and ask user
- [x] Step 4: Add total-iteration stats at completion to both command files: steps completed, steps blocked, files changed
- [x] Step 5: Mirror all changes — both template and project-local command files must be identical
- [x] Step 6: Update `.claude/skills/spec-work/SKILL.md` description if it mentions behavior that changed

## Acceptance Criteria

- [x] `templates/commands/spec-work.md` contains stall detection logic (retry limit + no-change warning)
- [x] `.claude/commands/spec-work.md` is identical to the template version
- [x] Per-step retry limit is documented: blocked after >3 retries
- [x] No-change warning triggers after 2 consecutive steps with no git diff output
- [x] Completion summary includes: steps completed, steps blocked, files changed
- [x] SKILL.md updated if behavior description changed

## Files to Modify

- `templates/commands/spec-work.md` — add stall detection + retry limit + completion stats
- `.claude/commands/spec-work.md` — mirror template exactly
- `.claude/skills/spec-work/SKILL.md` — update description if needed

## Out of Scope

- `/spec-work-all` — separate command, not in scope
- Changes to `/loop` command
- Changes to spec-validate, spec-review, or other spec commands
