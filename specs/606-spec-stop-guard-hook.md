# Spec 606: Spec Stop Guard Hook

> **Status**: Draft
> **Source**: Brainstorm 604 (pilot-shell research)
> **Effort**: M
> **Value**: ★★★

## Problem

When Claude is mid-spec (spec-work, spec-run), it can stop prematurely — user disconnects, context compacts, or Claude incorrectly thinks the task is done. There's no enforcement that a started spec must be completed before the session ends.

## Solution

A Stop hook (`spec-stop-guard.sh`) that checks for in-progress specs before allowing the session to end. If any spec file has `Status: in-progress`, it prints a warning and blocks the stop.

60-second cooldown: if the Stop hook fires again within 60 seconds, it passes through (prevents infinite blocking when Claude legitimately needs to wait for user input).

## Trigger

`Stop` lifecycle event

## Logic

```bash
# Check for in-progress specs
if grep -ql "Status:.*in-progress" specs/*.md 2>/dev/null; then
  # Check cooldown (60s since last block)
  if cooldown not expired:
    print block message
    exit 2
fi
exit 0
```

## Block Message

```
Active spec in progress — don't stop yet.
Run: grep -l "Status:.*in-progress" specs/*.md to see which spec.
Your next action must be a tool call to continue the spec.
To intentionally stop, send another message within 60 seconds.
```

## Files to Create/Modify

- **Create**: `templates/claude/hooks/spec-stop-guard.sh`
- **Modify**: `templates/claude/settings.json` — add Stop hook entry (after transcript-ingest.sh)
- Cooldown state: `/tmp/claude-spec-stop-<proj_hash>.ts`

## Constraints

- Must complete in < 50ms
- Cooldown prevents infinite re-blocking
- Only checks `specs/*.md` — no deep scanning
- Does NOT block when `.continue-here.md` is the only signal (that's the auto-compact use case)

## Out of Scope

- Tracking current task within the spec
- Checking git worktree state
- Blocking for non-spec workflows

## Acceptance Criteria

- [ ] Hook exists at `templates/claude/hooks/spec-stop-guard.sh`
- [ ] Registered in `templates/claude/settings.json` Stop event
- [ ] With in-progress spec: first Stop → blocked with message
- [ ] With in-progress spec: second Stop within 60s → passes through
- [ ] No in-progress spec: Stop → passes through
- [ ] Hook completes in < 50ms
