# Spec: Repomix Snapshot Freshness Detection

> **Spec ID**: 096 | **Created**: 2026-03-16 | **Status**: draft | **Branch**: —

## Goal
Detect stale repomix snapshots via the existing freshness hook and warn when the snapshot is outdated.

## Context
The snapshot is generated once during setup and never refreshed — even if the codebase changes significantly. The freshness hook already compares `package.json`/`tsconfig.json` hashes but ignores the snapshot entirely. Adding a snapshot age check and hash to `.state` extends the existing pattern with minimal code.

## Steps
- [ ] Step 1: In `lib/generate.sh` state file block (~line 629), add `SNAPSHOT_AT` timestamp after snapshot generation completes
- [ ] Step 2: In `lib/setup.sh` `generate_repomix_snapshot()`, write snapshot cksum to `.agents/context/.state` as `SNAPSHOT_HASH` after successful generation
- [ ] Step 3: In `templates/claude/hooks/context-freshness.sh`, add snapshot staleness check — read `SNAPSHOT_AT`, warn if older than 7 days via stderr
- [ ] Step 4: Update the installed hook at `.claude/hooks/context-freshness.sh` to match the template
- [ ] Step 5: Test: generate snapshot, advance system clock or manually edit `.state` timestamp, verify `[SNAPSHOT STALE]` warning appears

## Acceptance Criteria
- [ ] `.state` file contains `SNAPSHOT_HASH` and `SNAPSHOT_AT` after setup
- [ ] Hook warns `[SNAPSHOT STALE]` when snapshot is older than 7 days
- [ ] Hook stays silent when snapshot is fresh or missing (graceful degradation)
- [ ] Hook runtime stays under 50ms (no API calls, only file reads + date math)

## Files to Modify
- `lib/setup.sh` — write snapshot hash to state after generation
- `lib/generate.sh` — write `SNAPSHOT_AT` timestamp to state
- `templates/claude/hooks/context-freshness.sh` — add snapshot age check

## Out of Scope
- Auto-regeneration of stale snapshots
- Tracking individual file changes within the snapshot
