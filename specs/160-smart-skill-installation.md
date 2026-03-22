# Spec: Simplify Skill Installation — Global Only + Boilerplate

> **Spec ID**: 160 | **Created**: 2026-03-22 | **Status**: in-progress | **Complexity**: medium | **Branch**: —

## Goal
Extract skill installation into its own step, reduce to 3 global skills, remove keyword-based mapping, and clean up dead code.

## Context
Skills are embedded in `run_generation()` alongside AI context generation. 10+ system skills install universally plus keyword-mapped skills from package.json — most irrelevant (vercel-cli without Vercel, seo-audit for APIs). Boilerplate system already pulls system-specific skills from repos. Fix: install only 3 truly universal skills (agent-browser, find-skills, gh-cli), let boilerplate handle the rest, users run `/find-skills` for on-demand discovery. Also removes dead code: `FORCE_SKILLS`, `SKILL_PATTERN`, `SKIPPED`.

### Verified Assumptions
- Only agent-browser, find-skills, gh-cli are truly universal | Confidence: High | If Wrong: some projects miss a useful default
- Boilerplate system already handles system-specific skills (shopify, nuxt, etc.) | Evidence: `lib/boilerplate.sh:97-116` | Confidence: High
- `/find-skills` covers on-demand discovery for non-boilerplate projects | Evidence: installed as universal skill | Confidence: High
- `REGEN_SKILLS` toggle in TUI (`lib/tui.sh:75`) needs to wire to the new function | Confidence: High | If Wrong: update flow breaks

## Steps
- [x] Step 1: Create `run_skill_installation()` in `lib/skills.sh` — installs only 3 global skills (agent-browser, find-skills, gh-cli), parallel install, sets `INSTALLED` count. Reuse existing `install_skill()` function
- [ ] Step 2: Remove skill block from `run_generation()` (generate.sh:396-532) — remove keyword detection, SYSTEM_SKILLS array, parallel install loop, REGEN_SKILLS handling
- [ ] Step 3: Wire `run_skill_installation` as own step in `ai-setup.sh` between plugins and Auto-Init. Wire into update flow (`lib/update.sh`) where `REGEN_SKILLS=yes`
- [ ] Step 4: Update TUI (`lib/tui.sh`) — rename "Skills" option description to reflect reduced scope, keep REGEN_SKILLS toggle working with new function
- [ ] Step 5: Remove dead code — `FORCE_SKILLS` from ai-setup.sh, `SKILL_PATTERN` from skills.sh, `SKIPPED` from skills.sh/generate.sh, `get_keyword_skills()` from skills.sh
- [ ] Step 6: Add post-install hint in `run_skill_installation()` — after install output, print hint: "Run /find-skills in Claude Code to discover skills matched to your project" + 1-2 sentences why (skills matched to actual project context are more useful than generic stack-based ones)
- [ ] Step 7: Test `./bin/ai-setup.sh` on this repo — verify only 3 skills install, no keyword detection output, hint is shown

## Acceptance Criteria

### Truths
- [ ] "Running ai-setup installs exactly 3 global skills (minus already-installed)"
- [ ] "run_generation() contains zero skill-related code"
- [ ] "Grepping for FORCE_SKILLS, SKILL_PATTERN, get_keyword_skills returns no results in lib/ and bin/"

### Key Links
- [ ] `bin/ai-setup.sh` → `lib/skills.sh` via `run_skill_installation` call
- [ ] `lib/update.sh` → `lib/skills.sh` via `run_skill_installation` when REGEN_SKILLS=yes

## Files to Modify
- `lib/skills.sh` — add run_skill_installation(), remove get_keyword_skills(), SKILL_PATTERN, SKIPPED
- `lib/generate.sh` — remove lines 396-532 (entire skill block)
- `bin/ai-setup.sh` — add skill step, remove FORCE_SKILLS
- `lib/update.sh` — wire run_skill_installation for REGEN_SKILLS
- `lib/tui.sh` — update Skills description text

## Out of Scope
- LLM-based skill ranking or discovery
- Changes to boilerplate skill-pull logic
- Adding new global skills beyond the current 3
