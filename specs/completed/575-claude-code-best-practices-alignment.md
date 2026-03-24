# Spec: Claude Code Best Practices Alignment (Docs Audit)

> **Spec ID**: 575 | **Created**: 2026-03-24 | **Status**: draft | **Complexity**: low | **Branch**: —

## Goal
Implement missing best practices from the official Claude Code docs audit: subagent model enforcement, auto-compact threshold, and context management commands in templates.

## Context
A full audit of code.claude.com/docs revealed 3 actionable gaps not yet in the setup. `ENABLE_TOOL_SEARCH`, `BASH_MAX_OUTPUT_LENGTH`, and `MAX_MCP_OUTPUT_TOKENS` are already set. Remaining items require changes to global settings env vars, the CLAUDE.md template, and the explore skill frontmatter.

## Steps
- [ ] Step 1: Add `CLAUDE_CODE_SUBAGENT_MODEL=haiku` and `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE=80` to `~/.claude/settings.json` env block
- [ ] Step 2: Add `effort: low` to frontmatter of `templates/skills/explore/SKILL.md`
- [ ] Step 3: Extend `## Context Management` in `templates/CLAUDE.md` with `/rewind`, `/btw`, and `/compact Focus on <topic>` tips
- [ ] Step 4: Mirror Step 3 changes to the live project CLAUDE.md at `CLAUDE.md` (root of npx-ai-setup)

## Acceptance Criteria

### Truths
- [ ] `~/.claude/settings.json` contains `"CLAUDE_CODE_SUBAGENT_MODEL": "haiku"` and `"CLAUDE_AUTOCOMPACT_PCT_OVERRIDE": "80"`
- [ ] `templates/skills/explore/SKILL.md` frontmatter contains `effort: low`
- [ ] `templates/CLAUDE.md` Context Management section mentions `/rewind`, `/btw`, and `/compact Focus`

### Artifacts
- [ ] `~/.claude/settings.json` — updated env block
- [ ] `templates/skills/explore/SKILL.md` — updated frontmatter

## Files to Modify
- `~/.claude/settings.json` — add 2 env vars
- `templates/skills/explore/SKILL.md` — add effort: low to frontmatter
- `templates/CLAUDE.md` — extend Context Management section
- `CLAUDE.md` — mirror template changes

## Out of Scope
- `opusplan` as default model (personal preference, not in templates)
- Changes to other skill templates beyond explore
- Global CLAUDE.md at `~/.claude/CLAUDE.md`
