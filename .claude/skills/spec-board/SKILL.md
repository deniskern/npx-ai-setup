---
name: ais:spec-board
description: "Overview of all specs as Kanban board. Triggers: /spec-board, 'show specs', 'spec overview', 'what specs do we have', 'show me whats in progress'."
model: haiku
---

Displays a visual terminal board of active specs plus only the latest 10 completed specs. Show the raw board output exactly as produced by the script before adding any short summary.

## Step 1: Show board (zero tokens)

!.claude/scripts/spec-board.sh

## Rules
- This skill is read-only by default. Do not repair or move files unless the user explicitly asks for cleanup.
- Show the shell board first. Do not replace it with a one-line summary.
- If `specs/` does not exist or has no spec files, report "No specs found" and stop.
- The default board is intentionally windowed: all open specs + latest 10 completed specs only.

## Next Step

To work on a spec, run `/spec-work NNN`. To validate a draft spec before starting, run `/spec-validate NNN`.
