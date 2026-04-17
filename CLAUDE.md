# CLAUDE.md

## Project Context (tiered loading)
@.agents/context/SUMMARY.md
For full details: `@.agents/context/STACK.md` (or `ARCHITECTURE.md`, `CONVENTIONS.md`).

## CLI Shortcuts (zero tokens)
- CI status: `! bash .claude/scripts/ci-prep.sh`
- Lint check: `! bash .claude/scripts/lint-prep.sh`
- Test check: `! bash .claude/scripts/test-prep.sh`
- Health check: `! bash .claude/scripts/doctor.sh`
- Quality gate (bash -n + shellcheck + smoke): `! bash .claude/scripts/quality-gate.sh`
- Debug context: `! bash .claude/scripts/debug-prep.sh`

Use the `/test` skill only when you need Claude to analyze failures or auto-fix.

## Build Artifact Rules

Never read or search inside: `dist/`, `.output/`, `.nuxt/`, `.next/`, `build/`, `coverage/`.
Hard blocks via `permissions.deny` in `.claude/settings.json`.

## Automation (Agent SDK CLI)
Non-interactive: `claude -p "<prompt>" --output-format json`. CI: add `--bare` (disables Hooks/Skills/MCP).
Cost controls: `--max-budget-usd 0.50` / `--max-turns 20`.
