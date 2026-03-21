# Spec: Review-Prep Scripts (review, spec-validate)

> **Spec ID**: 118 | **Created**: 2026-03-21 | **Status**: in-review | **Branch**: spec/118-review-prep-scripts

## Goal
Add prep-scripts for `/review` and `/spec-validate` that pre-collect diffs, detect duplicates, and parse spec structure — giving Claude focused input instead of raw data.

## Context
`/review` spends tokens reading diffs and searching for duplicates. `/spec-validate` spends tokens parsing spec structure. Bash scripts can pre-collect this data and pass only relevant findings to Claude. Depends on Spec 116 for scripts infrastructure.

## Steps
- [x] Step 1: Create `templates/scripts/review-prep.sh` — collects staged + unstaged diff, branch diff vs main, lists changed files, runs grep for duplicate patterns, outputs structured summary
- [x] Step 2: Create `templates/scripts/spec-validate-prep.sh` — reads spec file, counts lines/steps/criteria, checks required sections exist, outputs structural report (fields present/missing, line counts)
- [x] Step 3: Update `templates/commands/review.md` — call review-prep first, Claude receives focused diff + duplicate report
- [x] Step 4: Update `templates/commands/spec-validate.md` — call spec-validate-prep first, Claude scores content quality from pre-parsed structure

## Acceptance Criteria
- [x] review-prep.sh outputs structured Markdown with: file list, diff summary, duplicate findings
- [x] spec-validate-prep.sh outputs: section checklist (present/missing), line counts, structural score
- [x] Claude receives pre-filtered input instead of running git/grep itself

## Files to Modify
- `templates/scripts/review-prep.sh` — new
- `templates/scripts/spec-validate-prep.sh` — new
- `templates/commands/review.md` — add script-prep step
- `templates/commands/spec-validate.md` — add script-prep step

## Out of Scope
- /review + /grill merge (Spec 119)
- Spec-validate scoring redesign (Spec 112)
