# Spec: Add Stakeholder Perspectives to /challenge Command

> **Spec ID**: 109 | **Created**: 2026-03-18 | **Status**: in-review | **Complexity**: low | **Branch**: —

## Goal
Add a Phase 6b (Stakeholder Perspectives) to `/challenge` that simulates 4 viewpoints before the verdict.

## Context
SpecForge evaluation identified multi-persona challenge as a PARTIAL gap. Our `/challenge` evaluates from one skeptical voice — adding Security, UX, DevOps, and End User perspectives catches blind spots. Minimal edit: ~15 lines inserted into existing template.

## Steps
- [x] Step 1: Insert Phase 6b section into `templates/commands/challenge.md` between Phase 6 (line 46) and Phase 7 (line 47) with 4 stakeholder perspectives (Security Engineer, UX Designer, DevOps Engineer, End User) — each 2-3 sentences, skip if not applicable
- [x] Step 2: Update Phase 7 verdict to reference stakeholder findings ("incorporate concerns from Phase 6b into the verdict rationale")
- [x] Step 3: Copy updated template to `.claude/commands/challenge.md` for local project use

## Acceptance Criteria

### Truths
- [x] `/challenge` output includes a "Stakeholder Perspectives" section between Alternatives and Verdict
- [x] Irrelevant perspectives are skipped (e.g. UX for a CLI-only backend change)

### Artifacts
- [x] `templates/commands/challenge.md` — contains Phase 6b with 4 stakeholder definitions (min 70 lines total)

## Files to Modify
- `templates/commands/challenge.md` — insert Phase 6b section
- `.claude/commands/challenge.md` — sync with updated template

## Out of Scope
- Adding more than 4 perspectives
- Making perspectives configurable via arguments
- Changes to any other command template
