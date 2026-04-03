# Spec: Git Workflow Streamlining

> **Spec ID**: 620 | **Created**: 2026-04-03 | **Status**: completed | **Complexity**: medium | **Branch**: —

## Goal
Tighten the local `commit` / `push` / `PR` workflow so it is faster, more consistent, and better aligned with the documented team flow.

## Context
The current workflow is split across commit guidance, PR drafting, permissions, hooks, and release steps. The separation is sound, but there are clear friction points: commit next-step hints do not match the actual workflow routing, PR creation stops just before the final operational step, and push permissions are narrower than the documented branch flow. This spec defines a coherent Git flow that can be exercised end to end without weakening the safety defaults.

### Verified Assumptions
- `commit` is intentionally local-only and should never auto-push. — Evidence: `.claude/commands/commit.md` | Confidence: High | If Wrong: the entire safety model changes
- PR creation currently prefers `gh pr create`, but only after manual `git push`. — Evidence: `.claude/commands/pr.md` | Confidence: High | If Wrong: some of the optimization work is unnecessary
- Push rules are stricter than the documented generic feature-branch flow. — Evidence: `.claude/settings.json`, `README.md` | Confidence: High | If Wrong: the current mismatch is only perceived, not real
- Pre-push checks are already available via tracked hooks and should remain part of the flow. — Evidence: `README.md` hook section | Confidence: High | If Wrong: push hardening needs a different guardrail

## Steps
- [x] Step 1: Audit the current `commit`, `pr`, `release`, workflow-hint, and permission files to produce one explicit source-of-truth flow for local commit, branch push, draft PR, and release handoff.
- [x] Step 2: Update the commit workflow so its next-step guidance matches the routing rules, including clear branch-aware handoff to `/pr` or `/release`.
- [x] Step 3: Update the PR workflow so it cleanly distinguishes between drafting metadata and the final user-confirmed publish step, with an explicit recommended `gh` path and a manual URL fallback.
- [x] Step 4: Normalize push permissions and branch expectations so the documented workflow and enforced workflow describe the same allowed branch strategy.
- [x] Step 5: Decide whether a dedicated publish shortcut skill is warranted for `push + draft PR` after explicit confirmation, and either add it or document why the existing split remains preferable.
- [x] Step 6: Update docs so the default engineering flow is easy to follow as a short sequence: review -> commit -> push -> PR -> CI / merge.

## Acceptance Criteria

### Truths
- [x] The documented workflow and the enforced permission model no longer contradict each other for normal feature-branch work.
- [x] `/commit` points to the correct next action instead of ending in a dead-end hint.
- [x] `/pr` clearly documents the preferred `gh`-based path and the exact boundary between automated drafting and user-confirmed publish.

### Artifacts
- [x] One updated workflow/rules source that explicitly covers commit, push, PR, and release handoff.
- [x] Updated command/skill text for `/commit` and `/pr`.
- [x] Updated permission or branch-policy config if the chosen flow requires it.

## Files to Modify
- `.claude/commands/commit.md` - align post-commit guidance with the actual team workflow
- `.claude/commands/pr.md` - clarify the publish boundary and preferred `gh` path
- `.claude/rules/workflow.md` - make workflow hints authoritative and internally consistent
- `.claude/settings.json` - align push permissions with the intended branch strategy if needed
- `README.md` - document the final recommended commit/push/PR flow
- `templates/skills/pr/SKILL.md` - keep the template-side PR behavior in sync if the local flow changes
- `templates/skills/release/SKILL.md` - preserve the release handoff boundary if adjacent wording changes

## Out of Scope
- Replacing `git` commit/push with GitHub CLI for all operations
- Auto-merging PRs or changing GitHub repository protection rules
- Reworking release automation beyond the handoff points relevant to the standard Git flow
