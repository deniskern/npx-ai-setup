# Spec: Curated-Only Skill Installation

> **Spec ID**: 150 | **Created**: 2026-03-22 | **Status**: completed | **Branch**: —

## Goal
Remove network-based skill discovery from setup and use only the curated keyword map for installation.

## Context
The current setup runs 5 network phases per install (search, popularity fetch, Claude Haiku ranking, registry check, install). This burns 30-60s and an API call for skills we already know. The curated map in `get_keyword_skills()` covers all our stacks. Discovery stays available via the existing `/find-skills` skill for on-demand use.

### Verified Assumptions
- `get_keyword_skills()` covers all active stacks (vue, react, typescript, etc.) — Evidence: `lib/skills.sh:44-71` | Confidence: High | If Wrong: missing skills for uncurated keywords
- `/find-skills` skill exists and handles discovery — Evidence: listed in system-reminder skills | Confidence: High | If Wrong: users lose discovery entirely
- `install_skill()` is reused by both paths — Evidence: `lib/skills.sh:91` | Confidence: High | If Wrong: need separate install logic

## Steps
- [x] Step 1: Remove search/ranking block from `lib/generate.sh` (lines ~488-636): parallel `search_skills`, popularity curl, Claude Haiku ranking, cache write. Keep the `SYSTEM_SKILLS` curated install block (lines ~712-770).
- [x] Step 2: Remove `search_skills()` from `lib/skills.sh` (lines 12-40) and the retry logic. Keep `get_keyword_skills()`, `install_skill()`, `install_local_skill_template()`.
- [x] Step 3: Remove skill cache logic — `SKILL_CACHE_FILE`, `.agents/.skill-cache.json` references in `generate.sh`. Cache is no longer needed without search.
- [x] Step 4: Simplify `install_skill()` — remove the pre-install `curl` registry check (lines 106-117). Just attempt `npx skills add` directly with local fallback.
- [x] Step 5: Update CLAUDE.md Skills Discovery section to reference `/find-skills` for manual discovery.
- [x] Step 6: Run `bin/ai-setup.sh` on a test project — verify curated skills install, no search/ranking occurs.

## Acceptance Criteria
- [x] No `search_skills`, popularity fetch, or Claude Haiku call in setup flow
- [x] Curated skills install correctly from `get_keyword_skills()`
- [x] `install_skill()` has single network call (npx add), not two (curl + npx)
- [x] Setup completes in <10s for skill phase (was 30-60s)

## Files to Modify
- `lib/generate.sh` — remove search/ranking block (~150 lines)
- `lib/skills.sh` — remove `search_skills()`, simplify `install_skill()`
- `templates/CLAUDE.md` — update Skills Discovery section

## Out of Scope
- Changes to `/find-skills` skill (already exists)
- Adding new keywords to curated map (separate task)
- Removing `npx skills` CLI dependency entirely
