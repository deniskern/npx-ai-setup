---
model: sonnet
mode: plan
argument-hint: "[spec number]"
allowed-tools: Read, Glob, Grep, AskUserQuestion, Bash
---

Validates spec $ARGUMENTS against 10 quality metrics before execution. Run before `/spec-work` to catch weak specs early.

## Process

### 1. Find the spec
If `$ARGUMENTS` is a number (e.g. `011`), open `specs/011-*.md`. If it's a filename, open that directly. If empty, list all draft specs in `specs/` and ask which to validate.

### 2. Run prep script

Run the prep script to pre-parse the spec structure before reading it yourself:

```bash
bash .claude/scripts/spec-validate-prep.sh $ARGUMENTS
```

Use the prep output to populate the scoring table in step 5 — it provides:
- Which required sections are present or missing
- Step count and completion state
- Acceptance criteria count
- Files to Modify count
- Structural score (0–100)

If the script is not present, proceed without it (read the spec file directly).

### 3. Validate status
Only validate specs with `Status: draft`. If `in-progress`, `in-review`, or `completed` → report status and stop.

### 4. Load context
Read `.agents/context/CONVENTIONS.md` if it exists — use it to calibrate expectations for test coverage, code patterns, and integration standards.

### 5. Score the spec

Evaluate each metric from 0–100. Be strict — a spec that doesn't answer the question scores ≤50.

| # | Metric | Question to answer |
|---|--------|--------------------|
| 1 | **Goal Clarity** | Is the one-sentence goal specific, bounded, and measurable? Can you tell when it's done? |
| 2 | **Step Decomposition** | Are steps atomic and each achievable in one focused session? No "implement X" megasteps. |
| 3 | **Dependency Identification** | Are external dependencies (other specs, APIs, libs, env vars) named explicitly? |
| 4 | **Coverage Completeness** | Do the steps collectively cover the entire goal — nothing obviously missing? |
| 5 | **Acceptance Criteria Quality** | Are criteria specific and testable (not vague)? Can each be checked YES/NO? |
| 6 | **Scope Coherence** | Is the scope realistic for a single spec? Not too large, not trivially small? |
| 7 | **Risk & Blockers** | Are known risks, ambiguities, or potential blockers mentioned (in Context or Out of Scope)? |
| 8 | **File Coverage** | Are all files that will realistically change listed in "Files to Modify"? |
| 9 | **Out of Scope Clarity** | Is scope exclusion precise enough to prevent creep during execution? |
| 10 | **Integration Awareness** | Does the spec account for how changes integrate with existing code, tests, or systems? |

### 6. Present results

Display a score table:

```
Spec Validation — NNN: [title]
─────────────────────────────────────────
 1. Goal Clarity ................ XX
 2. Step Decomposition .......... XX
 3. Dependency Identification ... XX
 4. Coverage Completeness ........ XX
 5. Acceptance Criteria Quality .. XX
 6. Scope Coherence .............. XX
 7. Risk & Blockers .............. XX
 8. File Coverage ................ XX
 9. Out of Scope Clarity ......... XX
10. Integration Awareness ........ XX
─────────────────────────────────────────
   Average: XX.X    Minimum: XX
   Threshold: 80 avg / 65 min
   Result: PASS ✓  |  FAIL ✗
```

### 7. Verdict

**PASS** (avg ≥ 80 AND no metric < 65):
- Report: "Spec NNN is ready for execution. Run `/spec-work NNN`."
- No changes to the spec file.

**FAIL** (avg < 80 OR any metric < 65):
- List every metric below threshold with a specific, actionable improvement (1-2 sentences per issue).
- Do NOT make changes to the spec. Let the user revise it.
- Report: "Spec NNN needs improvement before execution. Fix the issues above and re-run `/spec-validate NNN`."

## Rules
- **Read-only** — never modify the spec or any file.
- Score honestly. A spec that passes with weak scores wastes execution compute.
- Only report metrics that actually fail. Don't pad passing specs with warnings.
- This command does NOT block `/spec-work` — it's advisory. But weak specs ship weak code.
