---
name: spec-work
description: Execute a spec step by step. Use when the user says `/spec-work NNN`, "work on spec NNN", "execute spec NNN", "implement spec NNN", or "run spec NNN". NNN is a 3-digit spec number.
---

# Spec Work — Execute a Spec Step by Step

Executes a spec from `specs/NNN-*.md` step by step, commits after each step, and verifies the result.

## Process

1. **Find the spec**: If given a number (e.g. `074`), open `specs/074-*.md`. If a filename, open directly.

2. **Read the spec** — understand Goal, Steps, Acceptance Criteria, Files to Modify.

3. **Read project context**: Skim `.agents/context/CONVENTIONS.md` and `.agents/context/STACK.md`.

4. **Update status**: Set `**Status**: in-progress` in the spec header.

5. **Print a progress checklist** of all steps before starting.

6. **Resume check**: Scan for already-checked steps (`- [x]`). If found, skip them and continue from the first unchecked step.

7. **Execute each step** in order:
   - Implement the change
   - Check it off in the spec
   - Commit with `git commit -m "spec(NNN): step N — <title>"`
   - If blocked, stop and ask
   - If you made an architectural, pattern, library, or convention decision during this step that downstream work should know about, append it to `decisions.md` in the project root. Not every step produces decisions — only append when a meaningful choice was made.
   - **Context budget:** If you've been working for many steps and context is growing large, prioritize completing the current step fully (including its commit) over starting the next step. If compaction seems imminent, update the spec with progress markers (`[x]` for completed steps) before continuing — this ensures the next session can resume cleanly.

8. **Verify acceptance criteria** — check each one off in the spec.
   For structured criteria (Truths / Artifacts / Key Links), verify each category mechanically:
   - **Truths**: Run the described commands and confirm output matches the stated behavior.
   - **Artifacts**: Read the files and confirm real implementation is present (not stubs or placeholders).
   - **Key Links**: Verify the stated imports or references exist in the source file.

9. **Update CHANGELOG.md** — add an entry under `## [Unreleased]`.

10. **Run tests/build** if available. Report PASS or FAIL.
    - If tests/build **FAIL**, follow the debugging discipline before fixing:
      - Form a hypothesis before making any change
      - Change one variable at a time
      - After 3 failed fix attempts, stop and reassess your mental model
      - Don't fix symptoms — understand the root cause first

11. **Set status to `completed`**, move file to `specs/completed/`.

## Rules
- Commit after every step
- Never skip the status update and file move at the end
- If a step fails, set status to `blocked` and stop
- **Skill-First**: If a step contains a skill reference (e.g. `` `/shopify-liquid` ``, `` `/vitest` ``), invoke it via the `Skill` tool instead of reimplementing the action manually
