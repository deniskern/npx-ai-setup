# Spec: SessionStart context hook head-truncation

> **Spec ID**: 107 | **Created**: 2026-03-16 | **Status**: in-progress | **Branch**: —

## Goal
Reduce SessionStart token cost by ~60-70% via head-truncation of STACK.md and CONVENTIONS.md injection.

## Context
The SessionStart hook `cat`s full STACK.md + CONVENTIONS.md into every session (500-1000 tokens). CLAUDE.md already instructs Claude to read these files before complex tasks, making full injection redundant. Truncating to the first 20 lines provides essential context (headers, key sections) while saving tokens on simple tasks.

## Steps
- [x] Step 1: In `templates/claude/settings.json`, replace `cat` with `head -20` in the SessionStart inline bash command
- [ ] Step 2: Update smoke test if any assertion depends on full context injection output
- [ ] Step 3: Run smoke tests to verify nothing breaks

## Acceptance Criteria
- [ ] SessionStart hook uses `head -20` instead of `cat` for context files
- [ ] Smoke tests pass (91/91 or more)
- [ ] No other hooks or scripts reference the full SessionStart output

## Files to Modify
- `templates/claude/settings.json` — change `cat` to `head -20` in SessionStart hook

## Out of Scope
- Adding disable flags or settings.local.json overrides
- Changing CLAUDE.md instructions about reading context files
- Modifying other hooks
