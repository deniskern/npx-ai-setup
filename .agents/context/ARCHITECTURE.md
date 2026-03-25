---
abstract: "CLI tool automating Claude Code setup: detects stack, copies templates, generates context, installs hooks/skills"
sections:
  - "Directory Structure: bin/ (entry), lib/ (modules), templates/ (config), .claude/ (active config), specs/"
  - "Entry Points: ai-setup.sh (project), global-setup.sh (workstation), --audit, --patch"
  - "Data Flow: detect stack → copy templates → generate context → install skills → install hooks → verify"
  - "Key Patterns: modular bash, hook-based safety, template versioning, spec-driven features, parallel agents"
---

# Architecture

## Project Type
CLI tool / npm package that automates Claude Code setup for new projects. Single-command installation of hooks, configuration, skills, and AI-curated context files.

## Directory Structure
```
bin/                 # Entry points
  ai-setup.sh       # Project setup (detects stack, copies templates, generates context)
  global-setup.sh   # Workstation setup (developer machine config)

lib/                 # Reusable bash modules
  _loader.sh        # Module sourcing system
  core.sh           # Core utilities (prompts, file ops, state management)
  process.sh        # Process handling (parallel execution, worktrees)
  detect.sh         # Tech stack detection from package.json
  setup.sh          # Setup coordination
  skills.sh         # Skill installation and curation
  plugins.sh        # Plugin discovery and installation
  json.sh           # JSON parsing
  (+ others)

templates/          # Configuration templates (copied 1:1 to projects)
  claude/          # CLAUDE.md, settings.json, WORKFLOW-GUIDE.md
  agents/          # Agent templates (12 subagent types)
  rules/           # Quality/security/git/testing rules
  commands/        # Slash commands (26 total)
  skills/          # Curated skill manifests
  github/          # GitHub workflows and Copilot instructions

.claude/            # This project's Claude Code config
  hooks/           # 13 safety/automation hooks
  skills/          # Installed skills
  commands/        # Project-specific commands
  rules/           # Quality rules
  agents/          # Agent templates
  docs/            # Internal documentation

specs/              # Feature specifications (spec-driven development)
  completed/       # Finished specs
  brainstorms/     # Early-stage ideas

tests/              # Test suite
  smoke.sh         # Basic functionality tests

.agents/context/    # Generated context (this directory)
  STACK.md         # Tech stack summary
  ARCHITECTURE.md  # This file
  CONVENTIONS.md   # Coding standards
```

## Entry Points
1. **ai-setup.sh** — Installs per-project configuration (run once per project)
2. **global-setup.sh** — Installs workstation tools (run once per developer)
3. **bin/ai-setup.sh --audit** — Validates existing installation
4. **bin/ai-setup.sh --patch <pattern>** — Partial re-installation

## Data Flow
1. **Detection:** Read package.json to infer stack (react, vue, typescript, tailwind, etc.)
2. **Template Copy:** Copy templates/ contents to target project (.claude/, .github/, etc.)
3. **Context Generation:** Generate STACK.md, ARCHITECTURE.md, CONVENTIONS.md based on detected stack
4. **Skill Installation:** Install curated skills matched to detected frameworks
5. **Hook Installation:** Install 13 safety/automation hooks into git config
6. **Verification:** Run tests to confirm installation

## Directory Ownership
- **templates/** — end-user config (copied to projects); no dev/debug tooling
- **.claude/** — maintainer/dev tools (metrics, debugging, hooks for this repo only)
- **lib/skills.sh** — generic skills only; stack-specific skills belong in boilerplate repos (lib/boilerplate.sh) or via `/find-skills` on demand

## Key Patterns
- **Modular bash:** Functions in lib/ modules, sourced via source_lib
- **Hook-based safety:** Git hooks enforce security (pre-commit, post-commit)
- **Template versioning:** All templates checked into git, versioned with package
- **Spec-driven features:** Multi-file changes go through specs/NNN-title.md
- **Parallel execution:** Multi-spec work uses worktrees and parallel agents
- **Valid hook types:** SubagentStart and SubagentStop are confirmed valid Claude Code hook types
