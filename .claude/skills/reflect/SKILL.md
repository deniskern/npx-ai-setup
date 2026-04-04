---
name: ais:reflect
description: "Analyze the current session for corrections, architectural discoveries, and stack decisions — convert them into permanent learnings. Triggers: /reflect, 'save learnings', 'capture session insights'."
model: sonnet
mode: plan
allowed-tools: Read, Write, Edit, Glob, AskUserQuestion, mcp__plugin_claude-mem_mcp-search__save_memory
---

Analyze the current session for corrections, architectural discoveries, and stack decisions — convert them into permanent learnings.

## Process

### 1. Recall signals from this session

Review conversation history only. Extract four signal types:
- **CORRECTION**: explicit reversals or “use X instead of Y”
- **AFFIRMATION**: approved patterns worth preserving
- **ARCHITECTURAL**: data flow, boundaries, dependencies, gotchas
- **STACK**: deps, versions, runtime/tooling requirements

Skip questions, clarifications, and one-off choices without a reusable rule.

### 2. Classify each signal by target

- `.agents/context/LEARNINGS.md` → `## Corrections`, `## Conventions`, `## Architecture`, `## Stack`
- `CLAUDE.md` → workflow/process rules in Critical Rules, command/CLI usage in Commands

Most signals belong in `LEARNINGS.md`. If architectural signals imply a lasting ADR and `decisions.md` exists, append only new decisions with the next D-number.

### 3. Draft proposed changes (smart merge)

Read `LEARNINGS.md` and `CLAUDE.md` first. For each signal choose exactly one operation:
- `+ ADD` — new rule, no semantic overlap
- `~ UPDATE` — refine or correct an existing entry
- `- REMOVE` — stale or contradicted entry

Formatting rules:
- Max 1-2 lines per entry
- Corrections/affirmations are directives
- Architecture/stack findings are factual statements

If nothing actionable was found, report that and stop.

### 4. Ask for approval

Use `AskUserQuestion` before writing anything. Show grouped operations, for example:
```text
Proposed changes from this session:

.agents/context/LEARNINGS.md — ## Conventions
+ ADD: Always use kebab-case for script filenames
~ UPDATE: "Use snake_case for variables" → "Use snake_case for variables and function names"

CLAUDE.md — Critical Rules
+ ADD: Never modify template files directly — use generation logic instead

Apply these changes?
Options: [Apply all] [Skip all] [Edit manually]
```

### 5. Write approved changes

Only apply approved items.
- In `LEARNINGS.md`, keep only populated sections: `Corrections`, `Conventions`, `Architecture`, `Stack`
- `ADD` appends, `UPDATE` replaces, `REMOVE` deletes
- In `CLAUDE.md`, write only under the classified section

If `LEARNINGS.md` does not exist, create it with this structure:
```markdown
# Learnings

> Curated session learnings from /reflect. Persistent across updates — generate.sh never touches this file.
```

### 6. Save deliberate decisions to claude-mem

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

If the MCP tool is unavailable, skip silently.

## Rules
- Smart merge: ADD new entries, UPDATE refined entries, REMOVE stale entries — not append-only.
- Never write low-signal observations as rules.
- If a signal is ambiguous, skip it rather than guess.
- If no signals were found, say so and stop — do not invent rules.
- Changes must be explicit and git-trackable — no silent mutations.
- LEARNINGS.md is the primary target — only workflow/process rules go to CLAUDE.md.

## Next Step

After saving learnings, run `/apply-learnings` to distribute new entries from LEARNINGS.md into the correct project context files (`rules/`, `ARCHITECTURE.md`, `CONVENTIONS.md`, etc.). Then run `/commit` to checkpoint all changes, or `/pause` to end the session cleanly.
