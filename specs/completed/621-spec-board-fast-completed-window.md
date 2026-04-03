# Spec: Spec Board Fast Completed Window

> **Spec ID**: 621 | **Created**: 2026-04-03 | **Status**: completed | **Complexity**: medium | **Branch**: —

## Goal
Make `spec-board` materially faster and less noisy by default by limiting completed-spec scanning and display to the most recent completed window, without introducing user-facing parameters.

## Context
`spec-board` already uses a Bash script for the board itself, but it still scans the full `specs/` tree, including a large completed backlog. In practice, older completed specs are rarely relevant to current work, yet they still cost time and clutter the board. The desired behavior is a faster default board that keeps all active draft/in-progress/in-review/blocked specs visible while only considering the latest completed slice, with no additional CLI flags or skill arguments.

### Verified Assumptions
- The current board script scans both open and completed specs recursively under `specs/`. — Evidence: `.claude/scripts/spec-board.sh` | Confidence: High | If Wrong: the performance problem comes from another layer
- The repo currently contains far more completed specs than active ones. — Evidence: local `specs/` inventory and script output | Confidence: High | If Wrong: limiting completed history would give little benefit
- Older completed specs are low-value for the day-to-day board view compared with open work. — Evidence: user request and current board output distribution | Confidence: High | If Wrong: a separate history view may be needed
- The team does not want user-facing parameters for this behavior change. — Evidence: user instruction | Confidence: High | If Wrong: a configurable window may still be acceptable later

## Steps
- [x] Step 1: Redefine the default `spec-board` behavior so open specs are always scanned fully, but completed specs are limited to the 10 most recent completed files by default.
- [x] Step 2: Update `.claude/scripts/spec-board.sh` to gather open specs and completed specs through separate paths, applying the fixed completed window without requiring arguments.
- [x] Step 3: Ensure the board output makes the truncation explicit, for example by showing that `DONE` represents only the latest 10 completed specs rather than the full historical archive.
- [x] Step 4: Revisit the spec-board consistency logic so it only evaluates files that are still relevant to the default board behavior, avoiding unnecessary full-history work during normal board reads.
- [x] Step 5: Update the matching skill/template documentation so the no-parameter default behavior is clearly described and expectations stay aligned across Codex and Claude installs.
- [x] Step 6: Verify the new board still preserves the essential operator view: all active work visible, recent done work visible, old done work omitted.

## Acceptance Criteria

### Truths
- [x] Running `spec-board` with no arguments scans all open specs but no more than the latest 10 completed specs.
- [x] The board output explicitly communicates that completed history is windowed, not exhaustive.
- [x] The normal board path performs less work than the current full-history implementation.

### Artifacts
- [x] Updated board script with separate open/completed collection logic.
- [x] Updated skill/template text describing the fixed no-parameter behavior.
- [x] Verification notes showing the board still surfaces all active specs and only a bounded completed window.

## Files to Modify
- `.claude/scripts/spec-board.sh` - limit completed scanning to the most recent fixed window
- `.claude/skills/spec-board/SKILL.md` - document the new default board behavior
- `templates/skills/spec-board/SKILL.md` - preserve template parity for future installs

## Out of Scope
- Adding flags, arguments, or user-configurable limits to `spec-board`
- Building a separate archive browser for old completed specs
- Changing the meaning or visibility of active non-completed spec states
