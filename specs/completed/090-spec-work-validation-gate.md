# Spec: Add Validation Gate to spec-work

> **Spec ID**: 090 | **Created**: 2026-03-15 | **Status**: in-review | **Branch**: —

## Goal
Add an automatic spec validation step to spec-work that blocks execution of weak specs before any code changes happen.

## Context
Specs 088 and 089 both failed validation (wrong paths: globs, missing verification steps). The `/spec-validate` skill exists but is manual — users forget to run it. Adding a gate to spec-work ensures no weak spec reaches execution. The gate reuses spec-validate's 10 scoring criteria without duplicating them.

## Steps
- [x] Step 1: Add validation gate step (new step 3) to `templates/commands/spec-work.md` — after "Read the spec" (step 2), before "Understanding confirmation" (currently step 3). Score on 10 criteria, FAIL → show issues and STOP, PASS → continue. Reference spec-validate criteria by name, do not inline them.
- [x] Step 2: Mirror the same validation gate step to `.claude/skills/spec-work/SKILL.md` (between existing steps 2 and 3)
- [x] Step 3: Add `--skip-validate` flag documentation to the Rules section in both files — allows bypassing the gate for resumed specs or user override
- [x] Step 4: Add a smoke test assertion to `tests/smoke.sh` — verify `templates/commands/spec-work.md` contains "validation gate" or "spec-validate"
- [x] Step 5: Test manually: run `/spec-work 088` (known-failing spec) — confirm it stops with validation issues

## Acceptance Criteria
- [x] `templates/commands/spec-work.md` has a validation gate step between "Read the spec" and "Understanding confirmation"
- [x] `.claude/skills/spec-work/SKILL.md` has the matching gate step
- [x] Gate references spec-validate criteria (no duplication of the 10 scoring items)
- [x] `--skip-validate` flag is documented for bypass scenarios
- [x] Smoke test passes

## Files to Modify
- `templates/commands/spec-work.md` — add validation gate step + skip-validate flag
- `.claude/skills/spec-work/SKILL.md` — mirror validation gate step
- `tests/smoke.sh` — add assertion for validation gate presence

## Out of Scope
- Changes to `/spec` (spec creation skill)
- Changes to `/spec-validate` (validation skill itself)
- Auto-fix of failing specs (user must fix manually)
