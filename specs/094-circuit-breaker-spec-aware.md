# Spec: Circuit Breaker raises thresholds when a spec is in-progress

> **Spec ID**: 094 | **Created**: 2026-03-15 | **Status**: in-progress | **Complexity**: low | **Branch**: —

## Goal
Prevent false-positive circuit breaker blocks during legitimate spec execution by raising edit thresholds when a `specs/*.md` file has `Status: in-progress`.

## Context
The circuit breaker fires at 8 edits/10 min — correct for detecting infinite loops, but too low for planned migrations executed via spec-work (e.g. color token replacements across large files). An active in-progress spec is a reliable signal that the edits are planned, not circular.

## Steps
- [x] Step 1: In `templates/claude/hooks/circuit-breaker.sh`, after the existing whitelist block, add a spec-active check: if `specs/*.md` contains `Status.*in-progress`, set `BLOCK=20` and `WARN=12` instead of the defaults (8 and 5)
- [x] Step 2: Add smoke test asserting `circuit-breaker.sh` contains the spec-active detection logic

## Acceptance Criteria
- [ ] `templates/claude/hooks/circuit-breaker.sh` contains a check for `in-progress` specs that raises BLOCK to 20 and WARN to 12
- [ ] Smoke tests pass (`./tests/smoke.sh`)

## Files to Modify
- `templates/claude/hooks/circuit-breaker.sh` — add spec-active threshold override
- `tests/smoke.sh` — add assertion for spec-active check

## Out of Scope
- Completely disabling the circuit breaker during specs (warn-only mode)
- Per-file whitelist entries
- Changing default thresholds (8/5) for non-spec work
