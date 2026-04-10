# CLAUDE.md

## Project Context (tiered loading)
SessionStart injects L0 abstracts from `.agents/context/` (~400 tokens).
For full details: `/context-load STACK.md` (or ARCHITECTURE.md, CONVENTIONS.md, all).

## CLI Shortcuts (zero tokens)
- CI status: `! bash .claude/scripts/ci-prep.sh`
- Lint check: `! bash .claude/scripts/lint-prep.sh`
- Test check: `! bash .claude/scripts/test-prep.sh`
- Health check: `! bash .claude/scripts/doctor.sh`
- Quality gate (bash -n + shellcheck + smoke): `! bash .claude/scripts/quality-gate.sh`

Use the skill (`/test`, `/lint`) only when you need Claude to analyze failures or auto-fix.

## Skill Shell Execution

Do NOT set `disableSkillShellExecution: true` in settings.json for this project.
Skills `doctor`, `spec-board`, `review`, `ci`, `test-setup`, and `session-optimize` use `!` inline shell execution.

## Build Artifact Rules

Never read or search inside: `dist/`, `.output/`, `.nuxt/`, `.next/`, `build/`, `coverage/`.
Hard blocks via `permissions.deny` in `.claude/settings.json`.

## Automation (Agent SDK CLI)
Non-interactive: `claude -p "<prompt>" --output-format json`. CI: add `--bare` (disables Hooks/Skills/MCP).
Cost controls: `--max-budget-usd 0.50` / `--max-turns 20`.

## Model Routing
Haiku: explore agents and direct tool use only. Sonnet: implementation subagents (default).

## RTK
Always prefix commands with `rtk`. Full reference: `.claude/docs/rtk-reference.md`.
