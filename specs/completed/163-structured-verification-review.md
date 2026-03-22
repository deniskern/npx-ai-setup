# Spec: Structured 3-Check Verification in Spec Review

> **Spec ID**: 163 | **Created**: 2026-03-22 | **Status**: completed | **Complexity**: low | **Branch**: —

## Goal
Add explicit Completeness/Correctness/Coherence checks to the spec-review skill for systematic verification.

## Context
Inspired by OpenSpec's `/opsx:verify` which uses 3 named checks. Our `/spec-review` already verifies acceptance criteria (Truths/Artifacts/Key Links) but the review process is not explicitly structured into phases. Adding named phases makes reviews more consistent and ensures no dimension is skipped. Small change — adds ~15 lines to the review skill.

## Steps
- [x] Step 1: Update `templates/skills/spec-review/SKILL.md` — add 3-check structure to process step 5: (A) Completeness — all steps checked, all files modified, no TODOs left. (B) Correctness — code matches acceptance criteria, no regressions. (C) Coherence — changes are logically consistent, edge cases handled, no dead code introduced
- [x] Step 2: Copy updated skill to `.claude/skills/spec-review/SKILL.md`

## Acceptance Criteria

### Truths
- [x] "templates/skills/spec-review/SKILL.md contains the words Completeness, Correctness, and Coherence"

### Artifacts
- [x] `templates/skills/spec-review/SKILL.md` — updated review skill with 3-check structure

## Files to Modify
- `templates/skills/spec-review/SKILL.md` — add 3-check verification structure
- `.claude/skills/spec-review/SKILL.md` — mirror

## Out of Scope
- Changes to spec-validate or spec-work skills
- Adding automated checks (this is instruction-level, not script-level)
