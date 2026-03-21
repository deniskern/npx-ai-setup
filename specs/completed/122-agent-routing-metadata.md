# Spec: Add when_to_use/avoid_if to All Agent Templates

> **Spec ID**: 122 | **Created**: 2026-03-21 | **Status**: in-review | **Branch**: —

## Goal
Add `when_to_use` and `avoid_if` routing metadata to all agent template files so Claude selects the right agent for each task.

## Context
Currently agents have only a `description` field. Claude guesses which agent fits. Octopus agents include explicit `when_to_use` and `avoid_if` fields that tell the orchestrator when to (and when NOT to) spawn each agent. Adding these to our templates improves agent selection accuracy. Inspired by claude-octopus personas system.

## Steps
- [x] Step 1: Add `when_to_use` and `avoid_if` comments to `templates/agents/code-reviewer.md` — e.g. when: PR reviews, code quality, security. avoid: performance-only, architecture decisions
- [x] Step 2: Add metadata to remaining 9 template agents: build-validator, code-architect, context-refresher, liquid-linter, perf-reviewer, staff-reviewer, test-generator, verify-app, project-auditor
- [x] Step 3: Mirror changes to `.claude/agents/` (project-local copies)
- [x] Step 4: Update `.claude/rules/agents.md` to reference when_to_use/avoid_if as agent selection criteria
- [x] Step 5: Verify agent dispatch table in `.claude/docs/agent-dispatch.md` aligns with new metadata

## Acceptance Criteria
- [x] All agent templates have `when_to_use` and `avoid_if` in description/comments
- [x] Routing guidance is specific (not generic platitudes)
- [x] `.claude/agents/` mirrors templates

## Files to Modify
- `templates/agents/*.md` — all 10 agent files
- `.claude/agents/*.md` — all 9 agent files (mirror)
- `.claude/rules/agents.md` — reference new metadata

## Out of Scope
- New agents (frontend-developer, etc.) — separate specs
- Agent-level hooks (not supported by Claude Code)
