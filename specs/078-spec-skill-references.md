# Spec: Reference Installed Project Skills in Spec Steps

> **Spec ID**: 078 | **Created**: 2026-03-11 | **Status**: draft | **Branch**: —

## Goal

The `spec` skill must scan all installed skills in the target project and reference matching ones in spec steps, covering both workflow skills (`/spec-validate`, `/spec-review`) and domain skills (`/shopify-liquid`, `/shopware6-best-practices`, `/vitest`, etc.).

## Context

`npx-ai-setup` installs domain-specific skills per detected stack (Shopify, Shopware, Tailwind, Vitest, etc.). When a spec is created in such a project, the step descriptions should use these skills directly instead of reinventing their functionality in prose. Currently the `spec` skill has no step requiring it to scan available skills before writing steps.

Skills live in `.claude/skills/` (each as a directory). The skill name = directory name. All installed skill names are discoverable via `ls .claude/skills/`.

## Steps

- [ ] Add step to `spec/skill.md`: before writing steps, run `ls .claude/skills/` to discover available skills
- [ ] Add rule to `spec/skill.md`: if a step's action is covered by an installed skill, write the step as `` `/skill-name` `` rather than prose description
- [ ] Add rule to `spec-work/skill.md`: if a step contains a skill reference (e.g. `` `/shopify-liquid` ``), invoke it via the `Skill` tool instead of reimplementing manually
- [ ] Update `templates/skills/spec/skill.md` with the same rules (source of truth for new installs)
- [ ] Update `templates/skills/spec-work/skill.md` with the skill-invocation rule
- [ ] Update `templates/specs/TEMPLATE.md`: add inline comment showing skill-reference step syntax
- [ ] Sync the same rules to `templates/skills/spec-create/skill.md` if it exists and differs

## Acceptance Criteria

- [ ] `spec/skill.md` contains: "Before writing steps, run `ls .claude/skills/` to list available skills"
- [ ] `spec/skill.md` contains: "If a step maps to an installed skill, reference it as `/skill-name` in the step"
- [ ] `templates/skills/spec/skill.md` mirrors these rules
- [ ] `templates/specs/TEMPLATE.md` shows an example step using a skill reference
- [ ] `spec-work/skill.md` contains: "If a step references `/skill-name`, invoke it via the Skill tool"

## Files to Modify

- `.claude/skills/spec/skill.md` — add skill-discovery step + reference rule
- `.claude/skills/spec-work/skill.md` — add skill-invocation rule for step execution
- `templates/skills/spec/skill.md` — sync (source of truth)
- `templates/skills/spec-work/skill.md` — sync
- `templates/skills/spec-create/skill.md` — sync if different
- `templates/specs/TEMPLATE.md` — add example step with skill reference

## Out of Scope

- Changing completed specs retroactively
- Adding new skills to the project
- Auto-generating steps from skill descriptions
