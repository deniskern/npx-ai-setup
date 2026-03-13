---
**Status**: in-progress
**Branch**: —
**Complexity**: low
---

# Spec 081 — Understanding Confirmation in spec-work for High-Complexity Specs

## Goal

Before branch creation, show a 3-bullet understanding summary and ask for confirmation when `Complexity: high` is set — preventing wasted execution on misunderstood specs.

## Context

`spec-work` already gates on `Complexity: high` for architectural review (Step 6). The new confirmation step fits the same pattern but runs earlier (between Step 2 and Step 3), giving the user a chance to correct misunderstandings before any branch or commit is created.

Skills available: spec, spec-work, spec-review, spec-validate, spec-board, spec-work-all, spec-create.

## Steps

- [x] **Step 1 — Add understanding confirmation block to spec-work**
  In `templates/commands/spec-work.md`, insert a new step between the current Step 2 ("Read the spec") and Step 3 ("Branch setup"):

  ```
  3. **Understanding confirmation** (high-complexity specs only): Check if the spec header contains `**Complexity**: high`. If yes:
     - Show a 3-bullet summary:
       - **Goal**: [one sentence from the spec Goal section]
       - **Approach**: [main implementation strategy inferred from the Steps]
       - **Files**: [comma-separated list from the Files to Modify section]
     - Ask via AskUserQuestion: "Does this match your expectations before I create the branch and start work?"
       Options: [Yes, proceed] [No, clarify first]
     - If user selects "No, clarify first": stop, ask an open-ended follow-up question to understand the correction, and do not proceed.
  ```
  Renumber all subsequent steps (old Step 3 becomes Step 4, etc.).

- [x] **Step 2 — Mirror change in `.claude/skills/spec-work/`**
  Apply the identical change to `.claude/skills/spec-work/SKILL.md` (project-local copy).

## Acceptance Criteria

- [ ] `templates/commands/spec-work.md` contains the new understanding confirmation step between "Read the spec" and "Branch setup"
- [ ] The step is conditional on `Complexity: high` — no change for other specs
- [ ] `.claude/skills/spec-work/SKILL.md` mirrors the change
- [ ] All subsequent step numbers are updated correctly in both files

## Files to Modify

- `templates/commands/spec-work.md`
- `.claude/skills/spec-work/SKILL.md`

## Out of Scope

- Changing the Architect Review step (Step 6) — that runs later and serves a different purpose
- Adding confirmation for non-high-complexity specs
