# Spec: Multi-Tool Skills Symlinks for Codex and OpenCode

> **Spec ID**: 074 | **Created**: 2026-03-10 | **Status**: completed | **Branch**: —

<!-- Status lifecycle: draft → in-progress → in-review → completed (or blocked at any stage) -->

## Goal
Share installed skills with Codex CLI and OpenCode automatically by creating tool-specific symlinks during setup.

## Context
Codex CLI reads skills from `.codex/skills/` and OpenCode from `.opencode/skills/` — both using the identical `SKILL.md` format as Claude Code's `.claude/skills/`. A symlink from each tool's skills directory to `.claude/skills` makes all installed skills instantly available in all three tools without duplication. OpenCode already reads `.claude/commands/` natively so commands need no changes. ai-setup already generates `opencode.json` and a `.agents/skills` symlink, so this pattern is established.

## Steps
- [x] Step 1: In `lib/setup.sh`, add `ensure_codex_skills_alias()` — creates `.codex/skills` → `.claude/skills` symlink if `command -v codex` succeeds; skips silently if codex not installed
- [x] Step 2: In `lib/setup.sh`, add `ensure_opencode_skills_alias()` — creates `.opencode/skills` → `.claude/skills` symlink if `command -v opencode` succeeds; skips silently if opencode not installed
- [x] Step 3: Call both functions from `bin/ai-setup.sh` after `ensure_skills_alias` in the install flow
- [x] Step 4: In `lib/update.sh`, call both functions in `run_smart_update` alongside existing `ensure_skills_alias` call
- [x] Step 5: Add `.codex/skills` and `.opencode/skills` to `.gitignore` template (they are symlinks, not source files)
- [x] Step 6: Add both functions to function-presence checks in `tests/smoke.sh`

## Acceptance Criteria
- [x] `.codex/skills` symlink is created when `codex` CLI is installed, skipped otherwise
- [x] `.opencode/skills` symlink is created when `opencode` CLI is installed, skipped otherwise
- [x] Both symlinks point to the same canonical `.claude/skills` directory
- [x] Neither symlink is committed to git (covered by .gitignore)

## Files to Modify
- `lib/setup.sh` - two new alias functions
- `bin/ai-setup.sh` - call both new functions
- `lib/update.sh` - call both new functions on update
- `templates/.gitignore` - add .codex/skills and .opencode/skills

## Out of Scope
- Commands compatibility with Codex CLI (different format, not feasible)
- OpenCode commands (already works via .claude/commands/ natively)
- Installing or detecting Codex/OpenCode if not already present
