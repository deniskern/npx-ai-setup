# Spec: Pre-Release Validation Script

> **Spec ID**: 127 | **Created**: 2026-03-21 | **Status**: in-review | **Complexity**: medium | **Branch**: —

## Goal

Add a `scripts/validate-release.sh` script that checks version consistency, changelog entries, and template integrity before publishing a new release.

## Context

Manual release steps risk shipping with missing CHANGELOG entries, broken templates, or mismatched version numbers. A pre-flight validation script catches these issues before the version bump.

## Steps

- [x] Step 1: Create `scripts/validate-release.sh` with checks: version matches in package.json + CHANGELOG.md, no uncommitted changes
- [x] Step 2: Add template integrity check: all files in `templates/` are valid (no empty files, no broken symlinks)
- [x] Step 3: Add command/agent count validation: count files in templates/commands/ and templates/agents/, report counts
- [x] Step 4: Read the current `templates/commands/release.md` and integrate validation as pre-flight check (run validation before version bump)

## Acceptance Criteria

- [x] `scripts/validate-release.sh` exits 0 when all checks pass
- [x] Script exits 1 with a clear FAIL message on first failing check
- [x] Each check prints a PASS or FAIL line
- [x] Script is executable (chmod +x)
- [x] No `jq` hard dependency (falls back to grep/sed)
- [x] `templates/commands/release.md` references the validation script as step 0 pre-flight

## Files to Modify

- `scripts/validate-release.sh` — new file
- `templates/commands/release.md` — add pre-flight validation step
- `specs/127-pre-release-validation.md` — this file

## Out of Scope

- Automated publishing (npm publish)
- CI integration
- Network checks (npm registry, git remote)
