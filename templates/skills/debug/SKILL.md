---
name: debug
description: "Investigates and fixes bug: $ARGUMENTS. Use when a defect needs hypothesis-driven root-cause analysis and a minimal targeted fix."
model: sonnet
argument-hint: "[bug description]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent
---

Investigates and fixes bug: $ARGUMENTS. Use when a defect needs hypothesis-driven root-cause analysis and a minimal targeted fix.

## Process

### 1. Reproduce
- Identify the exact condition that triggers the bug
- If steps to reproduce are unclear, ask before proceeding
- Locate the relevant code path (use Grep/Glob, read 2-3 files max)

### 2. Hypothesis
- State your hypothesis: "I believe the bug is caused by X because Y."
- Do NOT skip this step. No fix without a written hypothesis.
- **Red Flag Detection** — check for these before proceeding:
  - Silent exception swallowing (empty catch blocks, bare `except:`)
  - Bare catch blocks that hide the real error
  - Missing error propagation (errors logged but not rethrown/returned)
  - State mutations happening in unexpected order
  - Off-by-one errors in loops or index access

### 3. Root Cause Isolate
- Trace the execution path to find where behavior diverges from expected
- State the root cause in one sentence: "Root cause: ..."
- If the hypothesis was wrong, update it — don't silently discard it

## Debugging Discipline

Follow these rules strictly when investigating and fixing:

1. **Hypothesis first.** State what you think is wrong and why, then test that specific theory. Don't shotgun-fix.
2. **One variable at a time.** Make one change, test, observe. Multiple simultaneous changes mean you can't attribute what worked.
3. **Read completely.** When investigating, read entire functions and their imports, not just the line that looks relevant.
4. **Distinguish "I know" from "I assume."** Observable facts (the error says X, the test output shows Y) are strong evidence. Assumptions (this library should work this way) need verification.
5. **Stop after 3 failed fixes.** If you've tried 3+ fixes without progress, your mental model is probably wrong. Stop. List what you know for certain. List what you've ruled out. Form fresh hypotheses from there.
6. **Don't fix symptoms.** Understand *why* something fails before changing code. A test that passes after a change you don't understand is luck, not a fix.

### 4. Fix
- Make the minimal change that fixes the root cause
- Do NOT refactor surrounding code or add unrelated improvements
- If the fix touches more than 3 files, stop and suggest creating a spec instead

### 5. Regression Test
- Write a test that **fails without the fix** and **passes with it**
- If no test framework is available, document the exact manual reproduction steps that prove the fix holds
- This step is mandatory — do not skip it

### 6. Verify
Spawn `verify-app` via Agent tool:
> "Verify the bug fix. Run the test suite if available. Run the build if available. Report PASS or FAIL."
- If **FAIL**: report the output and stop. Do NOT proceed to review. Suggest: re-investigate the root cause.
- If **PASS**: continue to Step 7.

### 7. Review
Spawn `code-reviewer` via Agent tool. Pass the changed files and a one-line description of the fix.
- Verdict **PASS** or **CONCERNS**: done, report fix as complete.
- Verdict **FAIL**: flag for manual review, report the issues.

## Rules
- Fix only what is broken. No scope creep.
- If the bug is unclear or cannot be reproduced, ask the user before writing any code.
- If the root cause requires architectural changes, stop and recommend `/spec` instead.

## Next Step

After a successful fix, run `/commit` to stage and commit the bug fix with a conventional commit message.
