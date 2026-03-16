# Spec: code-reviewer Numeric Confidence Scoring

> **Spec ID**: 102 | **Created**: 2026-03-16 | **Status**: completed | **Branch**: —

## Goal
Add numeric confidence scores (0–100) to code-reviewer findings and suppress anything below 80 — matching the quality bar of the official Anthropic code-review plugin.

## Context
Our `code-reviewer` agent uses text labels (HIGH/MEDIUM) but no numeric threshold. The official `code-review` plugin filters by 80+ confidence, which measurably reduces noise. Adding a score to each finding lets the agent self-filter and gives reviewers a clear signal about certainty.

## Steps
- [x] Step 1: Update `templates/agents/code-reviewer.md` — change output format to include a confidence score per finding (`[HIGH:92]`, `[MEDIUM:81]`); add rule: suppress findings with score < 80
- [x] Step 2: Update `templates/agents/code-reviewer.md` verdict logic — FAIL requires HIGH finding with score ≥ 80; CONCERNS requires MEDIUM with score ≥ 80; PASS if nothing clears the threshold

## Acceptance Criteria
- [x] Each finding in the output includes a numeric score: `[HIGH:92] file:line — description`
- [x] Findings with confidence < 80 are not reported (suppressed silently)
- [x] Verdict logic correctly reflects the 80+ threshold
- [x] Agent template diff is under 15 lines

## Files to Modify
- `templates/agents/code-reviewer.md` — update output format and suppression rule

## Out of Scope
- Changing the installed `.claude/agents/code-reviewer.md` directly (updated on next setup run)
- Adding confidence scoring to other agents (perf-reviewer, staff-reviewer)
