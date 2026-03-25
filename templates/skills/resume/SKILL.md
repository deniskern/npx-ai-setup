---
description: "Restores session state from `.continue-here.md` and routes to the next action. Run at the start of a new session."
model: haiku
allowed-tools: Read, Bash, Glob, Grep, AskUserQuestion
disable-model-invocation: true
---

Restores session state from `.continue-here.md` and routes to the next action. Run at the start of a new session.

## Process

### Step 1: Detect handoff file

Check if `.continue-here.md` exists.

**If found**: Read it and present its contents as a structured status report:
```
Session State Restored
======================
Position:   <value from ## Position>
Branch:     <current branch from git>
Remaining:  <value from ## Remaining>
Blockers:   <value from ## Blockers>
```

**If not found**: Fall back to context reconstruction:
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
- `Review state — show me the full .continue-here.md`
- `Start fresh — ignore handoff, begin new work`
- `Clean up — delete .continue-here.md (done with it)`

**Continue spec work**: Report the active spec and first unchecked step. Suggest: "Run `/spec-work NNN` to continue."

**Review state**: Output the raw `.continue-here.md` contents in full.

**Start fresh**: Acknowledge and stop. User drives next action.

**Clean up**: Delete `.continue-here.md`, commit the deletion (`git add -u && git commit -m "chore: clear session handoff"`), confirm.

## Rules
- Never modify source files — read-only except for cleanup action.
- If multiple specs are `in-progress`, list all and let the user choose via AskUserQuestion.
- If `.continue-here.md` is malformed or unreadable, fall back to git log reconstruction.

## Next Step

After reviewing state, run `/spec-work NNN` to continue an active spec, or describe a new task to start fresh work.
