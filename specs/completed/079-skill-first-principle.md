# Spec: Skill-First Principle — Always Use Installed Skills

> **Spec ID**: 079 | **Created**: 2026-03-11 | **Status**: completed | **Branch**: —

## Goal

Claude must check installed skills before implementing anything manually. If an installed skill covers the task, it must be used — not reimplemented in prose or code.

## Context

Projects receive domain-specific skills at setup (shopify-liquid, shopware6-best-practices, vitest, tailwind, etc.). Currently nothing in the rules or CLAUDE.md template instructs Claude to discover and prefer these skills. As a result, Claude regularly reimplements what skills already do — lowering quality and consistency.

This principle must be enforced at three layers:
1. **Rules** — general.md (applies to all Claude interactions in a project)
2. **CLAUDE.md template** — baked in for every new project install
3. **Agent definitions** — so delegated agents also follow the rule

## Steps

- [x] Add rule to `templates/claude/rules/general.md`: "Before implementing, run `ls .claude/skills/` and use any matching skill via the Skill tool"
- [x] Sync same rule to `.claude/rules/general.md` (active project copy)
- [x] Add "Skill-First" section to `templates/CLAUDE.md` under Working Style
- [x] Add skill-discovery reminder to `templates/agents/code-reviewer.md` and `verify-app.md`
- [x] Verify: read updated `general.md` and confirm rule is present and clear

## Acceptance Criteria

- [x] `templates/claude/rules/general.md` contains the skill-first rule
- [x] `.claude/rules/general.md` (active) contains the same rule
- [x] `templates/CLAUDE.md` documents skill-first under Working Style
- [x] Rule is unambiguous: scan → match → invoke via Skill tool, never reimplement

## Files to Modify

- `templates/claude/rules/general.md` — add skill-first rule (source of truth)
- `.claude/rules/general.md` — sync active copy
- `templates/CLAUDE.md` — add Working Style entry

## Out of Scope

- Changing agent model routing rules
- Modifying individual skill files (covered by spec 078)
- Retroactive changes to completed specs
