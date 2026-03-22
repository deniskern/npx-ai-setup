# Spec: Workflow Flow Hints and Documentation Restructuring

> **Spec ID**: 156 | **Created**: 2026-03-22 | **Status**: completed | **Complexity**: medium | **Branch**: —

## Goal
Add next-step suggestions to all commands and restructure documentation to separate onboarding from the development cycle.

## Context
Commands work in isolation — users must know the cycle order themselves. 5 of 24 commands already have post-action hints (commit, pr, spec-work, build-fix, update). This spec standardizes the pattern across all commands and restructures WORKFLOW-GUIDE.md into clear phases: Onboarding, Cycle (Plan → Execute → Review → Release), and Session Management. Also documents the emergency hotfix path.

### Verified Assumptions
- Next-Step-Hints are static text, not runtime branching — Evidence: existing Post-Commit/PR hints | Confidence: High | If Wrong: would need conditional logic in each command
- Emergency path needs no dedicated /hotfix command — Evidence: /debug + /commit + /pr cover it | Confidence: High | If Wrong: would need a new command file
- Local .claude/commands/ are synced from templates/ at the end — Evidence: current repo practice | Confidence: High | If Wrong: would need separate edits

## Steps
- [x] Step 1: Define the next-step mapping (which command suggests which) as a reference table in this spec's PR description, then add `## Next Step` sections to the 19 commands that lack them in `templates/commands/`
- [x] Step 2: Restructure `templates/WORKFLOW-GUIDE.md` — rename categories to Onboarding (discover, evaluate, analyze), Cycle (spec → spec-work → test → review → commit → pr → release), Session (pause, resume, reflect, doctor, update) and add a "Hotfix Flow" section
- [x] Step 3: Mirror the same restructuring to `.claude/WORKFLOW-GUIDE.md`
- [x] Step 4: Copy all modified `templates/commands/*.md` to `.claude/commands/` to sync local state

## Acceptance Criteria

### Truths
- [x] "Every command in templates/commands/ has a `## Next Step` or `## Post-*` section"
- [x] "WORKFLOW-GUIDE.md contains sections: Onboarding, Development Cycle, Session & Maintenance, and Hotfix Flow"
- [x] "`diff templates/commands/ .claude/commands/` shows no differences"

## Files to Modify
- `templates/commands/*.md` (19 files) — add Next Step sections
- `templates/WORKFLOW-GUIDE.md` — restructure categories, add hotfix flow
- `.claude/WORKFLOW-GUIDE.md` — mirror template changes
- `.claude/commands/*.md` — sync from templates

## Out of Scope
- New commands (/lint, /ci) — see Spec 157
- Runtime conditional hints (if-then branching in commands)
