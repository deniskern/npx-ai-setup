---
name: spec-validate
description: "Validate a draft spec before execution. Triggers: /spec-validate NNN, 'validate spec NNN', 'is spec NNN ready to implement', 'check spec quality'."
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

Score 0–10 per criterion. Be strict — unanswered questions score ≤5.

| # | Metric | Weight | Question |
|---|--------|--------|----------|
| 1 | Goal Clarity | 12% | Specific, bounded, measurable goal? |
| 2 | Step Decomposition | 12% | Atomic steps, no megasteps? |
| 3 | Coverage Completeness | 12% | Steps cover entire goal? |
| 4 | Acceptance Criteria | 12% | Testable YES/NO criteria? |
| 5 | File Coverage | 12% | All changed files listed? |
| 6 | Integration Awareness | 12% | Integration with existing code addressed? |
| 7 | Dependency ID | 7% | External deps named? |
| 8 | Scope Coherence | 7% | Realistic scope for one spec? |
| 9 | Risk & Blockers | 7% | Risks/ambiguities mentioned? |
| 10 | Out of Scope | 7% | Precise enough to prevent creep? |

### 5. Present results

```
Spec Validation — NNN: [title]
──────────────────────────────────────────────────────────
 #  Criterion                    Raw (0–10)  Weight  Score
──────────────────────────────────────────────────────────
 1  Goal Clarity                    X.X       12%     X.X
...
──────────────────────────────────────────────────────────
   Total weighted score: XX.X / 100     Grade: X
```

### 6. Verdict

| Grade | Threshold | Action |
|-------|-----------|--------|
| A | ≥ 85 | "Run `/spec-work NNN`." |
| B | ≥ 70 | "Run `/spec-work NNN`." |
| C | ≥ 55 | List criteria <7 with fixes. "Revision recommended." |
| F | < 55 | List criteria <7 with fixes. "Fix and re-run `/spec-validate NNN`." |

## Rules
- **Read-only** — never modify the spec or any file.
- Score honestly. Only report metrics that fail.
- Advisory only — does not block `/spec-work`.
