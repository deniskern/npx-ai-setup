# Spec: Skill Progressive Disclosure + Install Refactor

> **Spec ID**: 628 | **Created**: 2026-04-06 | **Status**: in-review | **Complexity**: high | **Branch**: main
> **Related**: Spec 627 (frontmatter normalization) can land independently before or after this refactor

## Goal
Enable multi-file skills with supporting files, sync them through setup/update, and add a skill lint script for structural validation.

## Context
Install system (`lib/setup.sh:653`) only copies `SKILL.template.md` per skill. Skills like analyze (237L), research (189L), reflect (167L) exceed the recommended 500-line soft limit and pack everything into one file. Supporting files (`references/*.md`) need install logic changes. A lint script prevents regression.

### Verified Assumptions
- `install_skills()` uses `find -maxdepth 1 -type d` and only copies SKILL.template.md -- Evidence: `lib/setup.sh:657-664` | Confidence: High | If Wrong: supporting files may already be copied
- Claude Code loads files referenced from SKILL.md on demand -- Evidence: docs "Reference supporting files from SKILL.md" | Confidence: High | If Wrong: files must be in context at load time

## Steps
- [x] Step 1: Extend `install_skills()` in `lib/setup.sh` to copy `references/*.md` files alongside SKILL.md using `_install_or_update_file` pattern
- [x] Step 2: Extend `scan_template_changes()` in `lib/update.sh` to track checksums for `references/*.md` supporting files
- [x] Step 3: Split `templates/skills/analyze/SKILL.template.md` -- move agent-prompt detail blocks to `references/`
- [x] Step 4: Extend `cleanup_orphans()` in `lib/setup.sh` to detect and remove orphaned `references/*.md` files when template references are deleted
- [x] Step 5: Create `scripts/skill-lint.sh` to validate `templates/skills/*/SKILL.template.md` for kebab-case `name`, `description` <=220 chars, and required sections
- [x] Step 6: Add inline skill health check to `templates/scripts/doctor.sh` (5-10 lines, checks SKILL.md exists + frontmatter has name/description) and regenerate `.claude/scripts/doctor.sh`

## Acceptance Criteria
- [x] `references/*.md` files are installed to `.claude/skills/*/references/` on fresh setup
- [x] `/update` detects and syncs changed supporting files
- [x] `bash scripts/skill-lint.sh` passes on all `templates/skills/*/SKILL.template.md` files
- [x] `bash .claude/scripts/doctor.sh` includes skill health check and reports OK/FAIL
- [ ] Split analyze skill still functions correctly (manual test: `/analyze`)

## Files to Modify
- `lib/setup.sh` -- extend install_skills() glob + cleanup_orphans() for references/
- `lib/update.sh` -- extend scan_template_changes() checksums
- `templates/skills/analyze/` -- split into SKILL.md + references/
- `scripts/skill-lint.sh` -- new file (template-only scope)
- `templates/scripts/doctor.sh` -- add inline skill health check
- `.claude/scripts/doctor.sh` -- regenerated installed copy

## Out of Scope
- Skill archetype templates (workflow/knowledge/forked variants)
- CI enforcement of lint (future)
- Splitting all 30 skills (only analyze initially)
- research split (190 lines is within acceptable range)
