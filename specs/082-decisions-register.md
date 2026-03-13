---
**Status**: draft
**Branch**: —
**Complexity**: low
---

# Spec 082 — Decisions Register Template

## Goal

Add an append-only decisions register pattern so architectural decisions are persistently tracked across sessions instead of being lost in chat context or scattered across memory files.

## Context

Currently, architectural decisions made during spec execution or debugging sessions are only captured in claude-mem observations or chat history — both ephemeral. GSD-2 uses a structured `decisions.md` file with append-only rows that downstream tasks read at the start of planning phases. This pattern is simple (one markdown table) but solves a real problem: decision re-litigation.

**Dependency:** Specs 081, 083, 084, 085 also modify `spec-work.md`. Execute in the same branch or after all conflicting specs are applied.

**Installation note:** `templates/decisions.md` at root of `templates/` is automatically picked up by `build_template_map()` (`lib/core.sh:39-46`) and installed idempotently by `_install_or_update_file()` (`lib/setup.sh:15-39`). No changes to setup scripts needed.

Relevant files: `templates/commands/spec-work.md`, `templates/commands/reflect.md`, `templates/CLAUDE.md`, `templates/skills/spec-work/SKILL.md`

## Steps

- [x] **Step 1 — Create decisions register template**
  Create `templates/decisions.md` with this content:
  ```markdown
  # Decisions Register

  <!-- Append-only. Never edit or remove existing rows.
       To reverse a decision, add a new row that supersedes it.
       Read this file at the start of any planning or research phase. -->

  | # | When | Scope | Decision | Choice | Rationale | Revisable? |
  |---|------|-------|----------|--------|-----------|------------|
  ```
  Columns:
  - **#**: Sequential ID (D001, D002...), never reused
  - **When**: Context where decided (e.g. "Spec 045", "debug session", "architecture review")
  - **Scope**: Category tag: arch, pattern, library, data, api, scope, convention
  - **Decision**: What was decided (the question)
  - **Choice**: What was chosen (the answer)
  - **Rationale**: Why this choice (one sentence)
  - **Revisable?**: No, or Yes — trigger condition

- [x] **Step 2 — Verify automatic installation**
  No changes to `lib/core.sh` or `bin/ai-setup.sh` are needed. The existing `build_template_map()` in `lib/core.sh` picks up all root-level files in `templates/` via the fallback `*) target="${rel}" ;;` case. `_install_or_update_file()` in `lib/setup.sh` handles idempotency automatically (skips if file exists and matches checksum, skips with notice if user-modified). Verify the logic holds by reading `lib/core.sh:39-46` and `lib/setup.sh:15-39`.

- [x] **Step 3 — Integrate into spec-work execution**
  In `templates/commands/spec-work.md`, add after step 10 (Execute each step):
  - "If you made an architectural, pattern, library, or convention decision during this step that downstream work should know about, append it to `decisions.md` in the project root. Not every step produces decisions — only append when a meaningful choice was made."

- [ ] **Step 4 — Integrate into reflect command**
  In `templates/commands/reflect.md`, add to the ARCHITECTURAL signals classification:
  - After detecting architectural signals, also check if `decisions.md` exists. If yes, append new architectural decisions as rows. Use the next sequential D-number.

- [ ] **Step 5 — Add read-on-planning instruction to CLAUDE.md**
  In `templates/CLAUDE.md` (root of `templates/`, NOT `templates/claude/CLAUDE.md`), in the "Project Context (read before complex tasks)" section, add a new bullet after the existing `.agents/context/` entries:
  - "- `decisions.md` — Architectural decisions register (read before planning or research, if the file exists)"

- [ ] **Step 6 — Mirror spec-work change in the spec-work skill**
  Apply the identical addition from Step 3 to `templates/skills/spec-work/SKILL.md` so the skill copy stays in sync with the command.

## Files to Modify

- `templates/decisions.md` (new)
- `templates/commands/spec-work.md`
- `templates/commands/reflect.md`
- `templates/CLAUDE.md`
- `templates/skills/spec-work/SKILL.md`

## Acceptance Criteria

- [ ] `templates/decisions.md` exists with append-only table format and column definitions
- [ ] `templates/CLAUDE.md` Project Context section references `decisions.md`
- [ ] `templates/commands/spec-work.md` prompts Claude to append decisions after each step (only when a meaningful choice was made)
- [ ] `templates/commands/reflect.md` appends architectural signals to `decisions.md` when the file exists
- [ ] `templates/skills/spec-work/SKILL.md` mirrors the spec-work.md change

## Out of Scope

- Migration of existing projects that already have a decisions.md with a different format
- Automatic backfilling of past decisions from git history or memory
- Validating decisions.md format or enforcing row structure at runtime
