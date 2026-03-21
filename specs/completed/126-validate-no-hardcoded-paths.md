# Spec: Add validate-no-hardcoded-paths CI Script

> **Spec ID**: 126 | **Created**: 2026-03-21 | **Status**: in-review | **Branch**: main

## Goal
Add a validation script that checks all git-tracked files for hardcoded absolute paths (`/Users/*`, `/home/*`) to prevent privacy leaks and ensure portability.

## Context
Hardcoded paths break portability and can leak developer usernames. Octopus has `validate-no-hardcoded-paths.sh` for this. We generate templates that get installed across projects — a hardcoded path in a template propagates to every consumer. Adapted from claude-octopus scripts/validate-no-hardcoded-paths.sh.

## Steps
- [x] Step 1: Create `scripts/validate-no-hardcoded-paths.sh` — scans `git ls-files` for patterns `/Users/`, `/home/`, `C:\\Users\\` in non-binary files
- [x] Step 2: Add allowlist for legitimate paths (e.g., documentation examples, test fixtures)
- [x] Step 3: Add to pre-commit or CI check (exit 1 on findings, list all violations with file:line)
- [x] Step 4: Run against current codebase and fix any existing violations

## Acceptance Criteria
- [x] Script detects hardcoded absolute paths in all git-tracked files
- [x] Allowlist prevents false positives on documentation/examples
- [x] Exit code 1 on violations with clear file:line output
- [x] Current codebase passes the check

## Files to Modify
- `scripts/validate-no-hardcoded-paths.sh` — new
- Existing files with hardcoded paths — fix violations

## Out of Scope
- Pre-release validation script (Spec 127)
- CI pipeline setup (GitHub Actions)
