# Spec: Merge /review + /grill into Single Command

> **Spec ID**: 119 | **Created**: 2026-03-21 | **Status**: in-review | **Branch**: —

## Goal
Merge `/review` and `/grill` into one `/review` command with intensity levels (Quick / Standard / Adversarial) to reduce tooling surface and eliminate redundancy.

## Context
Both commands read the same diff and check for similar issues (bugs, security). Users must decide between them. Octopus solves this with one `review.md` with intensity options. Merging reduces the command count and simplifies the decision. Inspired by claude-octopus review.md. Depends on Spec 118 for review-prep script.

## Steps
- [x] Step 1: Design the merged `/review` command with AskUserQuestion for intensity (Quick Scan / Standard Review / Adversarial Grill)
- [x] Step 2: Implement Quick mode — current `/review` behavior (bugs + security, HIGH/MEDIUM only)
- [x] Step 3: Implement Standard mode — adds performance, readability, test coverage checks + duplicate detection
- [x] Step 4: Implement Adversarial mode — adds Scope Challenge, Issue Resolution with A/B/C options, Self-Verification Table, "NOT reviewed" section (from current `/grill`)
- [x] Step 5: Add Stub/AI-Code Detection to all modes: "Check for placeholder implementations, TODO-marked incomplete code"
- [x] Step 6: Update `templates/commands/review.md`, remove `templates/commands/grill.md`, update `.claude/commands/` to match

## Acceptance Criteria
- [x] Single `/review` command replaces both `/review` and `/grill`
- [x] AskUserQuestion at start offers 3 intensity levels
- [x] Adversarial mode includes self-verification table and scope challenge
- [x] `/grill` removed from templates (breaking change documented)

## Files to Modify
- `templates/commands/review.md` — rewrite with intensity levels
- `templates/commands/grill.md` — delete
- `.claude/commands/review.md` — mirror template
- `.claude/commands/grill.md` — delete

## Out of Scope
- Review-prep script (Spec 118)
- Output quality gates via hooks
