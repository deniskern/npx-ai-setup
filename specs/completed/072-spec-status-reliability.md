# Spec: Reliable Spec Workflow Hardening

> **Spec ID**: 072 | **Created**: 2026-03-10 | **Status**: completed

## Goal
Ensure spec status transitions always happen and large tasks automatically split into multiple specs.

## Context
Developers report specs stuck with stale status (all steps done but still `in-progress`, not moved to `specs/completed/`). Root cause: status updates are prompt instructions at end of a 13-step flow — skipped under context pressure. Additionally, the "max 60 lines, split if larger" rule in `/spec` is passive and often ignored. Fix via prompt hardening, spec-board repair mode, and active auto-split logic.

## Steps
- [x] Step 1: In `templates/commands/spec-work.md`, add a "Status Checkpoint" rule at top of Rules section: "Before finishing, ALWAYS update status and move the file — this is the single most important step"
- [x] Step 2: In `templates/commands/spec-work.md`, restructure step 13 — update status to `in-review` BEFORE spawning code-reviewer, so status is saved even if agent fails
- [x] Step 3: In `templates/commands/spec-work-all.md`, add explicit fallback in wave post-processing: "If subagent failed or returned no result, set spec status to `blocked` with reason"
- [x] Step 4: In `templates/commands/spec-board.md`, add Step 6 "Consistency Check + Repair" — detect stale specs (all steps done but wrong status, completed but not moved), ask user to confirm fix, then update status and move files
- [x] Step 5: Update `templates/commands/spec-board.md` YAML header: remove `mode: plan`, add `Write, Edit, AskUserQuestion` to allowed-tools
- [x] Step 6: In `templates/commands/spec-work.md`, add resume logic at the start of step 9: scan for already-checked steps (`- [x]`), skip them, and continue from the first unchecked step — print which steps were skipped
- [x] Step 7: In `templates/commands/spec-work.md`, add auto-commit rule to step 9: after completing each step and checking it off, run `git add -A && git commit -m "spec(NNN): step N — <title>"` to preserve progress
- [x] Step 8: In `templates/commands/spec.md`, add active auto-split in Phase 2 Step 3: after drafting, check two triggers — (a) >60 lines or >8 steps, (b) mixed layers (frontend + backend, API + UI, etc.) — and automatically create separate spec files (NNN, NNN+1) with cross-references and dependency notes

## Acceptance Criteria
- [x] spec-work updates status before spawning code-reviewer agent
- [x] spec-board detects and offers to fix at least 2 inconsistency types (with user confirmation)
- [x] spec-work resumes from last unchecked step when re-run on a partially completed spec
- [x] spec-work commits after each completed step for crash resilience
- [x] /spec auto-splits when >60 lines, >8 steps, or mixed frontend/backend layers

## Files to Modify
- `templates/commands/spec-work.md` - reorder status update, add checkpoint rule
- `templates/commands/spec-work-all.md` - add failed subagent fallback
- `templates/commands/spec-board.md` - add consistency check + repair mode
- `templates/commands/spec.md` - add active auto-split logic in Phase 2

## Out of Scope
- New `/spec-fix` command (spec-board covers this)
- Hook-based automation of status transitions
- Changes to spec-review.md (already robust)
