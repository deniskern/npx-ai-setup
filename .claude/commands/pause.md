---
model: haiku
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
---

Captures current session state into `.continue-here.md` and commits it as a WIP checkpoint. Run before ending a session.

## Process

1. **Gather state** (zero LLM tokens for the raw data):
   ```
   ! git status --short
   ! git log --oneline -10
   ! ls specs/*.md 2>/dev/null | head -20
   ```

2. **Determine position**: Read the most recent open spec (status `in-progress` or `draft` with checked steps). This is the active working context.

3. **Gather open specs**: List all specs in `specs/` that are NOT `completed`. For each, note the spec ID, title, status, and how many steps are checked vs total.

4. **Gather recent decisions**: Check `decisions.md` if it exists — note the last 3 entries.

5. **Write `.continue-here.md`** with exactly these 5 sections:

```
# Continue Here

Generated: <ISO date and time>

## Position
<Active spec ID and title, or "No active spec — last commit was: <message>">
<Current branch>

## Completed
<Bullet list of commits since last non-WIP commit, or "Nothing committed this session">

## Remaining
<Bullet list of unchecked steps from the active spec, or "No remaining steps identified">

## Decisions
<Last 3 entries from decisions.md, or "No decisions recorded">

## Blockers
<Any blocked specs or known issues, or "None">
```

6. **Commit the handoff file**:
   ```
   git add .continue-here.md
   git commit -m "chore: WIP session handoff"
   ```

7. **Confirm**: Report "Session paused. Run `/resume` to restore state in the next session."

## Rules
- Never stage files other than `.continue-here.md` in the WIP commit.
- If `.continue-here.md` already exists, overwrite it — only the latest handoff is kept.
- If `git commit` fails (nothing to commit), still write the file but skip the commit step.

## Next Step

State saved. Start a new Claude Code session and run `/resume` to restore context and continue from where you left off.
