# Spec: Add Numeric Quality Scoring to /spec-validate

> **Spec ID**: 112 | **Created**: 2026-03-21 | **Status**: in-review | **Branch**: —

## Goal
Replace the 0–100 subjective scoring in /spec-validate with a weighted 0–10 per-criterion system (total 0–100) and A/B/C/F letter grades.

## Context
Current spec-validate scores 10 metrics on a vague 0–100 scale with PASS/FAIL output. A 0–10 scale per criterion forces clearer evaluation. Two-tier weighting (Core 12% + Secondary 8%) prioritizes the criteria that most impact spec executability. Letter grades (A/B/C/F) give instant readability. Remains advisory-only — does not block /spec-work.

## Steps
- [x] Step 1: Replace Section 4 "Score the spec" in `.claude/commands/spec-validate.md` — new 10-criteria table with 0–10 scale, weights, and evaluation questions
- [x] Step 2: Replace Section 5 "Present results" — score breakdown table showing raw score, weight, weighted score per criterion + total + letter grade
- [x] Step 3: Update Section 6 "Verdict" — grade thresholds (A ≥ 85, B ≥ 70, C ≥ 55, F < 55) replacing PASS/FAIL logic
- [x] Step 4: Mirror all changes to `templates/commands/spec-validate.md`
- [x] Step 5: Verify both files are identical and spec-validate skill SKILL.md description still matches

## Acceptance Criteria
- [x] Each criterion scored 0–10 with explicit weight (Core 12%, Secondary 7%)
- [x] Output shows score breakdown table with weighted total and letter grade (A/B/C/F)
- [x] Both command files are identical in content (modulo existing structural diff: template has extra "Run prep script" step)
- [x] Advisory-only — no blocking behavior added

## Files to Modify
- `.claude/commands/spec-validate.md` — primary command file
- `templates/commands/spec-validate.md` — template mirror

## Out of Scope
- Changes to /spec-work or any other command
- Automated blocking of low-grade specs
- Persistent score storage or history tracking
