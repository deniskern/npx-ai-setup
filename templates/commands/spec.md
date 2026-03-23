---
model: opus
mode: plan
argument-hint: "[task description]"
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
---

Creates a structured spec for the task: $ARGUMENTS. Use before implementing any multi-file or architectural change.

## Phase 1 — Triage & Think Through

Before writing anything: triage the idea, then think the implementation completely through. Present findings in the chat.

### 1a — Load Skills
If `.claude/skills/` exists, glob all skill directories and read each `SKILL.md` (first 5 lines only). Apply their guidance throughout the entire process.

### 1b — Detect Input Type & Clarify

**Check if `$ARGUMENTS` is a file path**: Test whether the argument resolves to an existing `.md` file.

**If `$ARGUMENTS` is an existing `.md` file path** → enter **Draft Interview Mode**:
1. Read the draft file completely
2. Interview the user proactively and exhaustively via `AskUserQuestion` — covering all of:
   - **Technical implementation**: architecture decisions, data flow, APIs, error handling, performance implications
   - **Edge cases & failure modes**: what happens with invalid input, concurrency, timeouts, empty states
   - **Tradeoffs**: alternatives considered, why this approach vs. others, cost/benefit
   - **Dependencies & side effects**: what else breaks, what this depends on, migration path
   - **UI/UX** (if applicable): interaction flow, accessibility, mobile behavior
   Questions must be **non-obvious** — do not ask about things already answered in the draft. Ask about gaps, assumptions, and implicit decisions. Continue for minimum 3 rounds of questions until all areas are fully covered.
3. After all questions are answered: update the draft file with the refined spec incorporating all interview insights
4. Continue with Phase 1c (Quick Triage)

**If `$ARGUMENTS` is plain text** → standard clarify flow:
If the request is ambiguous or underspecified, ask 1-3 focused questions before proceeding. Wait for answers. Skip if the task is clear.

### 1c — Quick Triage

**Concept check**: Read `.agents/context/CONCEPT.md` if it exists. If the idea is clearly misaligned with the project's core principles → **REJECT** immediately with reason. Otherwise continue.

**Complexity scan**: Estimate the scope by checking:
- How many files/systems are likely touched?
- Does this introduce a new dependency, pattern, or architectural layer?
- Does the task contain high-complexity keywords (migrate, rewrite, new system, redesign)?

If **any** of these are true: >5 files touched, new dependency/system introduced, or architectural change detected → use `AskUserQuestion`:
> "Dieses Feature hat hohe Komplexitaet ([reason]). Empfehlung: `/challenge` zuerst ausfuehren fuer eine tiefe Analyse, bevor die Spec geschrieben wird."
> Options: "Weiter mit Spec — ich kenne die Risiken", "Erst /challenge ausfuehren", "Scope reduzieren"

If user chooses `/challenge`: stop here and suggest the user runs `/challenge "task"`.
If user chooses scope reduction: ask clarifying questions to narrow scope, then continue.
Otherwise: proceed to 1d.

### 1d — Think It Through
Sketch the full implementation mentally before writing the spec.
**Use `AskUserQuestion` at any decision point** — don't assume, ask. Multiple rounds are fine.
Checklist:
- Files/systems touched; exact change in each
- Integration path; what calls what; data/state flow
- Edge cases; failure behavior; recoverability
- Hidden complexity; hard-to-test/debug parts; 6-month maintenance pain
- Implicit dependencies and side effects
- **Complexity = impact surface + risk** (e.g. "3 files, new dep — Risk: memory, scroll state"). NEVER time estimates.

**Scope guardrail**: The spec boundary is FIXED once defined. Discussion clarifies HOW to implement, not WHETHER to add more. If user suggests new capabilities: "That belongs in its own spec. I'll note it for later." Capture deferred ideas — don't lose them, don't act on them.

### 1e — Surface Assumptions

After thinking it through, scan 3-5 of the most relevant source files. Form a list of implicit assumptions underlying the implementation sketch.

For each assumption, structure it as:
- **Statement**: What you're assuming to be true
- **Evidence**: File path or observable fact that supports it
- **Confidence**: High / Medium / Low
- **If Wrong**: Concrete consequence for the implementation

Present assumptions via `AskUserQuestion`:
> "Ich habe folgende implizite Annahmen identifiziert. Bitte bestaetigen, korrigieren oder ergaenzen:"
> [list assumptions]
> Options: "Alle bestaetigt", "Ich korrigiere Annahme X: ...", "Fehlende Annahme: ..."

Wait for confirmation. Incorporate corrected or added assumptions before proceeding.
Confirmed assumptions are added to the spec's Context section as a "Verified Assumptions" subsection.

---

## Phase 2 — Write the Spec

Only proceed if Phase 1c did not REJECT and user confirmed to continue.

### Step 1 — Determine spec number
Scan `specs/` (including `specs/completed/`) for existing `NNN-*.md` files, find the highest number, increment by 1. Use 3-digit zero-padded numbers.

### Step 2 — Analyze the task
Read the 2-3 most relevant source files. Use the implementation sketch from Phase 1d — do not re-analyze from scratch.

List any relevant installed skills in the spec Context section.

### Step 3 — Create the spec file (with auto-split check)
Translate the Phase 1d implementation sketch into spec steps. Steps should reflect actual implementation path, not generic placeholders.

**After drafting**, check two auto-split triggers before writing the file:

**Trigger A — Size**: draft exceeds 60 lines OR more than 8 steps.
**Trigger B — Mixed layers**: steps span fundamentally different architectural layers (e.g. frontend + backend, API + UI, data migration + feature logic, infra + app code).

If either trigger fires, split into two specs automatically:
1. Create `specs/NNN-<first-title>.md` with steps for the first concern/layer
2. Create `specs/NNN+1-<second-title>.md` with steps for the second concern/layer
3. Add to each spec's Context: "Part N of 2 — see Spec NNN±1 for the other layer."
4. Add to each spec's Out of Scope: "Everything in Spec NNN±1."
5. If one spec depends on the other, note: "Requires Spec NNN to be completed first."
6. Report: "Task split into Spec NNN and Spec NNN+1 — [reason: size / mixed layers]."

If neither trigger fires, write a single spec file.

### Step 4 — Present the spec
Show the spec to the user for review and refinement.

### Step 5 — Branch
Use `AskUserQuestion` to ask: "Branch fuer diese Spec erstellen?"
- **Ja** — run `git checkout -b spec/NNN-<slug>` (slug = spec filename without number prefix)
- **Nein** — skip, user bleibt auf aktuellem Branch
- **Spaeter** — skip, user entscheidet selbst

## Spec Template

```markdown
# Spec: [Clear Title]

> **Spec ID**: NNN | **Created**: YYYY-MM-DD | **Status**: draft | **Complexity**: medium | **Branch**: —

<!-- Status lifecycle: draft → in-progress → in-review → completed (or blocked at any stage) -->
<!-- Branch is set automatically by /spec-work-all (worktree mode) or manually -->
<!-- Complexity definitions: low = mechanical (no judgment required), medium = judgment-required (default), high = architectural -->

## Goal
[One sentence]

## Context
[2-3 sentences. Why needed, what approach was chosen, relevant skills if any.]

### Verified Assumptions
<!-- Remove this section if no assumptions were confirmed in Phase 1e -->
- [Statement] — Evidence: `path/to/file` | Confidence: High | If Wrong: [consequence]

## Steps
- [ ] Step 1: description
- [ ] Step 2: description
- [ ] Step 3: description

## Acceptance Criteria

<!-- Use only the categories that apply — omit empty ones. -->
<!-- Truths: verified by running a command or observing output -->
<!-- Artifacts: verified by confirming files exist with real content (not stubs) -->
<!-- Key Links: verified by confirming imports/references connect -->

### Truths
Observable behaviors that must be true when this spec is done:
- [ ] "[behavior description that can be verified by running a command or observing output]"

### Artifacts
Files that must exist with real implementation (not stubs):
- [ ] `path/to/file.ts` — [what it exports/contains] (min [N] lines)

### Key Links
Critical wiring between artifacts that must actually connect:
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
- Steps must come from the Phase 1d implementation sketch — be specific, include file paths.
- Use today's date. Filename: lowercase with hyphens.
- Always create `specs/` and `specs/completed/` if they don't exist.

## Next Step

After the spec file is written, run `/spec-validate NNN` to score it before execution, or jump straight to `/spec-work NNN` to start implementation.
