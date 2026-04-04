---
name: ais:reflect
description: "Analyze the current session for corrections, architectural discoveries, and stack decisions — convert them into permanent learnings."
model: sonnet
mode: plan
allowed-tools: Read, Write, Edit, Glob, AskUserQuestion, mcp__plugin_claude-mem_mcp-search__save_memory
---

Analyze the current session for corrections, architectural discoveries, and stack decisions — convert them into permanent learnings.

## Process

### 1. Recall signals from this session

Review the conversation history in your context. Look for four categories of signals:

**CORRECTION signals** (explicit corrections — must apply):
- "don't do X", "stop doing Z", "not like that"
- "use Y instead", "wrong approach", "revert that"
- "I said X, not Y", "that's incorrect"

**AFFIRMATION signals** (approved approaches — apply if consistent):
- "good", "exactly", "yes that's right", "keep doing that"
- "that's the right way", "perfect", "this is how I want it"

**ARCHITECTURAL signals** (discovered patterns, component relationships, gotchas):
- Discovered data flow paths or component dependencies
- Codebase gotchas ("this file actually controls X", "Y depends on Z")
- Structural patterns ("all routes go through middleware X", "state lives in Y")
- Integration boundaries ("service A talks to B via C")
- After detecting architectural signals, also check if `decisions.md` exists in the project root. If yes, append new architectural decisions as rows using the next sequential D-number. Only append decisions not already present in the register.

**STACK signals** (new deps, version decisions, tool choices discovered at runtime):
- New dependency added or removed during session
- Version constraint discovered ("library X requires Node >= 18")
- Tool choice made ("use pnpm not npm", "vitest not jest")
- Runtime requirement discovered ("needs Redis running locally")

Only process CORRECTION, AFFIRMATION, ARCHITECTURAL, and STACK signals. Skip general questions, clarifications, and one-off decisions without a clear general rule.

### 2. Classify each signal by target

For each signal found, classify where it belongs:

| Signal type | Target | Section |
|---|---|---|
| Coding style, naming, patterns, tooling choices | `.agents/context/LEARNINGS.md` | `## Conventions` |
| Component relationships, data flow, gotchas | `.agents/context/LEARNINGS.md` | `## Architecture` |
| Dependencies, versions, runtime requirements | `.agents/context/LEARNINGS.md` | `## Stack` |
| Corrections and approved approaches | `.agents/context/LEARNINGS.md` | `## Corrections` |
| Project workflow, process rules, safety rules | `CLAUDE.md` | Critical Rules section |
| Tool usage, commands, CLI patterns | `CLAUDE.md` | Commands section |

Most signals go to `.agents/context/LEARNINGS.md`. Only workflow/process rules and CLI patterns go to `CLAUDE.md`.

### 3. Draft proposed changes (smart merge)

Read `.agents/context/LEARNINGS.md` and `CLAUDE.md` first to detect existing entries.

For each signal, determine the **operation type**:

- **`+ ADD`** — New entry, no semantic overlap with existing entries
- **`~ UPDATE`** — Existing entry needs refinement (e.g. more specific, corrected, expanded). Reference the existing entry being replaced.
- **`- REMOVE`** — Existing entry is now stale, contradicted, or superseded by a new signal. Reference the entry being removed.

Draft rules:
- Maximum 1-2 lines per entry
- Corrections/affirmations: phrase as a directive ("Always X", "Never Y", "Use X instead of Y")
- Architectural findings: phrase as a factual statement ("Component X depends on Y", "All API calls route through Z")
- Stack findings: phrase as a factual statement ("Requires Node >= 18", "Uses pnpm as package manager")

If no actionable signals were found in this session, report that clearly and stop.

### 4. Show proposed changes for approval

Use AskUserQuestion to present all proposed operations and ask for approval before writing anything.
Format the proposal showing operation type, target section, and content:
```
Proposed changes from this session:

.agents/context/LEARNINGS.md — ## Conventions
+ ADD: Always use kebab-case for script filenames
~ UPDATE: "Use snake_case for variables" → "Use snake_case for variables and function names"
- REMOVE: "Prefer camelCase for JS functions" (contradicted by project convention)

.agents/context/LEARNINGS.md — ## Architecture
+ ADD: All API calls route through middleware X

CLAUDE.md — Critical Rules
+ ADD: Never modify template files directly — use generation logic instead

Apply these changes?
Options: [Apply all] [Skip all] [Edit manually]
```

### 5. Write approved changes

Only write items the user approved. For each approved item:

**For `.agents/context/LEARNINGS.md`:**
- If the file does not exist, create it with the header and relevant sections
- **ADD**: Append the entry under the matching section header
- **UPDATE**: Replace the old entry with the new one using the Edit tool
- **REMOVE**: Delete the entry using the Edit tool
- Keep the file organized with these sections: `## Corrections`, `## Conventions`, `## Architecture`, `## Stack`
- Only create sections that have entries — do not add empty sections

**LEARNINGS.md format:**
```markdown
# Learnings

> Curated session learnings from /reflect. Persistent across updates — generate.sh never touches this file.

## Corrections
- Always use X instead of Y — reason
- Never do Z in this codebase — reason

## Conventions
- Use kebab-case for script filenames

## Architecture
- Component X depends on Y for state management
- All API calls route through middleware Z

## Stack
- Requires Node >= 18 for native fetch
- Uses pnpm as package manager
```

**For `CLAUDE.md`:**
- **ADD**: Append under "Critical Rules" or "Commands" as classified
- **UPDATE**: Replace the old entry with the Edit tool
- **REMOVE**: Delete the entry with the Edit tool

### 6. Save deliberate decisions to claude-mem (automatic, no approval needed)

After writing approved changes, automatically call `mcp__plugin_claude-mem_mcp-search__save_memory` for every approved **CORRECTION signal**.

Do NOT save AFFIRMATION, ARCHITECTURAL, or STACK signals — those live in project files and are always loaded.

For each approved correction, call save_memory with:
- `title`: `decision: [component or context] — [what was decided]`
  Example: `decision: SliderWrapper — keep ClientOnly without SSR fallback`
- `text`: structured block:
  ```
  Project: [project name from git remote or directory name]
  Context: [component, file, or feature area]
  Decision: [what was deliberately chosen]
  Avoid: [what Claude must NOT suggest — the rejected alternative]
  Reason: [why, one sentence]
  ```

This enables semantic retrieval in future sessions: if Claude is about to suggest the rejected approach, the search match surfaces the saved decision before the suggestion is made.

If `mcp__plugin_claude-mem_mcp-search__save_memory` is not available (plugin not installed), skip this step silently — do not error.

## Rules
- Smart merge: ADD new entries, UPDATE refined entries, REMOVE stale entries — not append-only.
- Never write low-signal observations as rules.
- If a signal is ambiguous, skip it rather than guess.
- If no signals were found, say so and stop — do not invent rules.
- Changes must be explicit and git-trackable — no silent mutations.
- LEARNINGS.md is the primary target — only workflow/process rules go to CLAUDE.md.

## Next Step

After saving learnings, run `/apply-learnings` to distribute new entries from LEARNINGS.md into the correct project context files (`rules/`, `ARCHITECTURE.md`, `CONVENTIONS.md`, etc.). Then run `/commit` to checkpoint all changes, or `/pause` to end the session cleanly.
