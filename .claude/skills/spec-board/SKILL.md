---
name: spec-board
description: Overview of all specs as Kanban board. Triggers: /spec-board, 'show specs', 'spec overview', 'what specs do we have', 'show me whats in progress'.
disable-model-invocation: true
---

# Spec Board — Kanban Overview of All Specs

Displays all specs grouped by status with step progress.

## Process

1. **Scan specs**: `ls specs/*.md specs/completed/*.md 2>/dev/null`

2. **For each spec**, extract:
   - ID and title from filename
   - Status from `**Status**:` in the header
   - Step progress: count `- [x]` vs total `- [ ]` + `- [x]` lines

3. **Display as Kanban**:

```
DRAFT          IN-PROGRESS    IN-REVIEW      COMPLETED
─────────      ───────────    ─────────      ─────────
074 title      075 title      073 title      072 title
               [3/6 steps]                   ✓
```

4. **Summary line**: `X draft, Y in-progress, Z in-review, W completed`

## Status values
- `draft` — approved, ready to implement
- `in-progress` — currently being worked on
- `in-review` — implemented, awaiting review
- `blocked` — blocked, needs user input
- `completed` — done, moved to specs/completed/
