# Spec: Token Optimization — .claudeignore + Skill Descriptions

> **Spec ID**: 575 | **Created**: 2026-03-24 | **Status**: completed | **Complexity**: medium | **Branch**: —

## Goal
Reduce token overhead by closing .claudeignore gaps (~236K einmalig) and trimming verbose skill descriptions (~800 tokens/message for all users).

## Context
Token Optimizer audit (Iteration 2, Eval-0) identified two high-ROI fixes: missing .claudeignore entries expose large directories to auto-indexing, and 11 template skill descriptions exceed 200 chars, inflating the skill menu for every user on every message. Empty stubs (drizzle, pinia, etc.) were NOT found — already cleaned up. Rules scoping is mostly correct (only typescript.md needs globs, and it already has them).

### Verified Assumptions
- `.claude/*.log` files are not in .claudeignore — Evidence: `cat .claudeignore` | Confidence: High | If Wrong: already optimized
- `specs/` and `templates/` are not in .claudeignore — Evidence: `cat .claudeignore` | Confidence: High | If Wrong: already optimized
- Template skills live in `templates/skills/*/SKILL.md` — Evidence: `find templates -name SKILL.md` | Confidence: High | If Wrong: wrong edit path
- 5 empty stubs do NOT exist — Evidence: `find` returned nothing | Confidence: High | If Wrong: stubs need removal too

## Steps
- [x] Step 1: Add `.claude/*.log`, `specs/`, `templates/`, `CHANGELOG.md` to project `.claudeignore`
- [x] Step 2: Add `.claude/*.log` to template `.claudeignore` (for users)
- [x] Step 3: Trim 11 verbose skill descriptions in `templates/skills/*/SKILL.md` to ≤200 chars each
- [x] Step 4: Verify — run `wc -c` on all modified skill files, confirm no description >200 chars

## Acceptance Criteria

### Truths
- [x] `grep -c 'specs/' .claudeignore` returns 1
- [x] `grep -c 'templates/' .claudeignore` returns 1
- [x] `grep -c '.claude/\*.log' .claudeignore` returns 1
- [x] No template skill description field exceeds 200 characters

## Files to Modify
- `.claudeignore` — add 4 missing entries
- `templates/.claudeignore` — add 1 entry for user projects
- `templates/skills/*/SKILL.md` (up to 11 files) — trim description fields

## Out of Scope
- Rules scoping (generic rules are intentionally global)
- Large skill file splitting (gh-cli, agent-browser — own setup, not templates)
- Setup script changes
