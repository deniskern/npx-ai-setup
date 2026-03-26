---
description: "Runs the project test suite and fixes failures in source code. Uses `test-prep.sh` to auto-detect and execute tests — green builds use 0 LLM tokens, Claude only activates on failure."
model: sonnet
allowed-tools: Read, Write, Edit, Bash, Glob, Grep
---

Runs the project test suite and fixes failures in source code. Uses `test-prep.sh` to auto-detect and execute tests — green builds use 0 LLM tokens, Claude only activates on failure.

## Process

1. **Run the prep script** (zero LLM tokens):
   ```
   ! bash .claude/scripts/test-prep.sh
   ```
   - Output `ALL_TESTS_PASSED` (exit 0) → **short-circuit**: report success and stop. No further LLM processing needed.
   - Exit 1 → no test framework detected; report the error and stop.
   - Exit 2 → failures found; output contains filtered failure summary and last 80 lines of full output.

2. **Analyze the failure output** — identify failing tests from the prep summary.

3. **For each failing test**:
   - Read the failing test file to understand what it expects.
   - Read the source file being tested.
   - Fix the **source code** (not the tests) to make tests pass.

4. **Re-run via prep script** and repeat with explicit attempt tracking:
   - **Attempt 1**: Apply fixes, re-run prep script. `ALL_TESTS_PASSED` → stop.
   - **Attempt 2**: Re-analyze new failure output, apply further fixes, re-run. `ALL_TESTS_PASSED` → stop.
   - **Attempt 3**: Final round of fixes, re-run. `ALL_TESTS_PASSED` → stop.

5. If still failing after Attempt 3, report what was tried and what remains broken.

## Rules
- Fix source code, not tests (unless the test itself has a clear bug).
- Do not delete or skip failing tests.
- Do not install new dependencies without asking.
- If no test framework is detected, tell the user and stop.

## Coverage Gap Detection

After all tests pass, check if the changes introduced new untested code:
- Run `git diff --name-only` to identify changed source files
- For each changed file, check if a corresponding test file exists
- If test files are missing for changed source code, spawn `test-generator` agent (model: sonnet) to generate missing tests

Skip this step if the user explicitly only asked to fix failing tests.

## Next Step

After tests pass, run `/review` to check uncommitted changes, or `/commit` to stage and commit the fixes.
