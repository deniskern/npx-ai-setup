---
name: spec-validate
description: "Validate a draft spec before execution."
user-invocable: true
effort: low
model: haiku
argument-hint: "<NNN spec number>"
allowed-tools:
  - Read
  - Glob
  - Bash
---

Validates spec $ARGUMENTS against 10 quality metrics. Run before `/spec-work` to catch weak specs early.

## Process

### 1. Find and validate the spec
If `$ARGUMENTS` is a number, open `specs/NNN-*.md`. If empty, list draft specs and ask. Only validate `Status: draft` — otherwise report status and stop.

### 2. Run prep script
```bash
bash .claude/scripts/spec-validate-prep.sh "$ARGUMENTS"
```
Use output to populate scoring. If script missing, read spec directly.

### 3. Load context
Read `.agents/context/CONVENTIONS.md` if it exists for calibration.

### 4. Score the spec
Apply the 10-metric rubric in `@references/scoring.md`. Be strict — unanswered questions score ≤5.

### 5. Present results + verdict
Use the output format and grade thresholds in `@references/scoring.md`.

## Next Step

- Grade A/B: `> ⚡ Naechster Schritt: /spec-work NNN — Spec implementieren`
- Grade C: `> 🔧 Naechster Schritt: Kriterien <7 fixen, dann /spec-validate NNN erneut`
- Grade F: `> 🔧 Naechster Schritt: Spec ueberarbeiten, dann /spec-validate NNN erneut`

## Rules
- **Read-only** — never modify the spec or any file.
- Score honestly. Only report metrics that fail.
- Advisory only — does not block `/spec-work`.
