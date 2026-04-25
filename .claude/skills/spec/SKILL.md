---
name: spec
description: "Creates a structured spec before implementation. Trigger: 'let\\'s spec this', 'plan this out', 'new feature'."
user-invocable: true
disable-model-invocation: true
effort: high
model: opus
argument-hint: "<task description>"
allowed-tools:
  - Read
  - Write
  - Glob
  - Grep
  - Bash
  - AskUserQuestion
  - Agent
---

Creates a structured spec for: $ARGUMENTS. Use before any multi-file or architectural change.

## Phase 1 — Triage

### 1a. Load skills
Glob `.claude/skills/*/SKILL.md`, read first 5 lines each. Apply relevant guidance.

### 1b. Context-Scan (mandatory)
Spawn `context-scanner` subagent (model: haiku). See `@references/context-scan.md`.
Present the returned summary in chat, then ask one consolidated AskUserQuestion call:

```
AskUserQuestion({
  questions: [
    { question: "Was soll diese Spec erreichen?", header: "Anforderung",
      options: [plain text from $ARGUMENTS as default, "Other / eigene Eingabe"] },
    { question: "Scope-Grenze?", header: "Scope",
      options: ["Nur dieses Feature", "Feature + Refactor", "Breaking Change", "Other"] },
    { question: "Stack-Coverage?", header: "Stack",
      options: ["Single: <detected_profile>", "Multi: alle Stacks", "Spezifisch wählen", "Other"] },
    { question: "Was ist explizit Out of Scope?", header: "OoS",
      options: ["Tests", "Doku", "Migration", "Other"] }
  ]
})
```

If `$ARGUMENTS` is an existing `.md` file: read it first, skip question 1.

### 1c. Quick triage
Read `.agents/context/CONCEPT.md` if present — REJECT if misaligned.
If >5 files touched or new dep/system: recommend `/challenge` first via AskUserQuestion.

### 1c.5. Challenge gate
See `@references/challenge.md` for the 4 challenges + AskUserQuestion format.
Stop if user aborts. Adjust approach if user requests scope change.

### 1d. Think it through
Using context-scan output + 1b answers, sketch:
- Files/systems touched per stack profile
- Integration path, data flow, what calls what
- Edge cases, failure behavior, recoverability
- Impact surface + risk

Code-flow analysis (max 5 functions): see `@references/code-flow.md`.

Each spec step must introduce a NEW code change. Remove redundant steps. Add steps for blocked flows.

### 1e. Surface assumptions
Scan 3-5 relevant files. Capture: `Statement / Evidence / Confidence / If Wrong`.
Only ask for confirmation when an assumption materially changes scope.

## Phase 2 — Write the spec

1. **Spec number**: Scan `specs/` + `specs/completed/` for highest `NNN-*.md`, increment by 1.
2. **Analyze**: Read 2-3 most relevant source files. Reuse Phase 1 sketch.
3. **Create**: Use template from `@references/template.md`. Include **Stack Coverage** section.
4. **Auto-split**: Draft >60 lines or >8 steps → split into NNN + NNN+1, cross-reference.
5. **Present**: Show spec, ask for refinement.
6. **Branch**: AskUserQuestion — create `spec/NNN-<slug>` now / later / skip.

## Next Step

Run `/spec-validate NNN` or jump to `/spec-work NNN`.
