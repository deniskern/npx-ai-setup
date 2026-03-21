# Spec 124: Quality Principles as Reusable Rules Templates

**Status:** in-review
**Created:** 2026-03-21

## Problem

Our agents each define their own ad-hoc checklists, leading to inconsistency. Shared principles ensure every reviewer checks the same things.

## Solution

Add 4 quality principle rule files as templates that agents and commands can reference for consistent code quality checks.

## Steps

- [x] Step 1: Create `templates/claude/rules/quality-general.md`
- [x] Step 2: Create `templates/claude/rules/quality-performance.md`
- [x] Step 3: Create `templates/claude/rules/quality-security.md`
- [x] Step 4: Create `templates/claude/rules/quality-maintainability.md`
- [x] Step 5: Add references in `perf-reviewer`, `code-reviewer`, `staff-reviewer`
- [x] Step 6: Verify install flow includes quality rules

## Notes

- Rule files live in `templates/claude/rules/` (not `templates/rules/`) — `install_rules()` reads from `$TPL/claude/rules`
- Auto-included: `install_rules()` iterates all files in that directory
