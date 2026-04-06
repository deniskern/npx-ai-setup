# Spec: Skill Frontmatter Normalization

> **Spec ID**: 627 | **Created**: 2026-04-06 | **Status**: in-review | **Complexity**: medium | **Branch**: main

## Goal
Normalize all 30 skill template frontmatter fields to match Claude Code docs best practices.

## Context
External audit + docs review revealed: `name:` uses non-standard `ais:` prefix, `description:` is overloaded with Triggers-lists, `effort:`/`disable-model-invocation:`/`argument-hint:` are missing on most skills. All changes are frontmatter-only -- zero install logic changes needed.

### Verified Assumptions
- `name:` should follow Claude Code frontmatter conventions even if this repo's install system currently keys skill identity from directory names, not frontmatter -- Evidence: Claude Code docs "lowercase, numbers, hyphens only"; `lib/setup.sh:657-664` installs from directory names | Confidence: High | If Wrong: normalization is cosmetic only
- `effort:` field is supported in current Claude Code -- Evidence: docs frontmatter reference | Confidence: High | If Wrong: field silently ignored
- `disable-model-invocation:` should only be added to explicitly user-invoked, side-effecting orchestration skills in this pass -- Evidence: current templates show mixed skill types (`update` already uses it; analysis/debug/spec skills still require rich model reasoning) | Confidence: Medium | If Wrong: some added flags may reduce useful auto-invocation and should be reverted

## Steps
- [ ] Step 1: Remove `ais:` prefix from all `name:` fields across `templates/skills/*/SKILL.template.md` -- use kebab-case only
- [ ] Step 2: Trim `description:` to max 220 chars per skill -- remove "Triggers:" lists, front-load natural use-case phrases
- [ ] Step 3: Add `effort:` field -- `high` for spec/research/challenge/analyze/debug, `low` for explore/doctor/scan/spec-validate
- [ ] Step 4: Add `disable-model-invocation: true` for explicitly user-invoked side-effecting orchestration skills: `commit`, `pause`, `reflect`, `release`, `spec-run`, `spec-run-all`, `spec-work-all`
- [ ] Step 5: Add `argument-hint:` to all skills that parse or branch on `$ARGUMENTS`: `build-fix`, `challenge`, `context-load`, `debug`, `lint`, `research`, `spec`, `spec-review`, `spec-run`, `spec-validate`, `spec-work`
- [ ] Step 6: Regenerate installed `.claude/skills/*/SKILL.md` from updated templates (run install_skills or /update)

## Acceptance Criteria
- [ ] `grep -r "ais:" templates/skills/*/SKILL.template.md` returns zero matches
- [ ] No `description:` field exceeds 220 characters
- [ ] All targeted skills in Step 3 have the intended `effort:` value (`high` or `low`) in frontmatter
- [ ] All side-effect skills have `disable-model-invocation: true`
- [ ] All skills listed in Step 5 that use `$ARGUMENTS` have a non-empty `argument-hint:`
- [ ] After regeneration, installed `.claude/skills/*/SKILL.md` copies reflect the updated frontmatter without manual edits
- [ ] `/update` installs updated skills without error

## Files to Modify
- `templates/skills/*/SKILL.template.md` (all 30 files) -- frontmatter only

## Out of Scope
- Supporting files / Progressive Disclosure (see Spec 628)
- Install logic changes
- Skill content/body changes
