---
id: "087"
title: "Token Optimization: Config and Template Cleanup"
status: in-progress
---

## Goal

Reduce per-session token overhead by ~2.100 tokens through targeted cleanup of redundant config, rules, and skill descriptions — applied both locally and to templates so all new projects benefit.

## Context

Token audit identified controllable tokens wasted per session:
- `update-check.sh` runs on both SessionStart AND UserPromptSubmit (double-spawn)
- `.claudeignore` missing — no explicit protection against scanning build dirs
- `git.md` Safety Rules duplicate the built-in system prompt (~100 tokens)
- `CLAUDE.md` carries ~350 tokens of meta-prose without behavioral effect
- `spec` skill duplicates `spec-create` exactly (~26 tokens, `/spec` command unaffected)
- Rules files load unconditionally — `paths:` scoping can limit them to relevant file contexts (~820 tokens)
- `general.md` duplicates subagent routing table from `agents.md` (~80 tokens)
- `write-as-denis` description has 9-phrase trigger enumeration that belongs in the body (~80 tokens)
- MCP responses uncapped — `MAX_MCP_OUTPUT_TOKENS` missing, large Storyblok/Vercel payloads can flood context
- `brainstorming` skill has over-aggressive trigger ("MUST use before any creative work") — triggers unnecessarily and loads 96-line body into context
- `firecrawl` + `mcp-builder` descriptions verbose (>200 chars) with redundant examples in description that belong in body

All fixes must be applied in both local `.claude/` and `templates/`.

## Steps

1. [x] **Remove update-check from SessionStart** — edit `.claude/settings.json` and `templates/claude/settings.json`: remove the `update-check.sh` entry from the `SessionStart` hook array. Keep it in `UserPromptSubmit`.

2. **Add `.claudeignore`** — create `.claudeignore` locally and `templates/.claudeignore` with: `node_modules/`, `dist/`, `.ai-setup-backup/`

3. **Trim `git.md` Safety Rules** — in `.claude/rules/git.md` and `templates/claude/rules/git.md`: remove the "Safety Rules" section (never force-push, --no-verify, --no-gpg-sign, reset --hard) — these duplicate the system prompt verbatim.

4. **Trim `general.md` routing duplicate** — in `.claude/rules/general.md` and `templates/claude/rules/general.md`: remove the "Subagent Model Routing" section (already in `agents.md`).

5. **Trim `CLAUDE.md` meta-prose + add compact guidance** — in project `CLAUDE.md` and `templates/CLAUDE.md`: remove "Prompt Cache Strategy" section, remove "Skill-First" paragraph (covered by `general.md`), collapse spec workflow steps to pointer `See specs/README.md`, remove redundant "Working Style" bullets. Add to Context Management section: `Run /compact when context reaches 80% — quality degrades beyond this threshold.`

6. **Remove `spec` skill duplicate** — delete `.claude/skills/spec/` locally and remove the `spec` entry from `SPEC_SKILLS_MAP` in `lib/setup.sh`. Keep `spec-create` and all `.claude/commands/spec.md` intact.

7. **Strengthen Haiku routing rule in `agents.md`** — mark Haiku for Explore agents as CRITICAL, add cost note (Sonnet = 12× Haiku). Move model routing table to top of file.

8. **Add `paths:` scoping to rules files** — add `paths:` frontmatter to `agents.md`, `git.md`, `testing.md` (local + templates) so they only load when relevant files are in context.

9. **Add `MAX_MCP_OUTPUT_TOKENS`** — add `"MAX_MCP_OUTPUT_TOKENS": "10000"` to `env` in `templates/claude/settings.json` and local `.claude/settings.json` to cap large MCP responses.

10. **Fix `brainstorming` trigger** — in `~/.claude/skills/brainstorming/SKILL.md`: replace `"You MUST use this before any creative work"` with a precise trigger (`Use when user explicitly asks to brainstorm, explore options, or plan before implementing`). Remove "MUST" language — prevents false-positive invocations that load 96 lines unnecessarily.

11. **Trim verbose global skill descriptions** — `~/.claude/skills/defuddle/SKILL.md`, `firecrawl/SKILL.md`, `mcp-builder/SKILL.md`: move examples and bullet lists from `description:` into body. Target: ≤120 chars per description.

12. **Trim `write-as-denis` description** — in `~/.claude/skills/write-as-denis/SKILL.md`: collapse the 9-phrase trigger enumeration to 1 sentence, move examples to body.

14. **Update `/update` command to show changed files** — in `templates/commands/update.md`: after `npx github:onedot-digital-crew/npx-ai-setup` runs, display a diff summary of which files were actually added/modified.

15. **Verify** — run `git diff --stat`, check `/spec` works, run `measure.py report` to confirm savings.

## Acceptance Criteria

- `update-check.sh` appears only once per `settings.json` (UserPromptSubmit only)
- `.claudeignore` exists locally and in `templates/`
- `git.md` no longer contains a "Safety Rules" section
- `general.md` no longer contains a "Subagent Model Routing" section
- `CLAUDE.md` "Prompt Cache Strategy" section gone, spec steps collapsed to 1 pointer line
- `.claude/skills/spec/` deleted, `spec-create` + `/spec` command intact
- `agents.md` has CRITICAL marker on Haiku routing, routing table at top
- Rules files `agents.md`, `git.md`, `testing.md` have `paths:` frontmatter
- `MAX_MCP_OUTPUT_TOKENS` set in both settings files
- `brainstorming` description has no "MUST" language, trigger is precise
- `defuddle`, `firecrawl`, `mcp-builder` descriptions ≤120 chars
- `write-as-denis` description ≤150 chars
- `/update` command output lists changed files after install
- `measure.py report` shows lower token count vs pre-spec baseline

## Files to Modify

- `.claude/settings.json` + `templates/claude/settings.json`
- `.claudeignore` (new) + `templates/.claudeignore` (new)
- `.claude/rules/git.md` + `templates/claude/rules/git.md`
- `.claude/rules/general.md` + `templates/claude/rules/general.md`
- `.claude/rules/agents.md` + `templates/claude/rules/agents.md`
- `.claude/rules/testing.md` + `templates/claude/rules/testing.md`
- `CLAUDE.md` + `templates/CLAUDE.md`
- `.claude/skills/spec/` (delete)
- `lib/setup.sh` (SPEC_SKILLS_MAP)
- `~/.claude/skills/brainstorming/SKILL.md`
- `~/.claude/skills/defuddle/SKILL.md`
- `~/.claude/skills/firecrawl/SKILL.md`
- `~/.claude/skills/mcp-builder/SKILL.md`
- `~/.claude/skills/write-as-denis/SKILL.md`
- `templates/commands/update.md`

## Out of Scope

- MEMORY.md cleanup (session-specific, not a template)
- claude.ai integration disabling (requires account settings)
- HUD/statusline config (separate concern, tracked locally)
