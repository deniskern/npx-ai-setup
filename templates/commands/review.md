---
model: opus
mode: plan
allowed-tools: Read, Glob, Grep, Bash
---

Reviews uncommitted changes and reports bugs, security issues, and improvements. Use before committing to catch issues.

## Step 1 — Run prep script

Run the prep script first to collect all diffs and duplicate findings in one pass:

```bash
bash .claude/scripts/review-prep.sh
```

Use the output as your sole source of diff data and duplicate findings. Do NOT re-run git diff or grep for duplicates — the script already captured this.

If the script is not present, fall back to:
- `!git diff`
- `!git diff --staged`
- `!git diff main...HEAD 2>/dev/null`

## Step 2 — Analyze

Work only from the prep script output above.

1. If all diffs are empty, report "No changes found." and stop.
2. For each changed file listed in the prep report, read the full file to understand context around the changes.
3. The prep report already contains duplicate findings — use them directly. Do not re-run grep for duplicates. If a name appears in multiple files, note it: "Similar pattern already exists at [file:line] — verify this is intentional and not a copy-paste."
4. Analyze each change for:
   - **Bugs**: Logic errors, off-by-one, null/undefined, race conditions
   - **Security**: Injection, XSS, secrets exposure, OWASP top 10
   - **Performance**: N+1 queries, unnecessary re-renders, memory leaks
   - **Readability**: Unclear names, missing context, overly complex logic
   - **Missing tests**: Changed logic without test coverage
5. Report findings with confidence levels (HIGH / MEDIUM / LOW).
6. Only report HIGH and MEDIUM confidence issues — skip stylistic preferences.

## Rules
- Do NOT make any changes. Only report findings.
- Read the actual code before commenting — never speculate.
- Focus on what matters: bugs and security over style.
- If no issues found, say so clearly.
