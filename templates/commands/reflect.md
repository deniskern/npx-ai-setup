---
model: opus
mode: plan
allowed-tools: Read, Write, Edit, Glob, AskUserQuestion, mcp__plugin_claude-mem_mcp-search__save_memory
---

Analyze the current session for corrections, architectural discoveries, and stack decisions — convert them into permanent rules.

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

| Signal type | Target file |
|---|---|
| Coding style, naming, patterns, tooling choices | `.agents/context/CONVENTIONS.md` |
| Project workflow, process rules, safety rules | `CLAUDE.md` Critical Rules section |
| Tool usage, commands, CLI patterns | `CLAUDE.md` Commands section |
| Component relationships, data flow, gotchas, structural patterns | `.agents/context/ARCHITECTURE.md` |
| Dependencies, versions, runtime requirements, tool choices | `.agents/context/STACK.md` |

### 3. Draft proposed additions

Read `CLAUDE.md`, `.agents/context/CONVENTIONS.md`, `.agents/context/ARCHITECTURE.md`, and `.agents/context/STACK.md` first to avoid duplicates.

For each signal, draft a rule or fact addition:
- Maximum 1-2 lines per entry
- Corrections/affirmations: phrase as a directive ("Always X", "Never Y", "Use X instead of Y")
- Architectural findings: phrase as a factual statement ("Component X depends on Y", "All API calls route through Z")
- Stack findings: phrase as a factual statement ("Requires Node >= 18", "Uses pnpm as package manager")
- Do NOT duplicate content already present in the target file

If no actionable signals were found in this session, report that clearly and stop.

### 4. Show proposed changes for approval
Use AskUserQuestion to present the proposed additions and ask for approval before writing anything.
Format the proposal as a diff preview showing exactly what will be appended to each file.
Example:
```
Proposed additions from this session:

File: .agents/context/CONVENTIONS.md
+ Always use kebab-case for script filenames

File: CLAUDE.md (Critical Rules)
+ Never modify template files directly — use generation logic instead

Apply the same format for `.agents/context/ARCHITECTURE.md` and `.agents/context/STACK.md` when needed.

Apply these changes?
Options: [Apply all] [Skip all] [Edit manually]
```

### 5. Write approved changes

Only write items the user approved. For each approved item:
- Append to the end of the relevant section (never delete or rewrite existing content)
- If appending to CONVENTIONS.md, add under the most relevant existing section header
- If appending to CLAUDE.md, add under "Critical Rules" or "Commands" as classified
- If appending to ARCHITECTURE.md, add under the most relevant existing section header (or create a new one if none fits)
- If appending to STACK.md, add under the most relevant existing section header (or create a new one if none fits)
- Keep additions minimal and self-contained

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
- Never delete or overwrite existing rules — append only.
- Never write low-signal observations as rules.
- If a signal is ambiguous, skip it rather than guess.
- If no signals were found, say so and stop — do not invent rules.
- Changes must be explicit and git-trackable — no silent mutations.
