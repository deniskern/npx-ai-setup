# Concept: @onedot/ai-setup

## What Is This?

`@onedot/ai-setup` is a one-command scaffolding tool that gives any project a complete, production-ready AI development environment. Run it once and you have:

- A project memory system (CLAUDE.md + context files)
- Safety hooks that prevent common AI mistakes
- Curated slash commands for the development workflow
- AI-selected skills matched to your tech stack
- Built-in integrations (Context7, persistent memory, official plugins)

## The Problem

Setting up Claude Code for a new project involves many moving parts: writing CLAUDE.md, configuring permissions, installing hooks, picking skills, setting up MCP servers. Each step is documented separately, and doing it right requires understanding the full system.

Most projects skip steps or copy config from old projects without updating it. The result is AI assistants that don't know the tech stack, have overly broad permissions (`Bash(*)`), no linting hooks, and no context files.

## Who Is This For

For any developer or agency team using Claude Code — from solo freelancers
to multi-developer teams. No prior Claude Code expertise required.

The goal is an agency-grade baseline: every project starts with the same
proven setup, every developer on the team works with the same guardrails,
and no session begins with "explain this codebase to me again."

## Why One Command?

The goal is zero configuration for the consumer of the tool. A developer should be able to type one command and immediately have a working AI development environment. The setup adapts to the project automatically — it reads `package.json`, detects the tech stack, and generates context files specific to that codebase.

## What Success Looks Like

After setup, the daily workflow is spec-driven: write a structured spec,
execute it step by step, review the result. New features, optimizations,
and bug fixes all follow the same pattern.

Success means Claude understands the project from session one, doesn't
make avoidable mistakes, and the team burns tokens on actual work —
not on setup, re-explanation, or recovering from AI errors.

## Templates, Not Generation

The core scaffolding (hooks, settings, commands) is template-based, not generated. Templates are committed to this repository and copied 1:1. This is intentional:

- **Predictable**: every project gets the same battle-tested hooks
- **Reviewable**: you can read exactly what will be installed before running
- **Maintainable**: updating templates in this repo propagates via version bumps
- **Lightweight**: no LLM call needed for the deterministic parts

Generation is reserved for the parts that *must* be project-specific: CLAUDE.md Commands section, ARCHITECTURE.md, STACK.md, CONVENTIONS.md. These require understanding the actual codebase.

## Curated Skills, Not AI Discovery

Skills are installed from a maintained keyword map — not discovered at runtime. The setup detects technologies from `package.json` and installs matching skills directly (e.g. vue → vue-best-practices, typescript → typescript-advanced-types). No network search, no LLM ranking call, no popularity scraping. For on-demand discovery, users run `/find-skills` inside Claude Code.

## Hook-Based Safety

AI assistants make mistakes: editing `.env` files, getting into edit loops, breaking linting rules. Hooks solve this at the infrastructure level, not the prompt level. Prompting an AI "don't edit .env" is unreliable. A PreToolUse hook that blocks the edit entirely is reliable.

The hook system is lightweight by design — every hook must complete in under 50ms with no API calls. They run on every tool use and must not slow down the development loop.

## Project Memory, Not Session Memory

CLAUDE.md and `.agents/context/` are persistent project memory. They survive across Claude Code sessions, team members, and context resets. This is the key insight: instead of re-explaining the project to Claude every session, the context files do it automatically by being referenced in CLAUDE.md (which Claude always reads at startup).

The three context files (STACK.md, ARCHITECTURE.md, CONVENTIONS.md) give Claude instant, accurate project understanding that normally takes 10–20 minutes of manual exploration per session.
