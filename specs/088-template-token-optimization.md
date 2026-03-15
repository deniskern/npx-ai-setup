# Spec: Template Token Optimization

> **Spec ID**: 088 | **Created**: 2026-03-15 | **Status**: in-progress | **Branch**: —

## Goal
Reduce per-session token overhead in ai-setup templates by ~400 tokens through env defaults, agents.md dispatch table extraction, and CLAUDE.md trimming.

## Context
Token optimizer audit identified three concrete template improvements: BASH_MAX_OUTPUT_LENGTH missing (allows bash output spikes), agents.md dispatch table loads every message but is only consulted during agent delegation (~300 tokens wasted), and CLAUDE.md Context Management block is verbose (~80 tokens). Note: paths: scoping was rejected — ["**"] saves nothing, and tighter scoping risks hiding the model routing table during non-code sessions. Part 1 of 2 — see Spec 089 for personal config changes.

## Steps
- [x] Step 1: Add `BASH_MAX_OUTPUT_LENGTH: "20000"` to `templates/claude/settings.json` env block
- [x] Step 2: Create `templates/claude/docs/agent-dispatch.md` with the 9-row dispatch table from `templates/claude/rules/agents.md`
- [ ] Step 3: Replace the 9-row table in `templates/claude/rules/agents.md` with a 3-line stub pointing to `.claude/docs/agent-dispatch.md`; keep model cost table (Haiku/Sonnet/Opus rows)
- [ ] Step 4: Mirror Step 1 to `.claude/settings.json` (project-local); mirror Steps 2-3 to `.claude/rules/agents.md` and create `.claude/docs/agent-dispatch.md`
- [ ] Step 5: Trim `templates/CLAUDE.md` Context Management section from 9 to 3 lines — run at session START per CONVENTIONS.md rule ("editing CLAUDE.md mid-session breaks prompt cache")
- [ ] Step 6: Run `bash tests/smoke.sh` — verify all checks pass

## Acceptance Criteria
- [ ] `BASH_MAX_OUTPUT_LENGTH: "20000"` present in template settings.json env block
- [ ] `templates/claude/docs/agent-dispatch.md` exists with the full dispatch table
- [ ] `templates/claude/rules/agents.md` has stub replacing the 9-row table
- [ ] Template CLAUDE.md Context Management section is 3 lines or fewer
- [ ] Smoke tests pass

## Files to Modify
- `templates/claude/settings.json` — add BASH_MAX_OUTPUT_LENGTH
- `templates/claude/rules/agents.md` — replace dispatch table with stub
- `templates/claude/docs/agent-dispatch.md` — new file with extracted table
- `templates/CLAUDE.md` — trim Context Management (session start only)
- `.claude/settings.json` — mirror BASH_MAX_OUTPUT_LENGTH
- `.claude/rules/agents.md` — mirror stub replacement
- `.claude/docs/agent-dispatch.md` — new file (local mirror)

## Out of Scope
- paths: frontmatter on rules files (["**"] saves nothing; tighter scope risks breaking model routing)
- Personal ~/.claude/ config changes (Spec 089)
- MCP server cleanup (manual via claude.ai UI)
