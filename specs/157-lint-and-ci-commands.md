# Spec: Add /lint and /ci Commands

> **Spec ID**: 157 | **Created**: 2026-03-22 | **Status**: in-review | **Complexity**: medium | **Branch**: —

## Goal
Add two new commands — /lint for lightweight code formatting and /ci for post-PR CI monitoring — to close the remaining gaps in the development cycle.

## Context
The cycle has no lightweight lint step between execute and review (/review with opus is too heavy for formatting). After /pr, there's no way to check CI status. Both follow the established prep-script pattern (zero LLM tokens on green path). Part 2 of 2 — see Spec 156 for flow hints and documentation.

### Verified Assumptions
- /lint needs a prep-script following test-prep.sh pattern — Evidence: test/scan/commit all use prep scripts | Confidence: High | If Wrong: would need a different architecture
- /ci is a standalone command, not an extension of /pr — Evidence: /pr is already complex with staff-review | Confidence: High | If Wrong: would bloat /pr further

## Steps
- [x] Step 1: Create `templates/scripts/lint-prep.sh` — detect linter (eslint/prettier/biome/stylelint/rubocop/ruff), run it, output `NO_LINT_ISSUES` on success or filtered issues on failure
- [x] Step 2: Create `templates/commands/lint.md` — model: sonnet, runs lint-prep.sh, auto-fixes on failure (up to 2 attempts), follows prep-script zero-token pattern
- [x] Step 3: Create `templates/commands/ci.md` — model: haiku, runs `gh pr checks` / `gh run list`, reports status, suggests `/build-fix` on failure
- [x] Step 4: Copy new files to `.claude/commands/` and `.claude/scripts/`, update command count in `templates/WORKFLOW-GUIDE.md` and README.md (24 → 26)
- [x] Step 5: Verify both commands have `## Next Step` sections (per Spec 156 pattern)

## Acceptance Criteria

### Truths
- [x] "`bash templates/scripts/lint-prep.sh` exits 0 in a project with no lint issues"
- [x] "README.md and WORKFLOW-GUIDE.md state 26 commands"

### Artifacts
- [x] `templates/scripts/lint-prep.sh` — detects and runs project linter (min 40 lines)
- [x] `templates/commands/lint.md` — prep-script-based lint command (min 20 lines)
- [x] `templates/commands/ci.md` — CI status check via gh CLI (min 15 lines)

### Key Links
- [x] `templates/commands/lint.md` → `templates/scripts/lint-prep.sh` via `! bash .claude/scripts/lint-prep.sh`

## Files to Modify
- `templates/scripts/lint-prep.sh` — new prep script
- `templates/commands/lint.md` — new command
- `templates/commands/ci.md` — new command
- `templates/WORKFLOW-GUIDE.md` — update count and add entries
- `README.md` — update command count

## Out of Scope
- Next-step hints for existing commands — see Spec 156
- Linter installation or configuration (only use what's already installed)
