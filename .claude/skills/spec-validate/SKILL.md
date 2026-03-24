---
name: spec-validate
description: Validate a draft spec before execution. Triggers: /spec-validate NNN, 'validate spec NNN', 'is spec NNN ready to implement', 'check spec quality'.
disable-model-invocation: true
---

# Spec Validate — Score a Draft Before Execution

Validates a draft spec and reports whether it is strong enough for implementation.

## Process

1. **Find the spec**: open `specs/NNN-*.md` or the filename provided.

2. **Validate status**: only validate specs with `Status: draft`. Otherwise report the current status and stop.

3. **Load context**: read `.agents/context/CONVENTIONS.md` if present to calibrate expectations.

4. **Score the spec** on:
   - Goal clarity
   - Step decomposition
   - Dependency identification
   - Coverage completeness
   - Acceptance criteria quality
   - Scope coherence
   - Risk and blockers
   - File coverage
   - Out of scope clarity
   - Integration awareness

5. **Return a verdict**:
   - `PASS` if the spec is ready for `/spec-work`
   - `FAIL` with concrete improvement points if it is weak

## Rules

- Read-only. Do not edit the spec.
- Be strict. Weak specs should fail.
- Only report real gaps with actionable fixes.
