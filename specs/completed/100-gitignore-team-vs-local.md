# Spec: gitignore — Team vs. Local Artifacts

> **Spec ID**: 100 | **Created**: 2026-03-16 | **Status**: completed | **Branch**: —

## Goal
Ensure generated context artifacts (.agents/context/*.md, AUDIT.md, PATTERNS.md) are committed and shared across the team, while machine-local state and caches stay gitignored.

## Context
Currently `.agents/context/.state` is gitignored but the generated context files (STACK.md, ARCHITECTURE.md, CONVENTIONS.md) are tracked — this is correct. However the upcoming PATTERNS.md and AUDIT.md from spec 098 need to be tracked too (team knowledge, not local state). The .state file, repomix snapshot, skill cache, and memory remain local-only. This spec audits and documents the boundary clearly.

## Principle
- **Gitignored (machine-local):** generated snapshots, hashes, caches, personal memory
- **Committed (team-shared):** context files Claude reads automatically (STACK.md, ARCHITECTURE.md, CONVENTIONS.md, PATTERNS.md, AUDIT.md)

## Steps
- [x] Step 1: Audit `lib/setup.sh` `update_gitignore()` — verify `.agents/context/STACK.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` are NOT gitignored (currently correct, confirm)
- [x] Step 2: Ensure `PATTERNS.md` and `AUDIT.md` are NOT added to gitignore when spec 098 is implemented — add a note/comment in `lib/setup.sh` near the gitignore block documenting the boundary
- [x] Step 3: Add `.agents/context/PATTERNS.md` and `.agents/context/AUDIT.md` to the installed `WORKFLOW-GUIDE.md` as documented context artifacts Claude can reference
- [x] Step 4: Update `templates/CLAUDE.md` context section to list PATTERNS.md and AUDIT.md as optional context files

## Acceptance Criteria
- [x] `.agents/context/*.md` files (STACK, ARCHITECTURE, CONVENTIONS, PATTERNS, AUDIT) are not gitignored
- [x] `.agents/context/.state` and all cache/snapshot files remain gitignored
- [x] `CLAUDE.md` template documents PATTERNS.md and AUDIT.md as optional context
- [x] Comment in `lib/setup.sh` documents the team-vs-local boundary

## Files to Modify
- `lib/setup.sh` — add boundary comment, verify no context .md files are ignored
- `templates/claude/WORKFLOW-GUIDE.md` — document PATTERNS.md / AUDIT.md
- `templates/CLAUDE.md` — add PATTERNS.md / AUDIT.md to context section

## Out of Scope
- Changing what is gitignored today (only additions/clarifications)
- Auto-committing context files on generation
