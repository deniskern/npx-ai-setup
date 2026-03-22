# Spec: Expand Prep-Script Architecture with build, lint, pr, changelog

> **Spec ID**: 156 | **Created**: 2026-03-22 | **Status**: completed | **Complexity**: medium | **Branch**: —

## Goal
Add 4 new prep scripts (build-prep.sh, lint-prep.sh, pr-prep.sh, changelog-prep.sh) following the established zero-token green path pattern, and wire them into their corresponding skills.

## Context
The prep-script architecture saves 60-90% tokens by gathering data in shell before Claude touches it. Currently 5 scripts exist (commit, review, test, scan, spec-validate). Four high-value workflows still run without prep: build, lint, PR creation, and changelog/release.

## Steps
- [x] Step 1: Create `templates/scripts/build-prep.sh` — auto-detect build command (npm run build/tsc/go build/make build), run it, emit `BUILD_PASSED` on green (exit 0), filtered first error group on red (exit 2). Pattern: test-prep.sh
- [x] Step 2: Create `templates/scripts/lint-prep.sh` — auto-detect linter (eslint/biome/ruff/golangci-lint), run it, emit `NO_LINT_ERRORS` on clean (exit 0), group findings by severity on issues (exit 2). Pattern: scan-prep.sh
- [x] Step 3: Create `templates/scripts/pr-prep.sh` — collect branch name, commit log vs main, diff stat vs main, full diff vs main, CI status (gh run list if available), linked issues from commit messages. No green/red path — always outputs context. Pattern: commit-prep.sh
- [x] Step 4: Create `templates/scripts/changelog-prep.sh` — parse conventional commits since last tag, group by feat/fix/refactor/breaking/other, emit counts and formatted sections. Green path: `NO_NEW_COMMITS` if HEAD == last tag. Pattern: scan-prep.sh grouping
- [x] Step 5: Update `templates/commands/build-fix.md` — replace inline build-validator spawn with `bash .claude/scripts/build-prep.sh` as Step 0, use prep output for error parsing
- [x] Step 6: Create `templates/commands/lint.md` — new skill that runs lint-prep.sh, reports findings, optionally auto-fixes (eslint --fix / biome check --fix)
- [x] Step 7: Update `templates/commands/pr.md` — add `bash .claude/scripts/pr-prep.sh` as Step 0 before build validation, use prep output for PR body generation
- [x] Step 8: Update `templates/commands/release.md` — add `bash .claude/scripts/changelog-prep.sh` as Step 0, use grouped output for CHANGELOG generation
- [x] Step 9: Mirror all new scripts to `.claude/scripts/` and all command changes to `.claude/commands/`
- [x] Step 10: Test each prep script standalone: verify exit codes, green paths, and output format

## Acceptance Criteria
- [ ] All 4 prep scripts follow established conventions: set -euo pipefail, guard clauses, deterministic exit codes (0/1/2), structured delimiters
- [ ] build-prep.sh and lint-prep.sh have zero-token green paths
- [ ] changelog-prep.sh has zero-token path when no new commits since last tag
- [ ] pr-prep.sh outputs structured context block usable by PR skill
- [ ] All 4 skills (build-fix, lint, pr, release) invoke their prep script as first step
- [ ] New /lint skill is registered in settings.json and bin/ai-setup.sh installer

## Files to Modify
- `templates/scripts/build-prep.sh` — new
- `templates/scripts/lint-prep.sh` — new
- `templates/scripts/pr-prep.sh` — new
- `templates/scripts/changelog-prep.sh` — new
- `templates/commands/build-fix.md` — add prep step
- `templates/commands/lint.md` — new skill
- `templates/commands/pr.md` — add prep step
- `templates/commands/release.md` — add prep step
- `.claude/scripts/` — mirror all 4 new scripts
- `.claude/commands/` — mirror all command changes

## Out of Scope
- Changing existing prep scripts (commit, review, test, scan, spec-validate)
- Adding new test frameworks or linter support beyond common ones
- CI/CD integration beyond reading `gh run list`
