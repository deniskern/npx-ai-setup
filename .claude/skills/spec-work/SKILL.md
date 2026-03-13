---
name: spec-work
description: Execute a spec step by step. Use when the user says `/spec-work NNN`, "work on spec NNN", "execute spec NNN", "implement spec NNN", or "run spec NNN". NNN is a 3-digit spec number.
---

# Spec Work — Execute a Spec Step by Step

Executes a spec from `specs/NNN-*.md` step by step, commits after each step, and verifies the result.

## Process

1. **Find the spec**: If given a number (e.g. `074`), open `specs/074-*.md`. If a filename, open directly.

2. **Read the spec** — understand Goal, Steps, Acceptance Criteria, Files to Modify.

3. **Understanding confirmation** (high-complexity specs only): Check if the spec header contains `**Complexity**: high`. If yes:
   - Show a 3-bullet summary:
     - **Goal**: [one sentence from the spec Goal section]
     - **Approach**: [main implementation strategy inferred from the Steps]
     - **Files**: [comma-separated list from the Files to Modify section]
   - Ask via AskUserQuestion: "Does this match your expectations before I create the branch and start work?"
     Options: [Yes, proceed] [No, clarify first]
   - If user selects "No, clarify first": stop, ask an open-ended follow-up question to understand the correction, and do not proceed.

4. **Read project context**: Skim `.agents/context/CONVENTIONS.md` and `.agents/context/STACK.md`.

5. **Update status**: Set `**Status**: in-progress` in the spec header.

6. **Print a progress checklist** of all steps before starting:
   ```
   Progress — Spec NNN
   [ ] Step 1: <title>
   [ ] Step 2: <title>
   ```

7. **Resume check**: Scan for already-checked steps (`- [x]`). If found, skip them and continue from the first unchecked step.

8. **Execute each step** in order:
   - Implement the change
   - Check it off in the spec: `- [ ]` → `- [x]`
   - Commit: `git add -A && git commit -m "spec(NNN): step N — <title>"`
   - If blocked, stop and ask

9. **Verify acceptance criteria** — check each one off in the spec.

10. **Update CHANGELOG.md** — add entry under `## [Unreleased]`:
    `- **Spec NNN**: [title] — [one-sentence summary]`

11. **Run tests/build** if available (`bash tests/smoke.sh` or equivalent). Report PASS or FAIL.

12. **Set status to `completed`**, move file: `specs/NNN-*.md` → `specs/completed/NNN-*.md`.

## Rules
- Commit after every step — enables crash resilience
- Never skip the status update and file move at the end
- If a step fails, set status to `blocked` and stop
- **Skill-First**: If a step contains a skill reference (e.g. `` `/shopify-liquid` ``, `` `/vitest` ``), invoke it via the `Skill` tool instead of reimplementing the action manually
