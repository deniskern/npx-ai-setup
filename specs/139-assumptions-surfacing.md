# Spec: Assumptions Surfacing in /spec Command

> **Spec ID**: 139 | **Created**: 2026-03-22 | **Status**: in-review | **Complexity**: medium | **Branch**: —

## Goal
Add an assumptions-surfacing step to the `/spec` command that makes Claude's implicit assumptions explicit before planning.

## Context
Adapted from GSD's `list-phase-assumptions` + `gsd-assumptions-analyzer`. Currently `/spec` jumps from "Think It Through" directly to writing. This misses implicit assumptions about technical approach, scope, risks, and dependencies. Adding a structured assumptions step between 1e and 1f prevents false starts and reduces rework. Each assumption must cite evidence (file path) and state a concrete consequence if wrong.

## Steps
- [x] Step 1: Add Phase 1e-bis "Surface Assumptions" to `templates/commands/spec.md` after Think It Through — scan 3-5 relevant source files, form assumptions with Evidence/Confidence/If-Wrong structure
- [x] Step 2: Present assumptions via `AskUserQuestion` — user confirms, corrects, or adds missing assumptions
- [x] Step 3: Feed confirmed assumptions into spec Context section as "Verified Assumptions" subsection
- [x] Step 4: Mirror changes to `.claude/commands/spec.md`
- [ ] Step 5: Test — create a spec with `/spec` and verify assumptions step triggers, produces structured output, and feeds into spec

## Acceptance Criteria
- [ ] `/spec` asks about assumptions before writing the spec
- [ ] Each assumption has: Statement, Evidence (file path), Confidence (High/Medium/Low), If Wrong (consequence)
- [ ] User can correct or dismiss assumptions via AskUserQuestion
- [ ] Confirmed assumptions appear in spec's Context section

## Files to Modify
- `templates/commands/spec.md` — add assumptions step
- `.claude/commands/spec.md` — mirror changes

## Out of Scope
- Separate `/assumptions` command (inline in /spec is sufficient)
- Assumptions for non-spec work
