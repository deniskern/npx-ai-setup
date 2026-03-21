# Spec: Update & Merge Strategy for Boilerplate-Based Projects

> **Spec ID**: 115 | **Created**: 2026-03-21 | **Status**: draft | **Branch**: —

## Goal
Define and implement how ai-setup handles updates in projects that already have a configured `.claude/` directory — either from a boilerplate or a previous ai-setup run. No files should be silently overwritten; user changes must be preserved.

## Context
Projects are typically created from boilerplate repos (sp-shopify-boilerplate, sb-nuxt-boilerplate, etc.) that already contain a full `.claude/` setup with system-specific skills, rules, agents, and settings. When `npx @onedot/ai-setup` runs in these projects (for updates), it must merge rather than overwrite. The current `_install_or_update_file()` uses checksum comparison but doesn't handle all edge cases. Long-term, system-specific code in ai-setup should become optional since boilerplates provide it.

## Open Questions (to resolve before implementation)
1. Should `--system` flag be deprecated or kept as fallback for non-boilerplate projects?
2. Should ai-setup detect boilerplate origin (e.g. via `.ai-setup.json` or git remote)?
3. How should settings.json merge work — deep merge, or section-by-section?
4. Should system-specific skills from ai-setup be removed entirely (boilerplate provides them)?
5. What happens when ai-setup adds a new command that the boilerplate doesn't have yet?

## Acceptance Criteria
- [ ] Running `npx @onedot/ai-setup` in a boilerplate-based project preserves all user/boilerplate modifications
- [ ] New files from ai-setup updates are added without conflict
- [ ] Updated template files are offered as diff, not silently applied
- [ ] Strategy is documented in WORKFLOW-GUIDE.md

## Out of Scope
- Two-mode architecture (rejected, was Spec 077)
- Auto-pull from boilerplate repos (future feature)
- Remote system plugin discovery

## Complexity: high
