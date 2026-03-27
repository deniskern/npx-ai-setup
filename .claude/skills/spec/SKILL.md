---
name: spec
description: Create a new spec for a task. Triggers: /spec, 'create spec for X', 'write a spec for X', 'spec out X', 'plan X as a spec'.
---

Creates a structured spec for the task: $ARGUMENTS. Use before implementing any multi-file or architectural change.

## Phase 1 — Triage & Think Through

Before writing anything: triage the idea, then think the implementation completely through. Present findings in the chat.

### 1a — Load Skills
If `.claude/skills/` exists, glob all skill directories and read each `SKILL.md` (first 5 lines only). Apply their guidance throughout.

### 1b — Detect Input Type & Clarify

**If `$ARGUMENTS` is an existing `.md` file** → Draft Interview Mode: read the draft, ask exhaustive `AskUserQuestion` rounds (min 3) covering technical impl, edge cases, tradeoffs, dependencies, UX — only gaps not already answered in the draft. Update draft with insights, then continue with 1c.

**If `$ARGUMENTS` is plain text** → ask 1-3 focused questions if ambiguous. Skip if clear.

### 1c — Quick Triage

Read `.agents/context/CONCEPT.md` if it exists → REJECT if clearly misaligned with core principles.

**Complexity check**: If >5 files touched, new dep/system, or architectural change → `AskUserQuestion`: "Hohe Komplexitaet ([reason]). Empfehlung: /challenge zuerst." Options: "Weiter mit Spec", "Erst /challenge", "Scope reduzieren". Stop if /challenge chosen; ask clarifying questions if scope reduction chosen.

### 1d — Think It Through
Sketch full implementation mentally before writing. Use `AskUserQuestion` at any decision point.
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
Scan 3-5 relevant source files. For each implicit assumption: **Statement** / **Evidence** (file path) / **Confidence** (High/Med/Low) / **If Wrong** (consequence). Present via `AskUserQuestion` for confirmation. Add confirmed assumptions to spec's Context as "Verified Assumptions".

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

### Truths
- [ ] "[observable behavior verifiable by running a command]"

### Artifacts
- [ ] `path/to/file.ts` — [what it exports/contains] (min [N] lines)

### Key Links
- [ ] `file-a.ts` → `file-b.ts` via import of `[function/type]`

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
