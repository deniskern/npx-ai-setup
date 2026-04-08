---
name: pre-modification
description: "ALWAYS run this BEFORE modifying, refactoring, or restructuring existing code across multiple files or introducing new architectural layers."
user-invocable: false
---

# Pre-Modification Risk Assessment

Automatic pre-flight check before risky code changes. Delegates to `code-architect` for blast-radius analysis and returns a GO / CAUTION / STOP verdict.

## Trigger Conditions

Run this skill when the task involves ANY of:
- Changes to 3 or more existing files
- Refactoring, restructuring, migrating, or replacing existing code
- Introducing new abstractions (services, modules, layers, shared utilities)
- Cross-system changes (frontend + backend + DB in the same task)
- Keywords: "refactor", "restructure", "migrate", "rewrite", "extract", "split", "merge"

## Skip Conditions

Do NOT run when:
- Single-file edits without system-wide impact
- Adding new files that don't modify existing behaviour
- Style, lint, or copy fixes
- Bug fixes in isolated functions with no shared state

---

## Step 1 — Assess Scope

Before calling code-architect, extract from the task description:
- **Target files**: Which files will be modified? List them explicitly.
- **Change type**: Refactor / Migration / New Abstraction / Cross-System / Other
- **Entry points affected**: Are public APIs, exported functions, or shared interfaces touched?

If fewer than 3 files are affected AND no architectural keywords are present, stop here and proceed without review.

## Step 2 — Delegate to code-architect

Use the Agent tool to invoke `code-architect` with the following prompt:

```
Pre-modification risk assessment requested.

Task description: [paste the user's task description]

Target files:
[list of files to be modified]

Change type: [Refactor / Migration / New Abstraction / Cross-System]

Please assess:
1. Blast radius — what else could break if these files change?
2. Dependencies affected — imports, consumers, callers of changed code
3. Architectural concerns — does this change fight the existing architecture?
4. Verdict: PROCEED / PROCEED WITH CHANGES / REDESIGN
```

## Step 3 — Summarize and Recommend

Parse the code-architect output and present a compact summary:

```
## Pre-Modification Check

**Blast Radius**: [Low / Medium / High] — [one sentence: what could break]
**Dependencies**: [list of affected modules/files, max 5]
**Architectural Concern**: [NONE / LOW / HIGH] — [one sentence if any]

**Verdict**: GO / CAUTION / STOP
[One sentence rationale]
```

Verdict mapping from code-architect output:
- `PROCEED` → `GO`
- `PROCEED WITH CHANGES` → `CAUTION` (list the required changes)
- `REDESIGN` → `STOP` (do not proceed — link to the concern)

## Step 4 — Fallback

If code-architect returns no output, an error, or content that cannot be parsed:

```
⚠ Pre-modification check incomplete — code-architect did not return a usable assessment.
Proceeding with caution. Recommend manual review before merging.
```

Continue with the task. Never block on a fallback — a missing review is a warning, not a hard stop.

## Rules

- Do NOT implement anything. This skill is assessment-only.
- If verdict is STOP, present the concern and ask the user to confirm before continuing.
- If verdict is CAUTION, list the required changes and ask the user if they want to address them first.
- If verdict is GO, proceed immediately without further prompts.
- Keep the summary under 10 lines — brevity over completeness.
