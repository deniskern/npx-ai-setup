---
name: spec-work
description: Execute a spec step by step. Use when the user says `/spec-work NNN`, "work on spec NNN", "execute spec NNN", "implement spec NNN", or "run spec NNN". NNN is a 3-digit spec number.
---

# Spec Work — Execute a Spec Step by Step

Executes a spec from `specs/NNN-*.md` step by step, commits after each step, and verifies the result.

## Process

1. **Find the spec**: If given a number (e.g. `074`), open `specs/074-*.md`. If a filename, open directly.

2. **Read the spec** — understand Goal, Steps, Acceptance Criteria, Files to Modify.

3. **Validation gate** (skip if `--skip-validate` flag is set or spec status is `in-progress`):
   Score the spec on these 10 criteria — Goal clarity, Step decomposition, Dependency identification, Coverage completeness, Acceptance criteria quality, Scope coherence, Risk and blockers, File coverage, Out of scope clarity, Integration awareness.
   - If any criterion has a critical gap: show the specific issues and **STOP**. Tell the user: "Fix these issues first, then re-run `/spec-work NNN`. Use `/spec-validate NNN` for details."
   - If all criteria pass: continue to step 4.

4. **Understanding confirmation** (high-complexity specs only): Check if the spec header contains `**Complexity**: high`. If yes:
   - Show a 3-bullet summary:
     - **Goal**: [one sentence from the spec Goal section]
     - **Approach**: [main implementation strategy inferred from the Steps]
     - **Files**: [comma-separated list from the Files to Modify section]
   - Ask via AskUserQuestion: "Does this match your expectations before I create the branch and start work?"
     Options: [Yes, proceed] [No, clarify first]
   - If user selects "No, clarify first": stop, ask an open-ended follow-up question to understand the correction, and do not proceed.

5. **Read project context**: Skim `.agents/context/CONVENTIONS.md` and `.agents/context/STACK.md`.

6. **Update status**: Set `**Status**: in-progress` in the spec header.

7. **Print a progress checklist** of all steps before starting:
   ```
   Progress — Spec NNN
   [ ] Step 1: <title>
   [ ] Step 2: <title>
   ```

8. **Resume check**: Scan for already-checked steps (`- [x]`). If found, skip them and continue from the first unchecked step.

8a. **Model routing by complexity** (before step 9): Read the `**Complexity**` field from the spec header:
    - If `**Complexity**: low` — execute step 9 directly (no subagent — overhead not justified for simple tasks)
    - If `**Complexity**: medium` or unset/missing — spawn subagent with `model: sonnet` for step 9 (default); pass spec content and remaining unchecked steps as context
    - If `**Complexity**: high` — spawn subagent with `model: opus` for step 9; pass spec content and remaining unchecked steps as context

9. **Execute each step** in order:
   - Implement the change
   - Check it off in the spec: `- [ ]` → `- [x]`
   - Commit: `git add -A && git commit -m "spec(NNN): step N — <title>"`
   - If blocked, stop and ask

10. **Verify acceptance criteria** — check each one off in the spec.

11. **Update CHANGELOG.md** — add entry under `## [Unreleased]`:
    `- **Spec NNN**: [title] — [one-sentence summary]`

12. **Run tests/build** if available (`bash tests/smoke.sh` or equivalent). Report PASS or FAIL.

13. **Set status to `completed`**, move file: `specs/NNN-*.md` → `specs/completed/NNN-*.md`.

## Rules
- Commit after every step — enables crash resilience
- Never skip the status update and file move at the end
- If a step fails, set status to `blocked` and stop
- If called with `--skip-validate` flag, skip step 3 (validation gate). Use for already-validated or resuming in-progress specs.
- **Skill-First**: If a step contains a skill reference (e.g. `` `/shopify-liquid` ``, `` `/vitest` ``), invoke it via the `Skill` tool instead of reimplementing the action manually
