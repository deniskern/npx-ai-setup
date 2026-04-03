---
name: pr
description: Drafts a pull request with staff review and PR body. Use when a feature branch is ready to be submitted for review.
model: haiku
allowed-tools: Read, Bash, Glob, Grep, Agent
---

Drafts a pull request with staff review and PR body. Use when a feature branch is ready to be submitted for review.

## Process

### 0. Collect PR Context

Run `! bash .claude/scripts/pr-prep.sh` to gather branch diff, commit history, CI status, and linked issues.

- Use the `=== COMMITS AHEAD OF main ===` section to understand what changed.
- Use `=== DIFF STAT vs main ===` for the PR summary.
- Use `=== LINKED ISSUES ===` to populate "Closes #NNN" in the PR body.
- Use `=== CI STATUS ===` to verify CI is passing before proceeding.

### 1. Build Validation

Run `! bash .claude/scripts/build-prep.sh`.

- If output contains `BUILD_PASSED`: continue.
- If exit 2: stop immediately and tell the user: "Fix the build before creating a PR." Show the error section. Do not proceed.

### 2. Analyze Changes

Use the diff and commits from the pr-prep.sh output to understand all modifications on this branch.

### 3. Stage Uncommitted Changes

Stage and commit any remaining uncommitted changes (descriptive message, no `git add .`).

### 4. Staff Review

Spawn `staff-reviewer` via Agent tool with the prompt:
> "Review this branch for production readiness before PR creation. Branch: <branch-name>. Recent commits: <commits from pr-prep output>."

- If staff-reviewer returns **APPROVE**: continue drafting PR normally; note "Staff review: APPROVED" in the output.
- If staff-reviewer returns **APPROVE WITH CONCERNS**: continue drafting PR; include the concerns under `## Staff Review Concerns` in the PR body.
- If staff-reviewer returns **REQUEST CHANGES**: stop, show the reviewer's concerns, and tell the user: "Fix the reported issues before creating the PR."

### 5. Draft PR

Draft the PR title (short, under 70 chars) and body (`## Summary` with 2-3 bullets + `## Test plan` checklist). Include any linked issues from the prep output.

### 6. Show Commands

Show the user the PR details and the preferred commands to run:
```
git push -u origin <branch>
gh pr create --title "..." --body "..."
```

Explain the publish boundary explicitly:
- This skill drafts PR metadata only.
- The user still confirms the actual `git push` and `gh pr create` step.
- Prefer `gh pr create` over manual browser entry when `gh` is installed.

## Next Step

> 🔄 Naechster Schritt: `/ci` — CI-Status pruefen, dann `/reflect` fuer Learnings

## Rules
- Never push (`git push` is denied by settings).
- Never push to main/master directly.
- If the branch is `main` or `master`, stop and ask the user to create a feature branch first.
- If `gh` CLI is not installed, provide the GitHub URL for manual PR creation.
