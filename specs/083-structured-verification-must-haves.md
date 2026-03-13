---
**Status**: draft
**Branch**: —
**Complexity**: medium
---

# Spec 083 — Structured Verification Must-Haves in Spec Template

## Goal

Replace freetext acceptance criteria in the spec template with three structured categories (Truths, Artifacts, Key Links) that make verification mechanically checkable instead of interpretive.

## Context

Current spec acceptance criteria are freetext bullets like "Feature works correctly" — hard to verify mechanically. GSD-2 uses a three-category structure that maps directly to automated checks:
- **Truths**: Observable behaviors verified by running commands or checking output
- **Artifacts**: Files that must exist with real implementation (not stubs), with minimum content indicators
- **Key Links**: Imports/wiring between artifacts that must actually connect

This is a zero-sum token change — the acceptance criteria section already exists, we just structure it differently.

**Dependency:** Spec 081 adds a step to `spec-work.md` and renumbers subsequent steps. Execute 081 first, or apply all spec-work.md changes in the same branch.

Relevant files: `templates/commands/spec.md`, `templates/commands/spec-review.md`, `templates/commands/spec-work.md`, `templates/agents/verify-app.md`

## Steps

- [x] **Step 1 — Update spec template acceptance criteria structure**
  In `templates/commands/spec.md`, find the section where acceptance criteria are defined (Phase 2 — Write the spec). Change the Acceptance Criteria section from freetext bullets to:
  ```markdown
  ## Acceptance Criteria

  ### Truths
  Observable behaviors that must be true when this spec is done:
  - [ ] "[behavior description that can be verified by running a command or observing output]"

  ### Artifacts
  Files that must exist with real implementation (not stubs):
  - [ ] `path/to/file.ts` — [what it exports/contains] (min [N] lines)

  ### Key Links
  Critical wiring between artifacts that must actually connect:
  - [ ] `file-a.ts` → `file-b.ts` via import of `[function/type]`
  ```
  Add a note in the spec template instructions that:
  - Truths are checked by running commands or observing output
  - Artifacts are checked by confirming files exist with real content
  - Key Links are checked by confirming imports/references connect
  - Not every spec needs all three categories — omit empty ones

- [x] **Step 2 — Update spec-review to check structured criteria**
  In `templates/commands/spec-review.md`, update the review process to check each category mechanically:
  - Truths: Run the described command/check
  - Artifacts: Verify file exists, has real content (not placeholder), meets minimum lines if specified
  - Key Links: Verify the import/reference actually exists in the source file

- [x] **Step 3 — Update spec-work verification step**
  In `templates/commands/spec-work.md`, find the **"Verify acceptance criteria"** step (currently step 11, step 12 if Spec 081 has run first). Add guidance:
  - "Check Truths by running the described commands. Check Artifacts by reading the files and confirming real implementation. Check Key Links by verifying imports exist."

- [x] **Step 4 — Update verify-app agent**
  In `templates/agents/verify-app.md`, add awareness of the structured format so it can check Artifacts and Key Links programmatically (glob for files, grep for imports).

## Files to Modify

- `templates/commands/spec.md`
- `templates/commands/spec-review.md`
- `templates/commands/spec-work.md`
- `templates/agents/verify-app.md`
- `templates/skills/spec-review/SKILL.md` (mirror Step 2)
- `templates/skills/spec-work/SKILL.md` (mirror Step 3)

## Acceptance Criteria

### Truths
- [ ] A spec created with `/spec` produces acceptance criteria in Truths/Artifacts/Key Links format
- [ ] `/spec-review` checks each category type with appropriate verification method

### Artifacts
- [ ] `templates/commands/spec.md` contains the three-category acceptance criteria template
- [ ] `templates/commands/spec-review.md` contains category-specific review instructions

### Key Links
- [ ] `spec-work.md` step 11 references the structured verification categories
- [ ] `verify-app.md` includes instructions for checking Artifacts (file existence) and Key Links (import verification)
- [ ] `templates/skills/spec-review/SKILL.md` mirrors the spec-review.md change
- [ ] `templates/skills/spec-work/SKILL.md` mirrors the spec-work.md change

## Out of Scope

- Migration of existing specs to the new Truths/Artifacts/Key Links format — old freetext criteria remain valid
- Enforcement or linting of spec format at runtime
- Changes to `spec-work-all.md` — it delegates verification entirely to `spec-work`
