---
**Status**: in-review
**Branch**: —
**Complexity**: low
---

# Spec 085 — Context Budget Awareness Rule

## Goal

Add a rule that instructs Claude to prioritize writing handoff documentation when context is running low, instead of squeezing in one more implementation step that may be lost to compaction.

## Context

When Claude's context fills up, the PreCompact hook auto-commits unsaved changes — but there's no instruction to prioritize writing a structured handoff. Currently, Claude keeps implementing until compaction happens, losing mental state and partial progress. GSD-2 explicitly instructs: "If you've used most of your context and haven't finished, stop implementing and prioritize writing the summary. A partial summary that enables clean resumption is more valuable than one more half-finished step."

This costs ~50 tokens as a rule addition but prevents the expensive re-orientation that happens after compaction without handoff notes.

**Dependency:** Spec 081 adds a step to `spec-work.md` and renumbers subsequent steps. Execute 081 first, or apply all spec-work.md changes in the same branch. The "Execute each step" section is currently step 10 — step 11 after 081 runs.

**Note:** `templates/CLAUDE.md` (not `templates/claude/CLAUDE.md`) already contains a "Context Management" section mentioning compaction and HANDOFF.md. This spec adds the context budget rule as an additional paragraph to that existing section — it does not replace or duplicate existing content.

Relevant files: `templates/CLAUDE.md`, `templates/commands/spec-work.md`

## Steps

- [x] **Step 1 — Add context budget rule to CLAUDE.md**
  In `templates/CLAUDE.md` (root of templates/, NOT templates/claude/), in the "Context Management" section (the one that mentions compaction and HANDOFF.md), add this rule after the existing bullets:
  ```markdown
  **Context budget:** When context is running low (you receive a compaction warning, or you sense the conversation is very long):
  - Stop implementing new steps
  - Prioritize writing a handoff: commit current work, update the spec with progress, or write HANDOFF.md
  - A partial handoff that enables clean resumption is more valuable than one more half-finished step
  - Never sacrifice handoff quality for one more implementation step
  ```

- [x] **Step 2 — Add context budget note to spec-work.md**
  In `templates/commands/spec-work.md`, find the **"Execute each step"** section (currently step 10, step 11 after Spec 081 runs). Add a note at the end of that step's bullet list:
  ```markdown
  **Context budget:** If you've been working for many steps and context is growing large, prioritize completing the current step fully (including its commit) over starting the next step. If compaction seems imminent, update the spec with progress markers (`[x]` for completed steps) before continuing — this ensures the next session can resume cleanly.
  ```

## Files to Modify

- `templates/CLAUDE.md`
- `templates/commands/spec-work.md`
- `templates/skills/spec-work/SKILL.md` (mirror Step 2)

## Acceptance Criteria

- [x] `templates/CLAUDE.md` Context Management section contains the context budget rule as a new paragraph (not replacing existing content)
- [x] `templates/commands/spec-work.md` has a context budget note at the end of the Execute each step bullet list
- [x] `templates/skills/spec-work/SKILL.md` mirrors the spec-work.md change
- [x] Both additions use directive language ("Stop", "Prioritize"), not suggestive language
- [x] The CLAUDE.md addition does not overlap with the existing "Before compaction: Commit current work or save state to HANDOFF.md" bullet — it adds the "when to start" trigger, not the "what to do" instruction

## Out of Scope

- Changes to `context-monitor.sh` or the PreCompact hook — they handle the technical side; this spec adds the LLM instruction side
- Adding context budget rules to other commands (bug.md, analyze.md)
