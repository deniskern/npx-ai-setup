---
name: ais:pause
description: "Captures session state into `.continue-here.md` plus `.claude/session-state.json` and commits the Markdown handoff. Run before ending a session."
model: haiku
allowed-tools: Read, Write, Bash, Glob, Grep, AskUserQuestion
---

Captures current session state into `.continue-here.md` and `.claude/session-state.json`, then commits the Markdown handoff as a WIP checkpoint. Run before ending a session.

## Process

1. **Gather state** (zero LLM tokens for the raw data):
   ```
   ! git status --short
   ! git log --oneline -10
   ! ls specs/*.md 2>/dev/null | head -20
   ```

2. **Determine position**: Read the most recent open spec (status `in-progress` or `draft` with checked steps). This is the active working context.

3. **Gather open specs**: List all specs in `specs/` that are NOT `completed`. For each, note the spec ID, title, status, and how many steps are checked vs total.

3a. **Validate spec consistency**: Flag any spec where `status: in-review` but 0 steps are checked — these are stale status entries and go into `## Blockers`.

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
<Specs with status mismatch (e.g. in-review but 0 steps checked), blocked specs, or known issues. "None" if clean.>
```

6. **Write `.claude/session-state.json`** as the canonical machine-readable handoff:

```json
{
  "updated_at": "<ISO date and time>",
  "source": "manual-pause",
  "phase": "paused",
  "active_spec": "<spec path or empty string>",
  "active_specs": ["<spec path>", "..."],
  "next_action": "<short next step>",
  "handoff_markdown": ".continue-here.md",
  "has_active_spec": true
}
```

Rules:
- `active_spec` is the primary spec from `## Position`
- `active_specs` includes every open spec still relevant to the handoff
- `next_action` should match the first actionable item from `## Remaining`
- Keep this file small and machine-readable; `.continue-here.md` remains the human narrative

7. **Commit the handoff file**:
   ```
   git add .continue-here.md
   git commit -m "chore: WIP session handoff"
   ```

8. **Confirm**: Report "Session paused. Run `/resume` to restore state in the next session."

## Rules
- Never stage files other than `.continue-here.md` in the WIP commit.
- If `.continue-here.md` already exists, overwrite it — only the latest handoff is kept.
- Always refresh `.claude/session-state.json` together with the Markdown handoff.
- If `git commit` fails (nothing to commit), still write the file but skip the commit step.

## Next Step

State saved. Start a new Claude Code session and run `/resume` to restore context and continue from where you left off.
