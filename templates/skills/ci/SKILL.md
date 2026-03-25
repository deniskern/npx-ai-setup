---
description: Checks CI status for the current branch — runs `gh pr checks` and `gh run list`, reports pass/fail, and suggests next steps.
model: haiku
allowed-tools: Bash
---

Checks CI status for the current branch — runs `gh pr checks` and `gh run list`, reports pass/fail, and suggests next steps.

## When NOT to Use

- **Before opening a PR** — use `/pr` which includes CI checks in pr-prep.sh
- **Build errors in your local code** — use `/build-fix`
- **Test failures locally** — use `/test`

## Process

### 1. Check PR Checks

Run:

```
! gh pr checks 2>&1 || true
```

- If output contains all passing checks: report CI green and stop.
- If command fails with "no pull request found": branch has no open PR — skip to step 2.
- If any checks show `fail` or `cancelled`: proceed to step 3.

### 2. Check Recent Workflow Runs (no open PR)

Run:

```
! gh run list --branch "$(git rev-parse --abbrev-ref HEAD)" --limit 5 2>&1
```

Parse the output:
- `completed / success` — CI green.
- `completed / failure` or `in_progress` — report status and affected workflows.

### 3. Report Status

Always report:

```
## CI Status
- Branch: [branch name]
- Checks: PASSED / FAILED / IN PROGRESS / NO PR
- Failed checks: [list or "none"]
- Last run: [workflow name, status, timestamp]
```

If any check failed, list:
- Workflow name
- Step that failed (if visible)
- Link to the run (`gh run view <id> --log-failed`)

### 4. Suggest Next Step

- CI green → run `/review` or `/commit` if you have uncommitted changes.
- CI failing → run `/build-fix` for build/type errors, or `/test` for test failures.
- PR not found → push the branch and open a PR with `/pr`.

## Rules

- Never re-trigger CI runs — read-only observation only
- Do not modify any files
- If `gh` is not installed or not authenticated, report the error and stop

## Next Step

If CI is green, run `/review` to check uncommitted changes or `/pr` to open a pull request.
If CI is failing, run `/build-fix` for compiler errors or `/test` for test failures.
