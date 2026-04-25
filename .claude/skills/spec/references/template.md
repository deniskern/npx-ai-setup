# Spec Template

```markdown
# Spec: [Clear Title]

> **Spec ID**: NNN | **Created**: YYYY-MM-DD | **Status**: draft | **Complexity**: medium | **Branch**: —

## Goal
[One sentence]

## Context
[2-3 sentences. Why needed, what approach was chosen, relevant skills if any.]

### Verified Assumptions
- [Statement] — Evidence: `path/to/file:NN` | Confidence: High/Medium | If Wrong: [consequence]

## Stack Coverage
- **Profiles affected**: nuxt-storyblok, shopify-liquid (or "all" / "single: laravel")
- **Per-stack difference**: [what changes per stack, if any]

## Steps
- [ ] Step 1: `path/to/file` — description
- [ ] Step 2: `path/to/file` — description

## Acceptance Criteria
- [ ] "[observable behavior verifiable by running a command or reading output]"

## Files to Modify
- `path/to/file` — reason

## Out of Scope
- What is NOT part of this task (max 3 items)
```

## Constraints

- Max 60 lines total. Auto-split at >8 steps or cross-layer architecture.
- Goal: 1 sentence. Context: 2-3 sentences. Out of Scope: max 3 items.
- Every step must reference a file path. No abstract steps.
- Use today's date (`date +%Y-%m-%d`). Filename: `NNN-lowercase-hyphens.md`.
- Create `specs/` and `specs/completed/` if missing.
- After split: cross-reference NNN ↔ NNN+1, note which runs first.
