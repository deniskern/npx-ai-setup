---
description: "Deep-researches an external repository, tool, or pattern against the existing project's Claude Code setup. Produces a comprehensive brainstorm document with prioritized adoption candidates."
model: opus
mode: plan
argument-hint: "<github-url or article-url>"
allowed-tools: Read, Glob, Grep, WebFetch, WebSearch, AskUserQuestion, Agent, Bash
---

Deep-researches an external repository, tool, or pattern against the existing project's Claude Code setup. Produces a comprehensive brainstorm document with prioritized adoption candidates. Input: $ARGUMENTS

## Phase 1 — Acquire & Scrape Deep

### 1a — Detect Input Type

- **GitHub repo URL** (contains `github.com`): enter **Deep Repo Scrape** mode (1b)
- **Article/blog URL**: WebFetch → extract patterns → proceed to Phase 2 with summary
- **Search query** (no URL): WebSearch → WebFetch best result → proceed to Phase 2
- **Pasted text**: extract patterns directly → proceed to Phase 2

### 1b — Deep Repo Scrape (GitHub repos only)

**Goal**: Read EVERY relevant file, not just the README.

1. Identify key directories to scrape. For Claude Code repos, this typically includes:
   `.claude/commands/`, `.claude/agents/`, `.claude/skills/`, `.claude/hooks/`, `.claude/rules/`,
   `scripts/`, `hooks/`, `agents/`, `mcp-server/`, `src/`

2. **Spawn parallel Agent workers** (model: haiku for all scraping agents) to scrape each directory:
   - Agent 1: List + read all command files
   - Agent 2: List + read all agent/persona files
   - Agent 3: List + read all skill files
   - Agent 4: List + read all hook/script files
   - Agent 5: Read README, config files, package.json

   Each agent uses `defuddle parse <url> --md` for directory listing, then `WebFetch` on raw GitHub URLs
   (`https://raw.githubusercontent.com/OWNER/REPO/main/PATH`) for file content.
   Agents must return **full file content**, not summaries.

3. In parallel, **read all our existing files** via a separate Agent:
   - All files in `templates/commands/`, `templates/agents/`, `templates/hooks/`
   - All files in `.claude/commands/`, `.claude/agents/`, `.claude/rules/`
   - `lib/plugins.sh`, `bin/ai-setup.sh` (for integration context)

4. Compile a **complete inventory** of both sides:
   ```
   EXTERNAL: [count] commands, [count] agents, [count] skills, [count] hooks, [count] scripts
   OURS:     [count] commands, [count] agents, [count] rules, [count] hooks
   ```

---

## Phase 2 — Existing Inventory Match

For each external item, find the closest match in our codebase:

| External Item | Our Equivalent | Status |
|--------------|---------------|--------|
| [name]       | [our file]    | ✅ Covered / ⚠️ Partial / ❌ Missing |

Group into:
- **Already covered**: We have an equivalent or better version
- **Partially covered**: We have something similar but theirs adds specific improvements
- **New**: We have nothing equivalent

---

## Phase 3 — Deep Comparison (the valuable part)

### 3a — Line-by-line comparison for "Partially covered" items

For each partially covered item:
1. Read our file completely
2. Read their file completely
3. Identify **specific sentences, patterns, or techniques** worth adopting
4. Quote the exact line/approach from theirs that we lack

Example output:
```
Their `/review` has: "Check for stub code, placeholder implementations, TODO-marked incomplete code"
Our `/review` at line 24 lacks this — would catch AI-generated incomplete code.
```

### 3b — Architecture patterns analysis

Look beyond individual files for **systemic patterns**:
- How do they structure agent delegation? (routing, when_to_use/avoid_if)
- What quality gates exist? (hooks that validate output)
- What's scripted vs. LLM-driven? (token savings opportunities)
- What's their testing/validation approach?

### 3c — Strategic analysis

- **Token economics**: Would adopting X save tokens? How much?
- **Quality impact**: Would adopting Y improve output consistency?
- **Maintenance cost**: Would adopting Z add maintenance burden?
- **Team impact**: Would this help onboarding new developers?

---

## Phase 4 — Create Brainstorm Document

Write a comprehensive brainstorm document to `specs/NNN-research-[source-name].md`:

```markdown
# Brainstorm: [Source Name] Adaptionen für [project]

> **Source**: [URL]
> **Erstellt**: [date]
> **Zweck**: Research welche Patterns adaptierbar sind

## Bestandsvergleich: Was haben wir schon?
[Table of covered items]

## Kandidaten für Adaption
[For each NEW/PARTIAL item: description, what it does, our gap, effort, recommendation]

## Einzelne Sätze/Patterns zum Adaptieren
[Specific lines worth stealing — even from "covered" items]

## Architektur-Patterns
[Systemic patterns worth adopting]

## Gesamtranking nach Aufwand/Nutzen
[Ranked table with: Item, Value ★, Aufwand, Empfehlung]
```

---

## Phase 5 — Interview & Prioritize

Use `AskUserQuestion` to discuss findings with the user:

1. **First question**: Present top 5 findings, ask which areas to explore deeper
2. **Follow-up rounds**: Based on user interest, dive into specific areas
3. **Strategic questions**: Ask about team context, priorities, constraints

Continue interviewing until the user signals they're satisfied. Minimum 2 rounds.

---

## Phase 5.5 — Philosophy Check (mandatory before specs)

Before creating any specs, validate each candidate against the project's core principles.

1. Read `CONCEPT.md` (or `.agents/context/CONCEPT.md`) and `decisions.md` if they exist
2. For each remaining candidate, check:
   - Does it ADD safety or REMOVE it? (npx-ai-setup is safety-first — reject anything that removes guardrails)
   - Does it belong in the base setup or in a boilerplate/stack-specific layer?
   - Does an existing feature already cover this? (read the actual command/agent/hook, not just the name)
3. Present a suitability verdict per candidate: GO / PIVOT (right idea, wrong layer) / SKIP (doesn't fit)
4. Only GO candidates proceed to Phase 6

This phase exists because /research tends to generate enthusiasm — scraping a repo reveals many patterns, and the interview selects favorites. Without this gate, specs get created and then cancelled after deeper review. The gate saves that wasted effort.

---

## Phase 6 — Spec Creation Gate

After philosophy check, present final prioritized list of GO candidates only:

Use `AskUserQuestion` with multiSelect: true — one option per adoption candidate.

For selected items: create actual spec files (not just `/spec` commands).
Each spec should reference the brainstorm document for context.

---

## Rules

- **Deep scrape**: For GitHub repos, read EVERY file — not just README
- **Full content**: Agents must return complete file content, not summaries
- **Parallel**: Use Agent workers for scraping — never sequentially fetch 20+ files
- **Specific**: Quote exact lines/approaches, not vague comparisons
- **Honest**: If our version is better, say so. Don't invent improvements that don't exist
- **Strategic**: Always include token economics and maintenance cost analysis
- If WebFetch/defuddle fails for a URL, ask user to paste content or try raw GitHub URLs
- The brainstorm document is the primary deliverable — it persists across sessions

## Auto-Link in README

After creating the brainstorm document, append the researched source to the `### Evaluated` subsection under `## Links` in `README.md`:
- Format: `- [Source Name](URL)` — add below the existing evaluated links
- Only add if the URL is not already listed anywhere in README.md
- Source name: use the repo name, tool name, or article title (short, descriptive)

## Next Step

After the brainstorm document is saved to `specs/`, run `/spec NNN` on any selected adoption candidate to create an implementation spec, or run `/spec-board` to see the full pipeline.
