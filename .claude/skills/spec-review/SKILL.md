---
name: spec-review
description: Review a completed spec after implementation. Triggers: /spec-review NNN, 'review spec NNN', 'did we complete spec NNN', 'verify spec implementation'.
---

Reviews spec $ARGUMENTS and its code changes against acceptance criteria. Use after spec-work to validate and close.

## Process

### 1. Find the spec
If `$ARGUMENTS` is a number, open `specs/NNN-*.md`. If empty, list specs with status `in-review` and ask. Must be `in-review` — otherwise report status and stop.

### 2. Read the spec
Understand Goal, Steps, Acceptance Criteria, Files to Modify, Out of Scope. Note checked items.

### 3. Inspect code changes
Read `**Branch**` from spec header:
- Branch exists: `git diff main...BRANCH`
- No branch: `git diff` + `git diff --staged`

Read full files for the 5 most changed files; review only diff hunks for the rest.

### 4. Review against spec

**4a — Goal achievement** ("Task done ≠ Goal achieved"):
- Verify the Goal is actually met, not just checkboxes
- Verify acceptance criteria against diff
- Flag Out of Scope violations

For structured criteria: verify Truths (run commands), Artifacts (file exists with real content), Key Links (imports present).

**4b — Definition of Done**: Check `.agents/context/CONVENTIONS.md` DoD section if it exists.

**4c — Code quality** (by complexity):
- Low/Medium: spawn `code-reviewer` agent (model: sonnet)
- High: spawn `code-reviewer` AND `staff-reviewer` in parallel (model: sonnet)
- Review stays on Sonnet for all tiers; do not escalate to Opus for routine spec review.

### 5. Verdict

**APPROVED** — All criteria met, agents returned PASS/CONCERNS:
1. Status → `completed`, move to `specs/completed/`
2. Proceed to Finishing Gate

**CHANGES REQUESTED** — Agent FAIL or criteria not met:
1. Add `## Review Feedback` with fix instructions, status → `in-progress`

**REJECTED** — Critical security/regression:
1. Status → `blocked`, add feedback, suggest next steps

### 6. Finishing Gate (APPROVED only)

Ask user via `AskUserQuestion`:
1. **Merge to main** — `git checkout main && git merge BRANCH && git branch -d BRANCH`
2. **Push and create PR** — `git push -u origin BRANCH && gh pr create`
3. **Keep branch** — report name, no changes
4. **Discard** — confirm first, then `git checkout main && git branch -D BRANCH`

Clean up worktree after merge/push/discard if one exists.

## Rules
- **Read-only** — no code changes, only spec status/feedback updates.
- Read actual code before commenting — never speculate.
- Focus on spec compliance and bugs over style.
- Never push or create PRs without explicit user choice.
