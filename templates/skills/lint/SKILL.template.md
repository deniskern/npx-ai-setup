---
name: ais:lint
description: Runs the project linter, reports findings grouped by severity, and optionally auto-fixes issues.
model: sonnet
argument-hint: "[optional: --fix to auto-fix]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash
---

Runs the project linter, reports findings grouped by severity, and optionally auto-fixes issues.

## When NOT to Use

- **Type errors** — use `/build-fix` for TypeScript/compiler errors
- **Test failures** — use `/test`
- **Security vulnerabilities** — use `/scan`

## Process

### 1. Run Lint Prep

Run `! bash .claude/scripts/lint-prep.sh`

- If output contains `NO_LINT_ERRORS`: report "Lint clean — nothing to fix." and stop.
- If exit 1: linter not detected — report the error and stop.
- If exit 2: proceed to step 2.

### 2. Analyze Findings

Parse the `=== ERRORS ===` and `=== WARNINGS ===` sections from the prep output.

Group findings by:
- **File** — which files have the most issues
- **Rule** — which lint rules are most violated
- **Severity** — errors before warnings

Report a summary table: file | rule | count.

### 3. Auto-Fix (if --fix requested)

If `$ARGUMENTS` contains `--fix`:

Detect linter and run the fix command:
- biome: `! biome check --fix .`
- eslint: `! eslint --fix .`
- ruff: `! ruff check --fix .`
- golangci-lint: does not support auto-fix — skip and report manually

### 4. Verify

Re-run `! bash .claude/scripts/lint-prep.sh` after any fixes.

- If `NO_LINT_ERRORS`: report clean.
- If still exit 2: report remaining issues with count delta (before vs after).

### 5. Report

```
## Lint Report
- Status: CLEAN / ISSUES FOUND
- Linter: [detected linter]
- Errors: N
- Warnings: N
- Files affected: [list]
- Auto-fixed: yes / no / not supported
```

If issues remain, list top 5 with file path, line, rule name, and suggested fix.

## Rules

- Never disable lint rules to silence errors
- Never add eslint-disable / biome-ignore comments without explaining why in a code comment
- Commit nothing — leave staging to the user
- If `$ARGUMENTS` specifies a path (e.g., `src/`), scope the linter to that path only

## Next Step

If lint is clean, run `/review` for a full code review, or `/commit` to stage and commit changes.
