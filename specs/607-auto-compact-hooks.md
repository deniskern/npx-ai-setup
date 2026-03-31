# Spec 607: Auto Compact Hooks (PreCompact + SessionStart)

> **Status**: Draft
> **Source**: Brainstorm 604 (pilot-shell research)
> **Effort**: M
> **Value**: ★★★

## Problem

`/pause` and `/resume` are manual skills for preserving session state across context compaction. When compaction fires automatically (at 80%), the user must remember to run `/pause` first — often they don't, and active spec context is lost.

## Solution

Automate the pause/resume cycle with two hooks:

1. **PreCompact hook** (`pre-compact-state.sh`): Before compaction, checks for in-progress specs and writes a brief state file to `.claude/compact-state.json`.
2. **SessionStart hook** (`post-compact-restore.sh`, matcher: `compact`): After compaction, reads the state file and injects it into context as a system message.

## Data Captured (PreCompact)

```json
{
  "active_specs": ["specs/NNN-feature-name.md"],
  "spec_status": "in-progress",
  "timestamp": "2026-04-01T10:00:00Z"
}
```

## Restoration Message (SessionStart/compact)

```
[Context Restored After Compaction]
Active spec: specs/NNN-feature-name.md (in-progress)
Resume with: /spec-work NNN or continue current task.
```

## Files to Create/Modify

- **Create**: `templates/claude/hooks/pre-compact-state.sh`
- **Create**: `templates/claude/hooks/post-compact-restore.sh`
- **Modify**: `templates/claude/settings.json`:
  - Replace the existing PreCompact git-commit hook with a version that also writes state
  - Add SessionStart hook with matcher `compact`
- State file: `.claude/compact-state.json` (gitignored)

## Design Decisions

- State file in `.claude/` (project-local, survives within a project)
- `.claude/compact-state.json` added to `.gitignore` (session-scoped, not committed)
- PreCompact hook must complete in < 10s (current git commit hook already uses 10s timeout)
- PostCompact restore must complete in < 5s

## Constraints

- No API calls in either hook
- Graceful failure — if state write fails, do nothing (don't break compaction)
- Works when no in-progress spec exists (writes empty state, restores silently)

## Out of Scope

- Full `/pause` functionality (context summary, continue-here.md generation)
- Worktree state capture
- Integration with claude-mem

## Acceptance Criteria

- [ ] `pre-compact-state.sh` writes `.claude/compact-state.json` with active spec info
- [ ] `post-compact-restore.sh` reads state and prints restoration message when spec was active
- [ ] `.claude/compact-state.json` added to `.claudeignore` or `.gitignore`
- [ ] Both hooks registered in `templates/claude/settings.json`
- [ ] When no active spec: no output from restore hook
- [ ] PreCompact hook < 10s, PostCompact restore hook < 5s
