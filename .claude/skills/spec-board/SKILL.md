---
name: spec-board
description: Overview of all specs as Kanban board. Triggers: /spec-board, 'show specs', 'spec overview', 'what specs do we have', 'show me whats in progress'.
---

Displays a Kanban board of all specs with status and step progress. Use for an overview of the current spec pipeline.

## Step 1: Show board (zero tokens)

!.claude/scripts/spec-board.sh

## Step 2: Consistency Check + Repair

After the board output above, scan the specs listed for inconsistencies:

**Type A — Stale in-progress**: spec has all steps `- [x]` but status is still `in-progress` or `in-review` (not moved to `specs/completed/`).

**Type B — Wrong location**: spec has status `completed` but file is still in `specs/` (not in `specs/completed/`).

If any inconsistencies are found, list them:
```
⚠️  Inconsistencies found:
  #NNN Title — all steps done but status is "in-progress" (Type A)
  #MMM Title — status "completed" but file not in specs/completed/ (Type B)
```

Use `AskUserQuestion` to ask:
```
Fix these inconsistencies automatically?
A) Fix all — update status and move files now
B) Fix selected — I'll choose one by one
C) Skip — leave as is
```

- **Option A**: For each inconsistency:
  - Type A: set status to `completed`, move `specs/NNN-*.md` → `specs/completed/NNN-*.md`
  - Type B: move `specs/NNN-*.md` → `specs/completed/NNN-*.md`
  - Report each fix.
- **Option B**: For each inconsistency, ask individually with AskUserQuestion (Fix / Skip).
- **Option C**: Skip all fixes.

## Rules
- Only write or move files during step 2 and only after user confirms.
- If `specs/` does not exist or has no spec files, report "No specs found" and stop.

## Next Step

To work on a spec, run `/spec-work NNN`. To validate a draft spec before starting, run `/spec-validate NNN`.
