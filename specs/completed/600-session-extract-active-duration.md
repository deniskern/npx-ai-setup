# Spec: Session Extract Active Duration

> **Spec ID**: 600 | **Created**: 2026-03-31 | **Status**: completed | **Complexity**: medium | **Branch**: —

## Goal
Make `session-extract.sh` report session duration in a way that separates active work from idle wall time so session-optimize metrics are trustworthy.

## Context
`/session-optimize` currently depends on `.claude/scripts/session-extract.sh` for duration metrics, but the script uses first-to-last event timestamps and overstates active work on long-idle sessions. Relevant skills: `spec`, `session-optimize`.

### Verified Assumptions
- `session-optimize` consumes the printed `duration` field as an input metric — Evidence: `.claude/skills/session-optimize/SKILL.md` | Confidence: High | If Wrong: only reporting text changes are needed, not metric semantics.
- Current duration is wall time, not active time — Evidence: `.claude/scripts/session-extract.sh` computes `min(timestamp)` to `max(timestamp)` | Confidence: High | If Wrong: the JSONL format already encodes session activity and should be read directly.
- A backward-compatible text output is preferable to a breaking format change — Evidence: session metrics are consumed manually and by ad hoc scripts | Confidence: Medium | If Wrong: the script can switch to a new schema without dual reporting.

## Steps
- [x] Step 1: Refactor the Python block in `.claude/scripts/session-extract.sh` to compute both wall-clock duration and an active-duration metric that caps idle gaps between events.
- [x] Step 2: Define and document the idle-gap heuristic inside `.claude/scripts/session-extract.sh` so future session analysis uses a stable interpretation of "active" time.
- [x] Step 3: Update the session summary output in `.claude/scripts/session-extract.sh` to print the new duration fields without breaking the rest of the metrics layout.
- [x] Step 4: Update `.claude/skills/session-optimize/SKILL.md` so its metrics guidance references the corrected duration semantics and does not treat raw wall time as friction by default.
- [x] Step 5: Add a regression test or fixture-driven verification path for `.claude/scripts/session-extract.sh` that proves idle gaps no longer inflate active duration.
- [x] Step 6: Run the extractor against representative local session data and verify the reported durations are plausible for both short active sessions and long idle sessions.

## Acceptance Criteria
- [x] A session with a large idle gap reports a materially smaller active duration than wall duration.
- [x] The extractor output still includes start time, tools, skills, models, subagents, and token estimates in a readable per-session block.
- [x] `session-optimize` documentation no longer implies that printed duration is simple first-to-last wall time.
- [x] Verification demonstrates at least one fixture or real session where the old logic would overreport duration and the new logic does not.

## Files to Modify
- `.claude/scripts/session-extract.sh` - compute and print active duration alongside wall duration
- `.claude/skills/session-optimize/SKILL.md` - align downstream guidance with corrected duration semantics
- `tests/` or a new lightweight fixture path - cover idle-gap duration behavior if no existing test home fits the script

## Out of Scope
- Adding claude-mem fallback behavior to `session-optimize`
- Redesigning the full session metrics schema beyond duration semantics
- Reworking model/tool aggregation in `session-extract.sh`
