---
name: ais:resume
description: "Restores session state from `.claude/session-state.json` plus `.continue-here.md` and routes to the next action. Run at the start of a new session."
model: haiku
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
---

Restores session state from `.claude/session-state.json` and `.continue-here.md`, then routes to the next action. Run at the start of a new session.

## Process

### Step 1: Detect structured handoff state

Check if `.claude/session-state.json` exists.

**If found**: Read it first, then read `.continue-here.md` if it exists. Present the combined state as a structured report:
```
Session State Restored
======================
Active spec: <value from session-state.json>
Phase:      <value from session-state.json>
Next action:<value from session-state.json>
Branch:     <current branch from git>
Remaining:  <value from .continue-here.md if present, else "See active spec">
Blockers:   <value from .continue-here.md if present, else "None recorded">
```

**If not found**: Fall back to `.continue-here.md`, then to context reconstruction:
- Run `git log --oneline -10` for recent work
- Run `ls specs/*.md 2>/dev/null` to find open specs
- Report: "No handoff file found. Reconstructed from git log and spec board."
- Show the last 5 commits and any in-progress specs.

### Step 2: Detect incomplete specs

Scan `specs/` for any spec with status `in-progress`. If found, list them:
```
Open specs:
  #NNN <title> — in-progress (N/M steps done)
```

### Step 3: Route to next action

Use `AskUserQuestion` to ask:
```
What do you want to do?
```
Options:
- `Continue spec work — resume from where I left off`
- `Review state — show me the handoff files`
- `Start fresh — ignore handoff, begin new work`
- `Clean up — delete the handoff files (done with them)`

**Continue spec work**: Report the active spec and first unchecked step. Suggest: "Run `/spec-work NNN` to continue."

**Review state**: Output the raw `.claude/session-state.json` first, then `.continue-here.md` if it exists.

**Start fresh**: Acknowledge and stop. User drives next action.

**Clean up**: Delete `.claude/session-state.json` and `.continue-here.md`, commit the deletion (`git add -u && git commit -m "chore: clear session handoff"`), confirm.

## Rules
- Never modify source files — read-only except for cleanup action.
- If multiple specs are `in-progress`, list all and let the user choose via AskUserQuestion.
- If `.claude/session-state.json` is malformed or unreadable, fall back to `.continue-here.md`, then to git log reconstruction.

## Next Step

After reviewing state, run `/spec-work NNN` to continue an active spec, or describe a new task to start fresh work.
