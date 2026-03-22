---
model: sonnet
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent
---

Scans recently changed files for tech debt and fixes safe wins. Use at end of session to clean up before committing.

## Process

1. **Scan recent changes**: Run `git diff --name-only HEAD~5` (or fewer if less history) to focus on recently touched files.
2. **Check each file for**:
   - Duplicated code blocks (3+ similar lines appearing in multiple places)
   - Dead exports (exported but never imported anywhere)
   - Unused imports
   - TODO/FIXME/HACK comments that could be resolved now
   - Inconsistent patterns compared to the rest of the codebase
3. **Report findings** grouped by category with file paths and line numbers.
4. **Fix clear wins only**: Remove unused imports, delete dead exports, consolidate obvious duplicates. Leave anything ambiguous for the user.

5. **Verify fixes**: Spawn `verify-app` via Agent tool with the prompt:
   > "Run the project's test suite and build command. Report PASS or FAIL with details."
   - If **PASS**: report what was cleaned up and stop.
   - If **FAIL**: read the error output, fix only the regressions caused by the debt cleanup (do not introduce new changes), then re-run verify-app.
   - Retry up to **2 times**. If still failing after 2 retries: revert the last change (`git checkout -- <file>`), report the failure, and stop.

## Rules
- Only scan recently changed files — not the entire codebase.
- Fix only clear, safe wins. Do not refactor working code.
- Do not change public APIs or behavior.
- Report but do not fix anything you're unsure about.

## Next Step

After cleaning up tech debt, run `/commit` to checkpoint the changes, or `/reflect` to capture any architectural discoveries from the sweep.
