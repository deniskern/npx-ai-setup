# Spec: Personal Config Token Optimization

> **Spec ID**: 089 | **Created**: 2026-03-15 | **Status**: in-progress | **Branch**: —

## Goal
Reduce personal Claude config overhead by ~350 tokens/session and eliminate duplicate MCP registrations.

## Context
Token optimizer audit found MEMORY.md duplicates (~90 tokens), unused skills in the active menu (~200 tokens), and a duplicate context7 MCP entry (~30 tokens). Steps 5-6 set env vars in ~/.claude/settings.json which affects all projects globally, not just this one. Part 2 of 2 — see Spec 088 for template changes.

## Steps
- [x] Step 1: Remove duplicate "English-only / no umlauts" rule from MEMORY.md User Preferences (already in project CLAUDE.md)
- [x] Step 2: Collapse MEMORY.md Critical Safety Rules to 1-line pointer: "Hook safety: see hook-safety-rules.md"
- [x] Step 3: Check `ls -la ~/.claude/skills/brainstorming ~/.claude/skills/write-as-denis` — if symlinks, use `unlink`; if directories, use `mv` — archive both to `~/.claude/skills/_archived/`
- [x] Step 4: Remove context7 server entry from `/Users/deniskern/Sites/npx-ai-setup/.mcp.json` (already active via plugin registration)
- [ ] Step 5: Add `BASH_MAX_OUTPUT_LENGTH: "20000"` to `~/.claude/settings.json` env block (global — affects all projects)
- [ ] Step 6: Add `MAX_MCP_OUTPUT_TOKENS: "10000"` to `~/.claude/settings.json` env block (global — currently only project-level)
- [ ] Step 7: Verify — confirm context7 still resolves via `claude mcp list`, confirm archived skills no longer appear in skill menu on next session

## Acceptance Criteria
- [ ] MEMORY.md User Preferences and Critical Safety Rules sections condensed (no duplicates)
- [ ] `brainstorming` and `write-as-denis` absent from `~/.claude/skills/` (in `_archived/`)
- [ ] context7 not duplicated in .mcp.json
- [ ] `BASH_MAX_OUTPUT_LENGTH` and `MAX_MCP_OUTPUT_TOKENS` in `~/.claude/settings.json` env block

## Files to Modify
- `~/.claude/projects/-Users-deniskern-Sites-npx-ai-setup/memory/MEMORY.md` — remove duplicate rules
- `~/.claude/skills/brainstorming/`, `~/.claude/skills/write-as-denis/` — archive (check symlink first)
- `/Users/deniskern/Sites/npx-ai-setup/.mcp.json` — remove context7 entry
- `~/.claude/settings.json` — add global env vars (affects all projects)

## Out of Scope
- Template changes (Spec 088)
- claude.ai workspace MCP cleanup (Playwright, Notion, Storyblok — manual UI action)
- Model routing enforcement (behavioral, no config needed)
