# CLAUDE.md

## Purpose

**npx-ai-setup** bootstrappt Claude Code in **Target-Projekten** (fremde Repos), nicht in sich selbst.
Entry: `npx github:onedot-digital-crew/npx-ai-setup` → detect stack → install templates, skills, hooks, context into the target repo's `.claude/` and `.agents/`.

Bei Feature-Entscheidungen immer fragen: **"Bringt das dem Zielprojekt was?"** — nicht diesem Repo.
Dieses Repo selbst ist Bash-CLI; Zielprojekte können beliebiger Stack sein.

### Zielgruppe & Primary Stacks
Interne ONEDOT/Alpensattel-Projekte unter `~/Sites/`. Häufigste Stacks (in Reihenfolge):
1. **Nuxt/Vue 3** (nuxt-*, sb-nuxt-*) — Storyblok-driven, Tailwind
2. **Shopify Themes** (sp-*) — Liquid, Vite, TS-bundle
3. **Laravel/PHP** (crewbuddy, laravel-overhub)
4. **MCP-Server** (mcp-*) — Node/TS
5. **Next/SaaS** (horizon, onedot-seomachine)
6. **N8N workflows** (n8n-*)

Features müssen für mindestens einen Primary Stack nützlich sein. Generische Dev-Tools (linter, test runner, graph builder) immer via Stack-Detection gated einschalten.

### Design-Prinzipien
- **Tokens > Vollständigkeit**: jedes Template/Skill muss Token sparen oder Qualität messbar heben.
- **Opt-in statt Default**: schwere Tools (Python-deps, LLM-calls, MCP-server) als Prompt/Flag, nie silent install.
- **Idempotent**: mehrfaches `npx ai-setup` darf nichts kaputt machen, `--patch` für Updates.
- **Zero build in diesem Repo**: pure bash, POSIX-kompatibel wo möglich.
- **Host-Tools global, nicht pro Projekt**: Python/qmd/graphify einmal auf Dev-Machine, Skill ruft Binary.

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
