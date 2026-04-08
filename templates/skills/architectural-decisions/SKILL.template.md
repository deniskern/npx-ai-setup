---
name: architectural-decisions
description: "ALWAYS use this skill when asked WHY something is built a certain way, why a specific technology was chosen, or why an architectural approach was taken."
user-invocable: false
effort: low
allowed-tools: Read, Glob, Grep, Bash
---

# Architectural Decisions

Answers WHY-questions about code and architecture by reading documented decisions before reasoning from context.

## Trigger

Activate when the user asks:
- "Why is X implemented this way?"
- "Why does this use X instead of Y?"
- "What was the reason for Z?"
- "Why not use [alternative]?"
- Any question containing "why", "reason", "rationale", "decision" about code structure or technology choices

## Process

Execute these steps in order, stop when you have enough to answer:

### 1. decisions.md

```bash
[ -f decisions.md ] && cat decisions.md
```

Filter rows matching the topic. A matching row answers the question directly — cite the row number and rationale.

### 2. WHY-Markers in Source Files

Search for inline decision markers near the relevant code:

```bash
grep -rn "# WHY:\|# DECISION:\|# TRADEOFF:\|# ADR:" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.rb" --include="*.sh" . 2>/dev/null | head -40
```

If the file/module in question is known, search it directly first:
```bash
grep -n "# WHY:\|# DECISION:\|# TRADEOFF:\|# ADR:" <relevant-file>
```

### 3. Git Log (ADR commits)

```bash
git log --oneline --grep="ADR\|decision\|why\|chose\|switch\|replace\|migrate" -- <relevant-path> 2>/dev/null | head -20
```

Follow up with `git show <hash>` on the most relevant commit to read the full message.

### 4. Fallback

If no documented decision is found in steps 1-3:
- State clearly: "No documented decision found for this."
- Offer a brief inference based on code structure, but label it as inference, not fact.
- Suggest documenting the decision: "Add a row to `decisions.md` to capture this for the future."

## Output Format

**If documented decision found:**
> **Decision [#N / commit abc1234]:** [rationale from source]
> Source: `decisions.md` / `path/to/file.ts:42` / `git show abc1234`

**If inferred only:**
> **No documented decision found.** Inference: [reasoning]. Consider adding to `decisions.md`.

Keep answers under 150 words unless the decision has multiple relevant tradeoffs.

## Next Step

If no decision is documented: suggest `/spec` to plan capturing it in `decisions.md`.
