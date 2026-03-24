---
name: spec-create
description: Create a new spec for a task. Triggers: /spec, 'create spec for X', 'write a spec for X', 'spec out X', 'plan X as a spec'.
---

# Spec Create — Write a Structured Implementation Plan

Creates a spec file in `specs/NNN-title.md` for an approved task before coding begins.

## Process

1. **Challenge the idea** — before writing, ask:
   - What specific problem does this solve?
   - Is it in scope for this codebase?
   - What breaks if we don't build it?

2. **Clarify if needed** — ask 1-3 focused questions if the task is ambiguous. Wait for answers.

3. **Determine the next spec number** — run `ls specs/*.md | sort | tail -1` to find the highest number, increment by 1.

4. **Discover installed skills** — run `ls .claude/skills/` to see all available skills in this project. Keep this list in mind when writing steps — if a step's action is covered by an installed skill, reference it as `` `/skill-name` `` instead of describing the action in prose.

5. **Think through implementation**:
   - Which files change?
   - What's the exact change in each file?
   - Edge cases and failure modes?
   - Hidden complexity?

6. **Write the spec file** `specs/NNN-title.md` using this template:
   - Goal
   - Context
   - Steps
   - Acceptance Criteria (categories: Truths, Artifacts, and optionally Scenarios)
   - Files to Modify
   - Out of Scope

   **Scenarios (optional AC category):** Use WHEN/THEN/AND format only when behavior is user-facing
   (UI features, API endpoints, user workflows). Skip for internal changes or config-only tasks.

## Rules
- Steps must be atomic — one file or system per step
- Acceptance criteria must be verifiable without running the full app
- Keep specs under 60 lines / 8 steps — split if larger
- Status stays `draft` until the user approves and runs spec-work
