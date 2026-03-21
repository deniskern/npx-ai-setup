---
model: opus
mode: plan
argument-hint: "[task description]"
allowed-tools: Read, Write, Glob, Grep, Bash, AskUserQuestion
---

Creates a structured spec for the task: $ARGUMENTS. Use before implementing any multi-file or architectural change.

## Phase 1 — Challenge & Think Through

Before writing anything: challenge the idea hard, then think it completely through. Present findings in the chat.

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
4. Continue with Phase 1c (Concept Fit)

**If `$ARGUMENTS` is plain text** → standard clarify flow:
If the request is ambiguous or underspecified, ask 1-3 focused questions before proceeding. Wait for answers. Skip if the task is clear.

### 1c — Concept Fit
Read `.agents/context/CONCEPT.md` if it exists. Answer:
- Does this align with the project's core principles?
- Is it in scope for this codebase/tool?
- Would this belong in the core, or is it a plugin/workaround?

Rate: **ALIGNED / BORDERLINE / MISALIGNED**. If MISALIGNED → **REJECT** immediately.

### 1d — Necessity
- What specific problem does this solve? Is it real or hypothetical?
- What breaks or stays painful if we don't build it?
- Who reported this problem — users, or us?

### 1e — Think It Through
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

### 1e-bis — Surface Assumptions

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

### 1f — Overhead & Risk
- Maintenance burden added?
- Does it increase surface area (more config, more flags, more docs)?
- What's the risk if the implementation is wrong?

### 1g — Simpler Alternatives
List 1-3 alternatives:
- A smaller scope version
- A workaround that avoids building anything
- **"Don't build it"** — explicitly if it applies
Scan with Glob and Grep for similar existing functionality. Check installed skills for overlap.

### 1h — Verdict
Present a clear summary of the thinking above, then choose exactly one:
**GO** — Needed, fits, complexity is understood. The implementation sketch from 1e becomes the basis for the spec steps.
**SIMPLIFY** — Merits exist but scope is too large. State the reduced scope. Ask user to confirm before proceeding.
**REJECT** — Misaligned, unnecessary, or risk outweighs benefit. State reason. Stop here.

---

## Phase 2 — Write the Spec

Only proceed if verdict is GO or user confirmed a SIMPLIFY scope.

### Step 1 — Determine spec number
Scan `specs/` (including `specs/completed/`) for existing `NNN-*.md` files, find the highest number, increment by 1. Use 3-digit zero-padded numbers.

### Step 2 — Analyze the task
Read the 2-3 most relevant source files. Use the implementation sketch from Phase 1e — do not re-analyze from scratch.

List any relevant installed skills in the spec Context section.

### Step 3 — Create the spec file (with auto-split check)
Translate the Phase 1e implementation sketch into spec steps. Steps should reflect actual implementation path, not generic placeholders.

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

> **Spec ID**: NNN | **Created**: YYYY-MM-DD | **Status**: draft | **Branch**: —

<!-- Status lifecycle: draft → in-progress → in-review → completed (or blocked at any stage) -->
<!-- Branch is set automatically by /spec-work-all (worktree mode) or manually -->

## Goal
[One sentence]

## Context
[2-3 sentences. Why needed, what approach was chosen, relevant skills if any.]

### Verified Assumptions
<!-- Remove this section if no assumptions were confirmed in Phase 1e-bis -->
- [Statement] — Evidence: `path/to/file` | Confidence: High | If Wrong: [consequence]

## Steps
- [ ] Step 1: description
- [ ] Step 2: description
- [ ] Step 3: description

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2

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
- Steps must come from the Phase 1e implementation sketch — be specific, include file paths.
- Use today's date. Filename: lowercase with hyphens.
- Always create `specs/` and `specs/completed/` if they don't exist.
