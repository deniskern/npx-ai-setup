# Scoring Rubric

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

## Output Format

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

## Verdict Thresholds

| Grade | Threshold | Action |
|-------|-----------|--------|
| A | ≥ 85 | "Run `/spec-work NNN`." |
| B | ≥ 70 | "Run `/spec-work NNN`." |
| C | ≥ 55 | List criteria <7 with fixes. "Revision recommended." |
| F | < 55 | List criteria <7 with fixes. "Fix and re-run `/spec-validate NNN`." |
