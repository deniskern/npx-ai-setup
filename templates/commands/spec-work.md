---
model: sonnet
disable-model-invocation: true
argument-hint: "[spec number]"
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion, Agent
---

Executes spec $ARGUMENTS step by step and verifies acceptance criteria. Use to implement a single approved spec.

## Process

1. **Find the spec**: If `$ARGUMENTS` is a number (e.g. `001`), open `specs/001-*.md`. If it's a filename, open that directly. If empty, list all draft specs in `specs/` and ask which one to work on.

2. **Read the spec** and understand Goal, Steps, and Files to Modify.

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

5. **Branch setup**: Ask the user whether to create a new branch before starting work.
   - Derive the branch name from the spec filename: `spec/NNN-title` (lowercase, hyphens, strip `.md`)
   - If user says yes: run `git checkout -b spec/NNN-title`. If the branch already exists, offer to switch to it with `git checkout spec/NNN-title`.
   - Update the spec header: set `**Branch**: spec/NNN-title` (or `—` if no branch created).

6. **Read project context**: Skim `.agents/context/CONVENTIONS.md` and `.agents/context/STACK.md` to follow project patterns and use correct libraries.

7. **Load relevant skills**: If the spec's Context section mentions skills, read `.claude/skills/<name>/SKILL.md` for each and apply throughout execution. Skip if none listed.

8. **Architectural review** (high-complexity specs only): Check if the spec header contains `**Complexity**: high`. If yes, spawn the `code-architect` agent via Agent tool, passing the full spec content as the prompt. Then:
   - If the verdict is **REDESIGN**: stop immediately, report all concerns to the user, and do not proceed.
   - If the verdict is **PROCEED WITH CHANGES**: report the concerns to the user, then continue.
   - If the verdict is **PROCEED**: continue normally.

9. **Start work**: Update the spec header — set `**Status**: in-progress`.

10. **Output progress checklist**: Before executing, print a checklist of all steps found in the spec:
   ```
   Progress — Spec NNN
   [ ] Step 1: <title>
   [ ] Step 2: <title>
   ...
   ```
   Check off each item (`[x]`) as you complete it so the user can follow along.

11. **Resume check**: Before executing, scan the spec file for already-checked steps (`- [x]`). If any are found, print a summary:
    ```
    Resuming Spec NNN — skipping N completed steps: Step 1, Step 2, ...
    Continuing from Step N.
    ```
    Skip those steps and begin from the first unchecked step. If all steps are already checked, jump to step 12.

11a. **Model routing by complexity** (before step 12): Read the `**Complexity**` field from the spec header:
    - If `**Complexity**: low` — execute step 12 directly (no subagent — overhead not justified for simple tasks)
    - If `**Complexity**: medium` or unset/missing — spawn subagent with `model: sonnet` for step 12 (default); pass spec content and remaining unchecked steps as context
    - If `**Complexity**: high` — spawn subagent with `model: opus` for step 12; pass spec content and remaining unchecked steps as context

12. **Execute each step** in order:
    - Implement the change
    - After completing a step, edit the spec file to check it off: `- [ ]` -> `- [x]`
    - Update the printed progress checklist to reflect the completed step
    - Commit the completed step: `git add -A && git commit -m "spec(NNN): step N — <title>"`
    - If a step is blocked or unclear, stop and ask the user
    - If you made an architectural, pattern, library, or convention decision during this step that downstream work should know about, append it to `decisions.md` in the project root. Not every step produces decisions — only append when a meaningful choice was made.
    - **Context budget:** If you've been working for many steps and context is growing large, prioritize completing the current step fully (including its commit) over starting the next step. If compaction seems imminent, update the spec with progress markers (`[x]` for completed steps) before continuing — this ensures the next session can resume cleanly.

13. **Verify acceptance criteria**: After all steps are done, check each acceptance criterion. Mark them as checked in the spec.
    For structured criteria (Truths / Artifacts / Key Links), verify each category mechanically:
    - **Truths**: Run the described commands and confirm output matches the stated behavior.
    - **Artifacts**: Read the files and confirm real implementation is present (not stubs or placeholders).
    - **Key Links**: Verify the stated imports or references exist in the source file.

14. **Update CHANGELOG.md**: Add an entry to the `## [Unreleased]` section in `CHANGELOG.md`:
    - Find the `## [Unreleased]` heading (it's just below the `<!-- Entries are prepended below this line, newest first -->` comment)
    - Insert after `## [Unreleased]`: `- **Spec NNN**: [Spec title] — [1-sentence summary of what changed]`
    - Do NOT create date headings — entries accumulate under [Unreleased] until `/release` is run

15. **Verify implementation**: Spawn `verify-app` via Agent tool with the prompt:
    > "Verify that the implementation for spec NNN is correct. Check if the project has a test suite and run it. Check if there is a build command and run it. Report PASS or FAIL."
    - If verify-app returns **PASS**: continue to the next step.
    - If verify-app returns **FAIL**: trigger the **Haiku Investigator** (exactly once — never in a loop):

    When diagnosing failures, follow the debugging discipline:
    - Form a hypothesis before making any change
    - Change one variable at a time
    - After 3 failed fix attempts, stop and reassess your mental model
    - Don't fix symptoms — understand the root cause first

    > **Haiku Investigator** — spawn a sub-agent with these constraints:
    > - Model: haiku | Allowed tools: Read, Glob, Grep, Bash (read-only: `cat`, `ls`, `grep`, `find`) | **Forbidden: Write, Edit**
    > - Prompt: "Diagnose this build/test failure. Read the error output and relevant source files. Identify the root cause. Output: (1) root cause in one sentence, (2) the specific line(s) to fix, (3) exact fix to apply. Do NOT edit any files."
    > - Pass the full verify-app error output to the investigator.

    Apply the investigator's suggested fix as a **single targeted edit**, then run verify-app once more.
    - If the second verify-app returns **PASS**: continue normally.
    - If the second verify-app returns **FAIL**: set status to `in-review`, report the investigator's diagnosis and remaining error, **stop**. Do NOT proceed to step 18 (code-reviewer). Do NOT run the investigator again. Suggest: `Fix the reported issues and re-run /spec-work NNN`.

16. **Optional cleanup**: Offer to run `/simplify` to improve code quality before review. If the user confirms (or execution is non-interactive), invoke it. Skip if the user declines or if no significant code was changed.

17. **Update status**: Set spec status to `in-review` now — before spawning code-reviewer. This ensures status is saved even if the agent call fails.

18. **Auto-review**: Spawn the `code-reviewer` agent via Agent tool to review the changes. Pass the spec content and the current branch name so the agent can run the correct diff.
    - If verdict is **FAIL**: leave status as `in-review`. Report the issues. Suggest: `Run /spec-review NNN to review manually.`
    - If verdict is **PASS** or **CONCERNS**: set status to `completed`, move spec file `specs/NNN-*.md` → `specs/completed/NNN-*.md`. Report: "Auto-review passed. Spec NNN completed."

## Rules
- **ALWAYS update status and move the file when done — this is the single most important step.** Status update (step 17) happens before the review agent — never skip it.
- Follow the spec exactly — nothing outside the Steps and within scope.
- Check off each step in the spec file as you complete it (progress tracking).
- Commit after each completed step (`git add -A && git commit -m "spec(NNN): step N — <title>"`). This enables crash resilience and resume.
- If a step fails or is blocked, leave it unchecked, set status to `blocked`, and ask the user.
- If called with `--complete` flag, skip steps 14–16: set status directly to `completed` and move to `specs/completed/` (legacy behavior).
- If called with `--skip-validate` flag, skip step 3 (validation gate). Use only for specs already validated or when resuming in-progress specs.
