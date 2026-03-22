# Spec: WHEN/THEN Scenarios as Optional Acceptance Criteria Format

> **Spec ID**: 164 | **Created**: 2026-03-22 | **Status**: completed | **Complexity**: low | **Branch**: —

## Goal
Add WHEN/THEN scenario format as an optional acceptance criteria category alongside Truths/Artifacts/Key Links.

## Context
Inspired by OpenSpec's behavior-first specs which use WHEN/THEN/AND scenarios for requirements. Our current AC categories (Truths, Artifacts, Key Links) are good for technical verification but lack a natural way to express user-facing behavior. WHEN/THEN scenarios fill this gap for UI features, API endpoints, and user workflows. Optional — not required for every spec.

## Steps
- [x] Step 1: Update `specs/TEMPLATE.md` — add `### Scenarios` as a fourth optional AC category with WHEN/THEN/AND format and a comment explaining when to use it (UI features, API behavior, user workflows)
- [x] Step 2: Update `templates/skills/spec-create/SKILL.md` — mention Scenarios as optional AC format in the template section, note it should only be used when behavior is user-facing
- [x] Step 3: Copy updated spec-create skill to `.claude/skills/spec-create/SKILL.md`

## Acceptance Criteria

### Truths
- [x] "specs/TEMPLATE.md contains a ### Scenarios section with WHEN/THEN format"
- [x] "The Scenarios section is marked as optional with a comment"

### Artifacts
- [x] `specs/TEMPLATE.md` — updated template with Scenarios category (min 5 new lines)

## Files to Modify
- `specs/TEMPLATE.md` — add Scenarios AC category
- `templates/skills/spec-create/SKILL.md` — mention Scenarios format
- `.claude/skills/spec-create/SKILL.md` — mirror

## Out of Scope
- Retrofitting existing specs with WHEN/THEN scenarios
- Making Scenarios mandatory
- Changes to spec-review verification logic
