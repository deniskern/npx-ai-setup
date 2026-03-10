# Spec: Replace Statusline with claude-powerline

> **Spec ID**: 075 | **Created**: 2026-03-10 | **Status**: completed | **Branch**: —

<!-- Status lifecycle: draft → in-progress → in-review → completed (or blocked at any stage) -->

## Goal
Replace the custom `statusline.sh` script with `@owloops/claude-powerline` for a visual, theme-aware powerline statusline out of the box.

## Context
`install_statusline_project()` in `lib/setup.sh` currently copies `templates/statusline.sh` and wires it into `settings.json`. claude-powerline (https://github.com/Owloops/claude-powerline) offers themes, powerline styles, git integration, and cost tracking with zero maintenance. Replacing the script-based approach eliminates ~100 lines of shell script in favour of a maintained npm package run via `npx`.

## Steps
- [x] Step 1: Rewrite `install_statusline_project()` in `lib/setup.sh` — set statusLine command to `npx -y @owloops/claude-powerline@latest --style=powerline --theme=dark`; copy `templates/.claude-powerline.json` → `.claude/claude-powerline.json` (skip if already present); remove `cp statusline.sh` lines
- [x] Step 2: Create `templates/.claude-powerline.json` with default config: dark theme, powerline style, enabled segments (directory, git, model, session, today, context), autoWrap enabled
- [x] Step 3: Delete `templates/statusline.sh` (no longer installed); update `lib/core.sh` TEMPLATE_EXCLUDES to remove `statusline.sh` entry

## Acceptance Criteria
- [x] Fresh install: `.claude/settings.json` statusLine points to `npx -y @owloops/claude-powerline@latest`
- [x] Fresh install: `.claude/claude-powerline.json` is created with default config
- [x] Fresh install: `.claude/statusline.sh` is NOT created
- [x] Idempotency: re-running install skips if statusLine already configured
- [x] Smoke tests pass (82/82)

## Files to Modify
- `lib/setup.sh` — rewrite `install_statusline_project()`
- `lib/core.sh` — remove `statusline.sh` from TEMPLATE_EXCLUDES
- `templates/.claude-powerline.json` — new file
- `templates/statusline.sh` — delete

## Out of Scope
- Update-badge from old statusline.sh (lost; handled by hooks separately)
- Context-monitor bridge from old statusline.sh (handled by hooks separately)
- Existing installs (idempotency guard preserves existing statusLine config)
