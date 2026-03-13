---
model: opus
mode: plan
argument-hint: "<url-or-pasted-text>"
allowed-tools: Read, Glob, Grep, WebFetch, WebSearch, AskUserQuestion
---

Systematically evaluates an external idea, article, tool, or pattern against the existing project's Claude Code setup. Input: $ARGUMENTS

## Phase 1 — Acquire Input

### 1a — Parse Input

Inspect `$ARGUMENTS`:

- If it starts with `http://` or `https://`: fetch via WebFetch. Use the prompt: "Extract all Claude Code patterns, workflow commands, agent definitions, hook configurations, settings fields, and tool recommendations mentioned in this content. List each as a named item with a one-sentence description."
- If it looks like a search query (no URL, short phrase): use WebSearch to find the most relevant article or discussion, then WebFetch the result.
- Otherwise: treat the full argument text as pasted content and extract patterns directly by reading it carefully.

Produce a numbered **Proposal Inventory** — every distinct pattern, feature, command, agent, rule, hook, or tool identified in the input. For each item, also note any specific implementation details, code snippets, or concrete approaches mentioned. Format:

```
1. [Name]: [one-line description]
   Implementation detail: [specific code, config, or approach if given]
2. [Name]: [one-line description]
   Implementation detail: [...]
```

If nothing can be extracted, report "No actionable Claude Code patterns found" and stop.

---

## Phase 2 — Build Existing Inventory (Shallow Pass)

Scan the project to understand what we already have. Run all reads in parallel. Scan whichever of these directories exist in the current project:

1. `.claude/commands/` or `templates/commands/` — list all .md filenames
2. `.claude/agents/` or `templates/agents/` — list all .md filenames
3. `.claude/rules/` or `templates/claude/rules/` — list all .md filenames
4. `.claude/hooks/` or `templates/claude/hooks/` — list all .sh filenames
5. `.claude/settings.json` or `templates/claude/settings.json` — note hook types and field names (no need to read full content)
6. `.claude/commands/` (project-local) — list all filenames

Produce a compact **Existing Inventory** by category (names only at this stage).

---

## Phase 3 — Gap Analysis with Deep Comparison

For each item in the Proposal Inventory:

**Step 3a — Initial match**: Use Grep to search `.claude/` and `templates/` directories (whichever exist) for the concept name, key terms, or related keywords. Identify the most likely existing equivalent.

**Step 3b — Deep read for non-obvious cases**: If a potential match is found and it's not immediately clear whether it's REDUNDANT or could be improved:
- Read the **full content** of the matching existing file(s)
- Read any related files referenced in it (e.g., if a command delegates to an agent, read that agent too)
- Compare the proposed implementation detail against our actual code line by line

**Step 3c — Classify** using these categories:

| Classification | Meaning |
|---|---|
| **NEW** | We have nothing equivalent — this fills a genuine gap |
| **PARTIAL** | We have this but the proposal has specific improvements we could adopt (list exactly what) |
| **BETTER** | The proposal is stronger overall — our version should be replaced |
| **REDUNDANT** | We have this fully — our version is equivalent or superior, nothing to borrow |
| **WORSE** | We have this and our version is clearly stronger — the proposal would be a downgrade |

**Critical rule**: Do NOT classify as REDUNDANT without reading the full file and comparing implementation details. Even similar-sounding features may differ in edge case handling, error recovery, scope, or specific code patterns.

---

## Phase 4 — Output: Findings Table

```
## Evaluation Results

**Source**: [URL or "inline text"]
**Evaluated**: [date]

### Findings

| # | Pattern | Class | Existing File | Detail |
|---|---------|-------|---------------|--------|
| 1 | name    | NEW   | —             | —      |
| 2 | name    | PARTIAL | [commands-dir]/foo.md | Proposal adds: [specific line/approach missing from ours] |
| 3 | name    | BETTER  | [agents-dir]/bar.md   | Proposal is stronger because: [specific reason] |
| 4 | name    | REDUNDANT | [commands-dir]/baz.md | Our version covers this fully |
| 5 | name    | WORSE   | [hooks-dir]/general.md | Our version handles: [what theirs misses] |
```

For **PARTIAL** and **BETTER** findings, the Detail column must be specific:
- Quote or describe the exact code/approach from the proposal that we lack
- Reference the exact line or section in our existing file where this could be added
- Example: "Proposal adds `tsc --noEmit` after TS edits; our `post-edit-lint.sh:7` only runs ESLint"

```
### Summary
- NEW: N | PARTIAL: N | BETTER: N | REDUNDANT: N | WORSE: N

### Overhead Assessment (NEW, PARTIAL, BETTER only)

| # | Pattern | Maintenance | Integration | User Value | Adopt? |
|---|---------|-------------|-------------|------------|--------|
| 1 | name    | low         | low         | high       | YES    |

### Verdict

[One paragraph: overall assessment. Highlight the highest-value PARTIAL/BETTER/NEW findings.]
```

---

## Phase 5 — Adoption Candidates

List all NEW, PARTIAL, and BETTER findings with medium/high user value:

```
## Adoption Candidates

1. [Pattern] — [one-line rationale]
   Class: NEW | Action: Create spec for `templates/commands/[name].md`

2. [Pattern] — [one-line rationale]
   Class: PARTIAL | Specific improvement: [exact change to make]
   Action: Modify `templates/claude/hooks/[file].sh` via spec — add [what]

3. [Pattern] — [one-line rationale]
   Class: BETTER | Action: Replace `templates/agents/[name].md` via spec
```

---

## Phase 6 — Spec Creation Gate

Use `AskUserQuestion` with multiSelect: true. Options: one per adoption candidate, plus "Keine — spaeter entscheiden".

If the user selects items: output pre-filled `/spec` commands with enough detail that the spec writer understands the exact change needed. For PARTIAL items, include the specific code or line to add.

Example:
```
Run these commands to create specs:

  /spec "Add tsc --noEmit to post-edit-lint.sh after .ts/.tsx edits — only when tsconfig.json exists in project root; insert after ESLint block at line 7"
```

---

## Rules

- Read-only: never write, create, or modify any file
- Never auto-create specs — only recommend `/spec` commands
- Always read the full existing file before classifying as REDUNDANT
- Scoped to Claude Code AI dev environment patterns only
- If WebFetch fails, ask user to paste content directly
