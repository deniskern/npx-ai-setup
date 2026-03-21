# Spec: Add frontend-developer Agent Template

> **Spec ID**: 123 | **Created**: 2026-03-21 | **Status**: in-review | **Complexity**: medium | **Branch**: main

## Goal

Add a `frontend-developer` agent template specialized for React/Vue/Nuxt with accessibility and performance focus.

## Context

one-dot.de builds Shopify (Liquid + JS), Vue/Nuxt, and React/Next.js projects. No existing agent covers frontend-specific concerns like WCAG compliance, Core Web Vitals, or component architecture.

## Steps

- [x] Step 1: Read existing agent templates in `templates/agents/` to understand the format and conventions
- [x] Step 2: Create `templates/agents/frontend-developer.md`
- [x] Step 3: Set model to `sonnet`, tools to Read/Write/Edit/Glob/Grep/Bash, max_turns to 20
- [x] Step 4: Read `lib/plugins.sh` and add conditional install to `lib/setup.sh`
- [x] Step 5: Mirror to `.claude/agents/frontend-developer.md`

## Acceptance Criteria

- [x] `templates/agents/frontend-developer.md` exists and follows existing format
- [x] Agent is stack-agnostic (works with React AND Vue)
- [x] Template is 30-50 lines
- [x] `lib/setup.sh` installs agent only when frontend stack detected
- [x] `.claude/agents/frontend-developer.md` mirrors the template

## Files to Modify

- `templates/agents/frontend-developer.md` — new
- `lib/setup.sh` — add conditional install for frontend stack detection
- `.claude/agents/frontend-developer.md` — mirror

## Out of Scope

- Backend API design guidance
- Database schema recommendations
- Infrastructure or DevOps concerns
