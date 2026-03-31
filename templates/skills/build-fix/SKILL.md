---
name: build-fix
description: "Active build-fixer: runs the build, parses the first error, applies a minimal fix, rebuilds — repeat until green or guard rails trigger."
model: sonnet
argument-hint: "[optional: build command override]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent
---

Active build-fixer: runs the build, parses the first error, applies a minimal fix, rebuilds — repeat until green or guard rails trigger.

## When NOT to Use

- **Architecture issues** — stop and run `/spec` or spawn `code-architect`
- **Test failures** — use `/test` instead; this command fixes build errors only
- **Refactoring needed** — use `/techdebt` or open a spec
- **Error is a missing dependency** — install it manually first, then re-run

## Guard Rails (non-negotiable)

- Max **10 iterations** — abort if still failing after iteration 10
- Max **5% of lines changed** per file per fix — no wholesale rewrites
- No architectural changes — types, imports, small logic only
- No new files unless fixing a missing export (single file, ≤20 lines)
- If the same error recurs after 2 fixes, stop and report — do not loop

## Process

### 0. Prep

Run `! bash .claude/scripts/build-prep.sh` to auto-detect the build command and get initial status.

- If output contains `BUILD_PASSED`: report "Build already green — nothing to fix." and stop.
- If exit 2: parse the `=== BUILD ERRORS ===` section to identify the first error group and proceed to the fix loop.
- If exit 1: build system not detected — ask user to specify the build command via `$ARGUMENTS`.

### 1. Fix Loop (up to 10 iterations)

### 2. Fix Loop (up to 10 iterations)

For each iteration:

#### 2a. Parse Error
- Extract: error type, file path, line number, message
- Classify: type error | import error | syntax error | missing export | other
- If "other" and unrecognizable: stop, report the raw error, recommend manual intervention

#### 2b. Plan Fix
State the fix in one sentence before touching any file:
> "Fix: [what will change] in [file] at line [N] because [reason]."

Check guard rails:
- Calculate lines to change vs total file lines — if >5%, stop and escalate
- If fix requires changing >2 files simultaneously, stop and open a spec

#### 2c. Apply Fix
- Read the target file completely before editing
- Make the minimal change — do not touch surrounding code
- Verify the change compiles in isolation where possible (e.g., `tsc --noEmit` on the single file)

#### 2d. Rebuild
Run `! bash .claude/scripts/build-prep.sh` again. Capture result.

If output contains `BUILD_PASSED`: exit loop → go to Step 3.
If **FAIL**: check for new errors vs same error:
  - New error: continue loop with next iteration
  - Same error after 2nd attempt: abort, report "Unfixable automatically — see error below."

### 2e. Validate (after build passes)
After build passes, spawn `build-validator` agent (model: haiku) to confirm the build is truly green and check for warnings that might indicate fragile fixes.

### 3. Report

```
## Build-Fix Report
- Iterations: N / 10
- Status: GREEN / ABORTED
- Files changed: [list]
- Fixes applied:
  1. [file:line] — [what was fixed]
  2. ...
- Exit reason: [build passed | max iterations | guard rail | unfixable error]
```

If aborted, append:
```
## Next Steps
- Last error: [raw message]
- Suggested action: [manual fix | open spec | /debug | /spec]
```

## Rules

- Never run `--force` or ignore TypeScript strict checks to silence errors
- Never delete type definitions to make errors disappear
- If $ARGUMENTS contains a build command (e.g., `npm run build:prod`), use that instead of auto-detected command
- Commit nothing — leave staging to the user
