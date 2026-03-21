# Spec: Hybrid Script Commands (scan, commit, test)

> **Spec ID**: 117 | **Created**: 2026-03-21 | **Status**: in-review | **Branch**: spec/117-hybrid-script-commands

## Goal
Add Bash prep-scripts to `/scan`, `/commit`, and `/test` that gather data with zero tokens, then pass focused input to Claude for the AI-dependent parts only.

## Context
These commands need Claude for analysis/generation but waste tokens on data gathering (running npm audit, collecting git diffs, executing test suites). Script-prep collects and filters data, Claude receives a focused summary. Depends on Spec 118 for the scripts infrastructure in `bin/ai-setup.sh`.

## Steps
- [x] Step 1: Create `templates/scripts/scan-prep.sh` — runs `npm audit --json` (or pip/snyk/bundler), groups by severity, outputs filtered summary
- [x] Step 2: Create `templates/scripts/commit-prep.sh` — collects `git diff --staged`, `git log --oneline -5`, branch name, outputs combined context
- [x] Step 3: Create `templates/scripts/test-prep.sh` — runs test command (auto-detect: npm test/pytest/go test), if green → outputs "PASS" (0 tokens needed), if red → outputs filtered failure summary
- [x] Step 4: Update `templates/commands/scan.md` — call prep script first, pass output to Claude for recommendations only
- [x] Step 5: Update `templates/commands/commit.md` — call prep script first, Claude generates commit message from focused context
- [x] Step 6: Update `templates/commands/test.md` — call prep script first, short-circuit on green (no Claude), Claude analyzes only on red

## Acceptance Criteria
- [x] `/test` with green tests uses 0 LLM tokens (script handles entirely)
- [x] `/scan` passes pre-filtered audit data to Claude (not raw JSON)
- [x] `/commit` passes focused diff context (not full repo state)
- [x] All prep scripts exit 0 on success, 1 on tool-not-found with helpful message

## Files to Modify
- `templates/scripts/scan-prep.sh` — new
- `templates/scripts/commit-prep.sh` — new
- `templates/scripts/test-prep.sh` — new
- `templates/commands/scan.md` — add script-prep step
- `templates/commands/commit.md` — add script-prep step
- `templates/commands/test.md` — add script-prep step

## Out of Scope
- Pure script commands (Spec 118)
- Review-prep scripts (Spec 118)
