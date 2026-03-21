---
model: sonnet
mode: plan
argument-hint: "[spec number]"
allowed-tools: Read, Glob, Grep, AskUserQuestion
---

Validates spec $ARGUMENTS against 10 quality metrics before execution. Run before `/spec-work` to catch weak specs early.

## Process

### 1. Find the spec
If `$ARGUMENTS` is a number (e.g. `011`), open `specs/011-*.md`. If it's a filename, open that directly. If empty, list all draft specs in `specs/` and ask which to validate.

### 2. Validate status
Only validate specs with `Status: draft`. If `in-progress`, `in-review`, or `completed` → report status and stop.

### 3. Load context
Read `.agents/context/CONVENTIONS.md` if it exists — use it to calibrate expectations for test coverage, code patterns, and integration standards.

### 4. Score the spec

Score each criterion from 0–10. Be strict — a criterion that doesn't answer the question scores ≤5. Core criteria carry 12% weight each (6 criteria × 12% = 72%), Secondary criteria carry 7% weight each (4 criteria × 7% = 28% — total 100%).

| # | Tier | Metric | Weight | Question to answer |
|---|------|--------|--------|--------------------|
| 1 | Core | **Goal Clarity** | 12% | Is the one-sentence goal specific, bounded, and measurable? Can you tell when it's done? |
| 2 | Core | **Step Decomposition** | 12% | Are steps atomic and each achievable in one focused session? No "implement X" megasteps. |
| 3 | Core | **Coverage Completeness** | 12% | Do the steps collectively cover the entire goal — nothing obviously missing? |
| 4 | Core | **Acceptance Criteria Quality** | 12% | Are criteria specific and testable (not vague)? Can each be checked YES/NO? |
| 5 | Core | **File Coverage** | 12% | Are all files that will realistically change listed in "Files to Modify"? |
| 6 | Core | **Integration Awareness** | 12% | Does the spec account for how changes integrate with existing code, tests, or systems? |
| 7 | Secondary | **Dependency Identification** | 7% | Are external dependencies (other specs, APIs, libs, env vars) named explicitly? |
| 8 | Secondary | **Scope Coherence** | 7% | Is the scope realistic for a single spec? Not too large, not trivially small? |
| 9 | Secondary | **Risk & Blockers** | 7% | Are known risks, ambiguities, or potential blockers mentioned (in Context or Out of Scope)? |
| 10 | Secondary | **Out of Scope Clarity** | 7% | Is scope exclusion precise enough to prevent creep during execution? |

Note: Weights sum to 100% (6×12% + 4×7% = 72% + 28% = 100%).

### 5. Present results

Display a score breakdown table showing raw score, weight, and weighted score per criterion, then total and letter grade:

```
Spec Validation — NNN: [title]
──────────────────────────────────────────────────────────
 #  Criterion                    Raw (0–10)  Weight  Score
──────────────────────────────────────────────────────────
 1  Goal Clarity                    X.X       12%     X.X
 2  Step Decomposition              X.X       12%     X.X
 3  Coverage Completeness           X.X       12%     X.X
 4  Acceptance Criteria Quality     X.X       12%     X.X
 5  File Coverage                   X.X       12%     X.X
 6  Integration Awareness           X.X       12%     X.X
 7  Dependency Identification        X.X        7%     X.X
 8  Scope Coherence                 X.X        7%     X.X
 9  Risk & Blockers                 X.X        7%     X.X
10  Out of Scope Clarity            X.X        7%     X.X
──────────────────────────────────────────────────────────
   Total weighted score: XX.X / 100     Grade: X
```

Calculate weighted score per criterion: `raw × weight`. Sum all weighted scores for the total (0–100).

### 6. Verdict

Assign letter grade based on total weighted score:

| Grade | Threshold | Meaning |
|-------|-----------|---------|
| A | ≥ 85 | Ready for execution — high confidence |
| B | ≥ 70 | Acceptable — minor gaps, proceed with care |
| C | ≥ 55 | Weak — significant gaps, revision recommended |
| F | < 55 | Not ready — major issues must be resolved |

**Grade A or B:**
- Report: "Spec NNN scored XX.X (Grade X). Run `/spec-work NNN`."
- No changes to the spec file.

**Grade C:**
- List every criterion scoring < 7 with a specific, actionable improvement (1-2 sentences per issue).
- Do NOT make changes to the spec. Let the user decide whether to revise or proceed.
- Report: "Spec NNN scored XX.X (Grade C). Revision recommended before execution."

**Grade F:**
- List every criterion scoring < 7 with a specific, actionable improvement (1-2 sentences per issue).
- Do NOT make changes to the spec. Let the user revise it.
- Report: "Spec NNN scored XX.X (Grade F). Fix the issues above and re-run `/spec-validate NNN`."

## Rules
- **Read-only** — never modify the spec or any file.
- Score honestly. A spec that passes with weak scores wastes execution compute.
- Only report metrics that actually fail. Don't pad passing specs with warnings.
- This command does NOT block `/spec-work` — it's advisory. But weak specs ship weak code.
