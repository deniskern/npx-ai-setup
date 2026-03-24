---
name: spec-review
description: Review a completed spec after implementation. Triggers: /spec-review NNN, 'review spec NNN', 'did we complete spec NNN', 'verify spec implementation'.
disable-model-invocation: true
---

# Spec Review — Validate and Close a Spec

Reviews a spec in `specs/NNN-*.md` after implementation and decides whether it should be approved, sent back, or blocked.

## Process

1. **Find the spec**: open `specs/NNN-*.md` or the filename provided.

2. **Validate status**: review only specs with status `in-review`. If status differs, report it and stop.

3. **Read the spec**: understand Goal, Steps, Acceptance Criteria, Files to Modify, and Out of Scope.

4. **Inspect code changes**:
   - If the spec has a branch, compare it against `main`.
   - Otherwise inspect current staged and unstaged diffs.
   - Read the most important changed files fully before judging.

5. **Review against the spec** using the 3-check verification structure:

   **(A) Completeness** — nothing was skipped:
   - All steps are marked `[x]` and match reality in the codebase
   - All files listed under "Files to Modify" were actually modified
   - No TODOs, placeholders, or stub implementations remain
   - Acceptance criteria checkboxes are all marked `[x]`

   **(B) Correctness** — the implementation is right:
   - Code matches every acceptance criterion (Truths / Artifacts / Key Links)
   - No regressions introduced in existing functionality
   - For **Truths**: run the described command and confirm the output matches
   - For **Artifacts**: confirm the file exists with real implementation (not a stub)
   - For **Key Links**: open the source file and confirm the import or reference is present
   - Check `.agents/context/CONVENTIONS.md` for global quality gates if present

   **(C) Coherence** — the change makes sense as a whole:
   - Changes are logically consistent with each other and the stated Goal
   - Edge cases are handled or explicitly excluded in Out of Scope
   - No dead code, unused variables, or leftover debug statements introduced
   - Scope creep is flagged against the Out of Scope section

6. **Choose a verdict**:
   - `APPROVED`: status becomes `completed`, move spec to `specs/completed/`
   - `CHANGES REQUESTED`: add concrete review feedback, set status to `in-progress`
   - `REJECTED`: set status to `blocked` with the rejection reason

## Rules

- Do not speculate. Read the actual code.
- Do not make implementation changes as part of the review.
- Focus on correctness, regressions, and acceptance criteria over style.
