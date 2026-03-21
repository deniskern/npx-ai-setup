# Spec: Global Developer Workstation Setup Command

> **Spec ID**: 128 | **Created**: 2026-03-21 | **Status**: in-review | **Branch**: main

## Goal
Add a separate `npx @onedot/ai-setup-global` command that installs CLI tools, global Claude settings, and developer workstation config — independent of any project.

## Context
The existing `npx @onedot/ai-setup` is project-scoped (hooks, commands, agents, CLAUDE.md). CLI tools like rtk, defuddle, repomix, codex, gemini are global per machine and don't belong in project setup. A dedicated global command runs once per developer workstation and standardizes the team's tool stack. Tools auto-detect availability and skip gracefully when prerequisites (cargo, API keys) are missing.

## Steps
- [x] Step 1: Create `bin/global-setup.sh` — entry point with 5 phases: System Check, CLI Tools, Global Settings, Global Commands/Rules, API Keys Check
- [x] Step 2: Create `lib/cli-tools.sh` — tool registry with auto-detect + install logic. Registry format: `name:pm:package:tier:description`. Required tools: rtk, defuddle, repomix. Optional: codex (needs OPENAI_API_KEY), gemini (needs GEMINI_API_KEY), agent-browser (needs cargo)
- [x] Step 3: Create `lib/global-settings.sh` — installs `~/.claude/settings.json` (global permissions for rtk, git, npm), `~/.claude/commands/` (global commands like commit, pr), `~/.claude/rules/` (general.md, git.md), statusline config
- [x] Step 4: Add API key check phase — reads ANTHROPIC_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY from env, reports status, suggests adding to `~/.zshrc`
- [x] Step 5: Register `global-setup` as separate npm bin entry in `package.json` so `npx @onedot/ai-setup-global` works
- [x] Step 6: Add `--check` mode that only reports status without installing (dry-run for auditing team setups)

## Acceptance Criteria
- [x] `npx @onedot/ai-setup-global` runs independently from project setup
- [x] CLI tools install via correct package manager (npm/cargo) with graceful fallback
- [x] Optional tools skip silently when API keys are missing (no errors)
- [x] `--check` mode reports installed/missing tools without modifying anything
- [x] Idempotent — running twice doesn't break or duplicate anything

## Files to Modify
- `bin/global-setup.sh` — new entry point
- `lib/cli-tools.sh` — new tool registry + install logic
- `lib/global-settings.sh` — new global config installer
- `package.json` — add `ai-setup-global` bin entry

## Out of Scope
- Project-specific setup (existing `bin/ai-setup.sh`)
- MCP server installation (project-scoped)
- Skills installation (stack-dependent, project-scoped)
