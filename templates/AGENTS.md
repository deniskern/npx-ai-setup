# AGENTS.md

## Purpose
Universal passive context for AGENTS.md-compatible tools (Cursor, Windsurf, Cline, and others).
Read this file before making multi-file edits, architectural changes, or release-impacting updates.

## Project Overview
<!-- Auto-Init populates this -->

## Project Context
For detailed project context, read:
- `.agents/context/STACK.md` - runtime, frameworks, key dependencies, and toolchain
- `.agents/context/ARCHITECTURE.md` - structure, entry points, boundaries, and data flow
- `.agents/context/CONVENTIONS.md` - coding conventions, testing patterns, and Definition of Done

If these files are missing or stale, regenerate with:
`npx @onedot/ai-setup --regenerate`

## Architecture Summary
<!-- Auto-Init populates this -->

## Commands

Primary project commands come from `package.json` scripts. Spec workflow skills are shared across tools via `.claude/skills/` (symlinked to `.codex/skills`, `.gemini/agents`, `.opencode/skills`).

### Spec Workflow

| Skill | Purpose |
|-------|---------|
| spec-create | Create a structured implementation plan |
| spec-work | Execute a spec step by step |
| spec-board | Show Kanban overview of all specs |
| spec-review | Review completed spec against acceptance criteria |
| spec-validate | Validate draft spec before execution |
| spec-work-all | Execute all draft specs in parallel waves |

### How to invoke per tool

- **Claude Code**: `/spec`, `/spec-work NNN`, `/spec-board` (native slash commands)
- **Codex**: `$spec`, `$spec-work NNN`, `$spec-board` (dollar-prefix skills)
- **Gemini**: Natural language — "create a spec for X", "work on spec NNN", "show spec board"
- **Other tools** (Cursor, Windsurf, Cline): Read the SKILL.md files in `.claude/skills/` and follow their instructions

### Multi-Agent Delegation (Claude Code only)

Delegate tasks to Gemini or Codex CLI from within Claude Code:
- `"use gemini to research X"` — sends prompt to Gemini CLI, returns result
- `"use codex to write tests for X"` — sends prompt to Codex CLI, returns result

Requires the respective CLI installed and API key set. Delegation is explicit only — Claude never auto-routes to other engines.

## Code Style Guidelines
- Follow existing lint and formatter config; do not introduce conflicting style rules.
- Prefer small, focused changes with clear intent and minimal side effects.
- Keep naming, folder structure, and abstraction patterns consistent with neighboring code.
- Add or update tests for behavior changes when a test framework is available.
- Avoid new dependencies unless there is a clear net benefit.

## Critical Rules
<!-- Auto-Init populates this -->

## Verification
- Run relevant lint, test, and build commands before marking work complete.
- Validate integrations affected by your changes (API calls, UI flows, background jobs).
- Summarize what was verified and the result.
