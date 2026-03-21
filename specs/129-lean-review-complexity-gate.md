# Spec: Lean Review Flow mit Complexity-Gate

> **Spec ID**: 129 | **Created**: 2026-03-21 | **Status**: in-progress | **Branch**: spec/129-lean-review-complexity-gate | **Complexity**: medium

## Goal
Remove meaningless scoring from spec-review and add complexity-gated staff-reviewer for high-complexity specs in both spec-work and spec-review.

## Context
The current spec-review uses a 10-metric scoring system (0-100) that produces arbitrary LLM-generated numbers with no actionable value. The code-reviewer agent already provides concrete findings with PASS/CONCERNS/FAIL verdicts. High-complexity specs benefit from an additional skeptical review via staff-reviewer. This change simplifies the review flow and adds depth only where justified.

## Steps
- [x] Step 1: Update `templates/commands/spec-work.md` Step 18 — add complexity-gated review (Low/Medium: code-reviewer only; High: code-reviewer + staff-reviewer in parallel)
- [x] Step 2: Update `templates/commands/spec-review.md` — remove section 5d (quality scoring), remove score table from section 6 verdict, simplify verdict logic to use code-reviewer + AC pass/fail, add complexity gate for staff-reviewer in section 5c
- [ ] Step 3: Mirror Step 1 changes to `.claude/commands/spec-work.md`
- [ ] Step 4: Mirror Step 2 changes to `.claude/commands/spec-review.md`

## Acceptance Criteria
- [ ] No scoring metrics or score tables remain in spec-review (template + active)
- [ ] spec-work Step 18 spawns staff-reviewer additionally when Complexity is high
- [ ] spec-review spawns staff-reviewer additionally when Complexity is high
- [ ] Verdict logic in spec-review uses code-reviewer verdict + acceptance criteria, not numeric scores

## Files to Modify
- `templates/commands/spec-work.md` — Step 18 complexity gate
- `templates/commands/spec-review.md` — Remove scoring, add complexity gate
- `.claude/commands/spec-work.md` — Mirror
- `.claude/commands/spec-review.md` — Mirror

## Out of Scope
- Changes to `/review` command (stays as-is for non-spec work)
- Changes to code-reviewer or staff-reviewer agent definitions
- Changes to spec-validate or spec-work-all
