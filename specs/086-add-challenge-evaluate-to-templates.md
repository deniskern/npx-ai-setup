---
**Status**: draft
**Branch**: —
**Complexity**: low
---

# Spec 086 — Add challenge and evaluate commands to templates

## Goal

Add generalized versions of `/challenge` and `/evaluate` to `templates/commands/` so every project installed via npx-ai-setup gets them — not just this repo.

## Context

`challenge.md` and `evaluate.md` currently live only in `.claude/commands/` (project-local for the npx-ai-setup repo itself) and are NOT in `templates/commands/`. This means projects installed via `npx @onedot/ai-setup` never receive these commands.

Both files need small generalizations before they can be distributed:
- `challenge.md` Phase 2 hardcodes `"one command, zero config, template-based"` as the project's core principles — must be replaced with a generic instruction to read `.agents/context/CONCEPT.md` for project-specific principles
- `evaluate.md` says `"against the existing npx-ai-setup template inventory"` — must be replaced with `"against the existing project's patterns, templates, and installed setup"`

## Steps

- [x] **Step 1 — Create templates/commands/challenge.md**
  Copy `.claude/commands/challenge.md` to `templates/commands/challenge.md` and generalize Phase 2:
  - Replace the hardcoded `"one command, zero config, template-based"` principle text with: `"the project's core principles as defined in .agents/context/CONCEPT.md"`. If `CONCEPT.md` does not exist, skip the concept fit check.
  - Keep all other phases (1, 3–7) identical to the source file.

- [ ] **Step 2 — Create templates/commands/evaluate.md**
  First read `.claude/commands/evaluate.md` in full. Then copy to `templates/commands/evaluate.md` with these specific changes:

  **Line 8 description**: Replace `"against the existing npx-ai-setup template inventory"` with `"against the existing project's Claude Code setup"`.

  **Phase 2 inventory scan (lines 37-41)**: Replace the hardcoded `templates/` glob patterns with adaptive logic that checks whichever directories exist:
  ```
  Scan whichever of these directories exist in the current project:
  1. `.claude/commands/` or `templates/commands/` — list all .md filenames
  2. `.claude/agents/` or `templates/agents/` — list all .md filenames
  3. `.claude/rules/` or `templates/claude/rules/` — list all .md filenames
  4. `.claude/hooks/` or `templates/claude/hooks/` — list all .sh filenames
  5. `.claude/settings.json` or `templates/claude/settings.json` — note hook types
  6. `.claude/commands/` (project-local) — list all filenames
  ```

  **Phase 3a grep target**: Replace `"search the templates/ directory"` with `"search .claude/ and templates/ directories (whichever exist)"`.

  **Example paths in findings table and adoption candidates** (lines 86-89, 122-129): Replace `templates/commands/`, `templates/agents/`, `templates/claude/` with the generic placeholder `[commands-dir]/`, `[agents-dir]/`, `[hooks-dir]/` to indicate the actual path depends on the project.

  Keep the full 6-phase evaluation process and all other content intact.

- [ ] **Step 3 — Generalize .claude/commands/challenge.md**
  Apply the same Phase 2 generalization from Step 1 to `.claude/commands/challenge.md` so the project-local copy stays in sync with the template.

- [ ] **Step 4 — Generalize .claude/commands/evaluate.md**
  Apply the same changes from Step 2 to `.claude/commands/evaluate.md` (project-local copy) so it no longer hardcodes "npx-ai-setup template inventory". This keeps the local version consistent with the distributed template.

## Files to Modify

- `templates/commands/challenge.md` (new)
- `templates/commands/evaluate.md` (new)
- `.claude/commands/challenge.md` (generalize existing)
- `.claude/commands/evaluate.md` (generalize existing)

## Acceptance Criteria

- [ ] `templates/commands/challenge.md` reads `.agents/context/CONCEPT.md` for principles; falls back gracefully if CONCEPT.md does not exist
- [ ] `templates/commands/evaluate.md` Phase 2 scans `.claude/` and `templates/` (whichever exist) instead of hardcoded `templates/` only
- [ ] `.claude/commands/challenge.md` no longer contains "one command, zero config, template-based" — replaced with CONCEPT.md reference
- [ ] `.claude/commands/evaluate.md` no longer contains "npx-ai-setup template inventory" — replaced with generic phrasing
- [ ] Both template files use the same frontmatter format (`model`, `mode`, `argument-hint`, `allowed-tools`) as existing commands in `templates/commands/`

## Out of Scope

- Creating `.claude/skills/challenge/` or `.claude/skills/evaluate/` skill copies — these are commands, not skills
- Changing the 6-phase evaluation logic or scoring rubric in evaluate.md
- Updating challenge.md's Phase 3–7 logic — only Phase 2 concept-fit check is generalized
