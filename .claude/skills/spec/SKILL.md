---
name: spec
description: "Create a new spec for a task."
effort: high
model: opus
argument-hint: "<task description>"
---

Creates a structured spec for the task: $ARGUMENTS. Use before implementing any multi-file or architectural change.

## Phase 1 — Triage & Think Through

Before writing anything: triage the idea, then think the implementation completely through. Present findings in the chat.

### 1a — Load Skills
If `.claude/skills/` exists, glob all skill directories and read each `SKILL.md` (first 5 lines only). Apply their guidance throughout.

### 1a.5 — Documentation Discovery (if external libs/APIs involved)

For each external dependency: `mcp__context7__resolve-library-id` → `mcp__context7__query-docs` (specific feature only).
Output: verified method signatures + what does NOT exist. Feeds into 1d and spec steps.

### 1b — Detect Input Type & Clarify

- If `$ARGUMENTS` is an existing `.md` file: read it, ask only for missing implementation details, then continue.
- If `$ARGUMENTS` is plain text: ask 1-3 focused questions only if ambiguity blocks a good spec.

### 1c — Quick Triage

Read `.agents/context/CONCEPT.md` if it exists → REJECT if clearly misaligned with core principles.

**Complexity check**: If >5 files touched, new dep/system, or architectural change → `AskUserQuestion`: "Hohe Komplexitaet ([reason]). Empfehlung: /challenge zuerst." Options: "Weiter mit Spec", "Erst /challenge", "Scope reduzieren". Stop if /challenge chosen; ask clarifying questions if scope reduction chosen.

### 1c.5 — Challenge Gate (mandatory)

**File-Count-Check**: Glob source files relevant to $ARGUMENTS (e.g. `**/*.{js,ts,vue,sh,md}`).
- ≤ 10 results → read top 3 directly with Glob/Grep/Read
- > 10 results → spawn Haiku subagent (`model: haiku`, read-only: Glob/Grep/Read) to find the 3 most relevant files and return their key snippets, then evaluate findings below

Stelle konkret:

1. **Dopplung**: Gibt es Code der das schon macht oder teilweise löst? → Zeige `path/to/file:NN`
2. **Pattern-Konflikt**: Widerspricht der Ansatz einem bestehenden Pattern in der Codebase? → Nenne das Pattern und wo es definiert ist
3. **Simpler Weg**: Was ist die einfachste Alternative — und warum reicht sie nicht?
4. **6-Monats-Schmerz**: Wo wird das schwer zu warten, zu debuggen, zu erweitern?

Format in Chat:
```
Challenge: [konkrete Aussage]
Quelle: path/to/file:NN
Empfehlung: [Weiter / Scope ändern / Ansatz überdenken]
```

`AskUserQuestion`: "Challenge-Ergebnis: [1-Satz-Summary]. Weiter?" — Options: "Ja, Spec schreiben", "Ansatz anpassen", "Spec abbrechen".
Stoppe wenn "abbrechen". Überarbeite Phase 1 sketch wenn "anpassen".

### 1d — Think It Through
Sketch the full implementation before writing. Use `AskUserQuestion` only at real decision points.
- Files/systems touched; exact change in each
- Integration path; data/state flow; what calls what
- Edge cases; failure behavior; recoverability
- Hidden complexity; hard-to-test parts; 6-month maintenance pain
- **Complexity = impact surface + risk** (e.g. "3 files, new dep — Risk: memory, scroll state"). NEVER time estimates.

**Code-Flow-Analyse** (mandatory before step generation): For each function the spec will modify or call, read the source and trace:
1. Who calls it, what guards/conditions gate execution
2. What variables/state it already sets
3. What error/failure paths exist
Present as a short list in the chat (max 5 functions). This prevents redundant steps and surfaces blockers.

**Step Dedup Check**: Each spec step must introduce a NEW code change. If existing code already does it → no step. If a guard/condition blocks the new flow → that removal/bypass IS a step. If an error path needs handling → explicit step.

**Scope guardrail**: Spec boundary is FIXED once defined. New capabilities → "That belongs in its own spec."

### 1e — Surface Assumptions
Scan 3-5 relevant source files. For each implicit assumption capture **Statement / Evidence / Confidence / If Wrong**. Only ask for confirmation when the assumption materially changes scope or implementation.

---

## Phase 2 — Write the Spec

Only proceed if Phase 1c did not REJECT and user confirmed to continue.

### Step 1 — Determine spec number
Scan `specs/` (including `specs/completed/`) for existing `NNN-*.md` files, find the highest number, increment by 1. Use 3-digit zero-padded numbers.

### Step 2 — Analyze the task
Read the 2-3 most relevant source files. Use the Phase 1d sketch — do not re-analyze from scratch. List relevant installed skills in the spec Context section.

### Step 3 — Create the spec file (with auto-split check)
Translate Phase 1d sketch into spec steps with actual file paths. After drafting, check auto-split triggers:
- **Trigger A**: draft >60 lines or >8 steps
- **Trigger B**: steps span fundamentally different architectural layers

If either fires: split into two specs (NNN and NNN+1), cross-reference each, note dependencies. Otherwise write a single spec.

**Step dedup validation** (after drafting): For each step, verify against the Code-Flow-Analyse from 1d:
- Does existing code already do this? → remove step
- Does a guard/condition block this flow? → add step for guard removal/bypass
- Is an error/failure path unhandled? → add explicit step

### Step 4 — Present the spec
Show spec to user for review and refinement.

### Step 5 — Branch
`AskUserQuestion`: "Branch fuer diese Spec erstellen?" — Ja: `git checkout -b spec/NNN-<slug>` / Nein / Spaeter.

## Spec Template

```markdown
# Spec: [Clear Title]

> **Spec ID**: NNN | **Created**: YYYY-MM-DD | **Status**: draft | **Complexity**: medium | **Branch**: —

## Goal
[One sentence]

## Context
[2-3 sentences. Why needed, what approach was chosen, relevant skills if any.]

### Verified Assumptions
- [Statement] — Evidence: `path/to/file` | Confidence: High | If Wrong: [consequence]

## Steps
- [ ] Step 1: description
- [ ] Step 2: description

## Acceptance Criteria
- [ ] "[observable behavior verifiable by running a command]"

## Files to Modify
- `path/to/file` - reason

## Out of Scope
- What is NOT part of this task
```

## Constraints & Rules
- **Total spec: max 60 lines.** If more, split into multiple specs.
- **Goal**: 1 sentence. **Context**: 2-3 sentences.
- **Steps**: Flat checkbox list, max 8 items. No nested sub-steps.
- **Acceptance Criteria**: max 5 items. **Out of Scope**: max 3 items.
- Steps must come from Phase 1d sketch — be specific, include file paths.
- Use today's date. Filename: lowercase with hyphens.
- Always create `specs/` and `specs/completed/` if they don't exist.

## Next Step

After the spec file is written, run `/spec-validate NNN` to score it before execution, or jump straight to `/spec-work NNN` to start implementation.
