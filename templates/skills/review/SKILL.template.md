---
name: ais:review
description: Reviews uncommitted changes with selectable intensity. Use before committing or merging.
model: sonnet
mode: plan
allowed-tools: Read, Glob, Grep, Bash
---

Reviews uncommitted changes with selectable intensity. Use before committing or merging.
Note: Mode C (Adversarial Grill) benefits from Opus — invoke with `claude --model claude-opus-4-6` if maximum depth is required.

## Step 0 — Select Intensity

Ask the user which review mode to run:

```
AskUserQuestion: Which review intensity?
A) Quick Scan — bugs + security, HIGH/MEDIUM issues only (~1 min)
B) Standard Review — full analysis: bugs, security, performance, readability, tests, duplicates (~3 min)
C) Adversarial Grill — full adversarial review with scope challenge, A/B/C resolution, and self-verification table (~10 min)
```

Wait for the user's choice before proceeding. Then follow the corresponding mode below.

---

## Step 1 — Collect Diff

Run the prep script to collect all diffs in one pass:

```bash
!bash .claude/scripts/review-prep.sh
```

If the script is not present, fall back to:
- `!git diff`
- `!git diff --staged`
- `!git diff main...HEAD 2>/dev/null`

If all diffs are empty, report "No changes found." and stop.

---

## Stub/AI-Code Detection (all modes)

Before analyzing issues, scan for placeholder implementations:
- Functions that only `throw new Error("not implemented")`, `TODO`, `FIXME`, or `return null/undefined` without logic
- AI-generated boilerplate comments like "// Add your logic here" or "// TODO: implement"
- Empty catch blocks, stub return values, or skeleton classes with no real behavior

Flag every instance as **STUB** severity. These block shipping regardless of mode.

---

## Quick Scan Mode (A)

Analyze each changed file for:
- **Bugs**: Logic errors, off-by-one, null/undefined, race conditions
- **Security**: Injection, XSS, secrets exposure, OWASP top 10

Report findings with confidence levels (HIGH / MEDIUM / LOW).
Only report HIGH and MEDIUM confidence issues — skip LOW and stylistic preferences.

End with: PASS or BLOCK (if HIGH/CRITICAL issues or STUBs found).

---

## Standard Review Mode (B)

Read every changed file completely — not just the diff, the full file for context.

Analyze each changed file for:
- **Bugs**: Logic errors, off-by-one, null/undefined, race conditions
- **Security**: Injection, XSS, secrets exposure, OWASP top 10
- **Performance**: N+1 queries, unnecessary re-renders, memory leaks
- **Readability**: Unclear names, missing context, overly complex logic
- **Missing tests**: Changed logic without test coverage

Also check for duplicates using the prep script output. If a name appears in multiple files, note it: "Similar pattern already exists at [file:line] — verify this is intentional and not a copy-paste."

Report findings with confidence levels (HIGH / MEDIUM / LOW).
Only report HIGH and MEDIUM confidence issues.

End with: PASS or BLOCK (if HIGH/CRITICAL issues or STUBs found).

---

## Adversarial Grill Mode (C)

### Scope Challenge

Before reading any code, challenge the scope:

1. **Does this already exist?** Run Grep to search for similar functions, patterns, or logic in the codebase. If the change duplicates existing code, flag it immediately.
2. **Is this the minimum viable change?** Consider whether a smaller diff would solve the problem equally well.

Present using AskUserQuestion:

```
A) Scope reduction — suggest a smaller version of this change before proceeding
B) Full adversarial review — continue with all steps below
C) Compressed review — quick pass, top 3 issues only, no deep dive
```

If A: suggest the smaller scope and stop. If C: skip to issue list, report only three most critical findings.

### Deep Analysis

Read every changed file completely. Act as a senior engineer who does NOT want to ship this. Challenge everything:

- **Edge cases**: Empty input, null, zero, max values, concurrent access
- **Error handling**: All error paths covered? Can errors propagate silently?
- **Security**: Injection, auth bypass, data exposure, SSRF, path traversal
- **Race conditions**: Shared state, async without proper synchronization
- **Missing validation**: Inputs validated at system boundaries?
- **Breaking changes**: Does this break any existing API, behavior, or contract?
- **Data integrity**: Risk of data loss, corruption, or inconsistency?

Also check: Performance, readability, missing tests, and duplicate patterns (same as Standard mode).

### Issue Resolution

For each issue found, report:
- Severity: CRITICAL / HIGH / MEDIUM
- File and line number
- Concrete failure scenario (not theoretical)
- Resolution options in A/B/C format:

  ```
  **Option A** — [approach]: [tradeoff]
  **Option B** — [approach]: [tradeoff]
  **Option C** — [approach]: [tradeoff]
  -> Recommended: Option [X] because [reason]
  ```

For each CRITICAL or HIGH issue, use AskUserQuestion to let the user choose which option to apply before continuing.

### NOT Reviewed

Explicitly list what was out of scope. Common exclusions: `dist/`, `.output/`, `node_modules/`, test fixtures, lock files (`package-lock.json`, `yarn.lock`), binary assets.

### Verdict

BLOCK (has CRITICAL/HIGH issues or STUBs) or PASS (only MEDIUM or no issues).

### Self-Verification Table

Double-check every claim made in this review. Create a markdown table:

| Claim | File:Line | Verified |
|-------|-----------|----------|
| [each finding summarized in one line] | [exact file and line] | yes / no / partial |

Every finding must appear in this table. If a claim cannot be verified against an exact file and line, mark it `no` and remove it from blocking issues.

---

## Rules (all modes)
- Do NOT make any changes. Only report findings.
- Read the actual code before commenting — never speculate.
- Focus on what matters: bugs and security over style.
- If no issues found, say so clearly.

## Agent Dispatch (Mode B and C only)

After the manual review, dispatch relevant agents in parallel for deeper analysis:

- **Always**: Spawn `code-reviewer` agent (model: sonnet) with the diff summary
- **If security-sensitive changes** (auth, user input, API endpoints, secrets): Also spawn `security-reviewer` agent (model: sonnet)
- **If hot path changes** (DB queries, loops, data fetching, rendering): Also spawn `performance-reviewer` agent (model: sonnet)

Merge agent findings into the final report. Deduplicate — if an agent finds the same issue you already reported, skip it.

## Next Step

After addressing any review findings, run `/commit` to stage and commit changes, or `/pr` if the branch is ready for a pull request.
