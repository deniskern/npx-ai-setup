---
status: in-review
priority: medium
complexity: low
branch: —
---

# Spec 144: Finishing Gate in spec-review

## Goal
After an APPROVED verdict in `/spec-review`, present structured options for what to do next (merge, PR, keep, discard) instead of ending abruptly. Inspired by superpowers' "finishing-a-development-branch" skill.

## Context
Currently, `/spec-review` ends with "Spec NNN approved." — the user must manually decide what happens to the branch and worktree. Adding a finishing gate makes the workflow complete.

## Steps

- [x] **Step 1**: Add a new Phase 7 "Finishing Gate" to `spec-review` after the APPROVED verdict
  - Only triggers on APPROVED verdict (not CHANGES REQUESTED or REJECTED)
  - Uses `AskUserQuestion` to present 4 options:
    1. Merge to main locally
    2. Push and create PR
    3. Keep branch as-is
    4. Discard branch and changes
  - Each option includes a brief description

- [x] **Step 2**: Add execution logic for each option
  - Option 1 (Merge): `git checkout main && git merge BRANCH && git branch -d BRANCH`
  - Option 2 (PR): `git push -u origin BRANCH && gh pr create`
  - Option 3 (Keep): Report branch name and location, do nothing
  - Option 4 (Discard): Require typed confirmation, then `git checkout main && git branch -D BRANCH`
  - All options: clean up worktree if one exists (`git worktree remove`)

- [x] **Step 3**: Mirror changes to template file `templates/commands/spec-review.md`

- [x] **Step 4**: Update spec status and verify both files are consistent

## Acceptance Criteria
- APPROVED verdict triggers AskUserQuestion with 4 options
- Each option executes the described git operations
- Discard requires explicit confirmation
- Worktree cleanup happens automatically for options 1, 2, 4
- Template and active command stay in sync

## Files to Modify
- `.claude/commands/spec-review.md`
- `templates/commands/spec-review.md`

## Out of Scope
- Changes to CHANGES REQUESTED or REJECTED flows
- Automatic pushing without user choice
