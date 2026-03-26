---
name: spec-work
description: Execute a single spec step by step. Triggers: /spec-work NNN, 'work on spec NNN', 'implement spec NNN', 'run spec NNN'. NNN is a 3-digit spec number.
---

Executes spec $ARGUMENTS step by step and verifies acceptance criteria. Use to implement a single approved spec.

## Process

1. **Find the spec**: If `$ARGUMENTS` is a number (e.g. `001`), open `specs/001-*.md`. If it's a filename, open that directly. If empty, list all draft specs and ask.

2. **Read the spec** — understand Goal, Steps, and Files to Modify.

3. **Validation gate** (skip if `--skip-validate` or status is `in-progress`):
   Score on 10 criteria (goal clarity, step decomposition, dependencies, coverage, acceptance criteria, scope, risks, file coverage, out-of-scope, integration). If any critical gap: **STOP** and tell user to fix first.

4. **Understanding confirmation** (only if `**Complexity**: high`):
   Show Goal/Approach/Files summary, ask "Does this match?" via AskUserQuestion. Stop if user says no.

5. **Branch setup**: Ask user whether to create branch `spec/NNN-title`. Update spec header with branch name.

6. **Read project context**: Skim `CONVENTIONS.md` and `STACK.md` from `.agents/context/`.

7. **Load relevant skills**: If spec's Context mentions skills, read and apply them.

8. **Architectural review** (only if `**Complexity**: high`): Spawn `code-architect` agent with spec content. REDESIGN → stop. PROCEED WITH CHANGES → report concerns, continue. PROCEED → continue.

9. **Start work**: Set `**Status**: in-progress`.

10. **Progress checklist**: Print all steps as `[ ] Step N: <title>`. Check off each as completed.

11. **Resume check**: Scan for `- [x]` steps. Skip completed steps, continue from first unchecked.

11a. **Model routing**: Read `**Complexity**` field:
    - `low` — execute directly (no subagent)
    - `medium` or unset — spawn subagent with `model: sonnet`
    - `high` — spawn subagent with `model: opus`

12. **Execute each step**:
    - Implement the change
    - Check off in spec: `- [ ]` → `- [x]`
    - Commit: `git add -u && git ls-files --others --exclude-standard | xargs -r git add && git commit -m "spec(NNN): step N — <title>"`
    - If blocked/unclear: stop and ask
    - If a meaningful architectural/convention decision was made: append to `decisions.md`
    - **Context budget:** If compaction seems imminent, update spec progress markers before continuing

    **Stall detection:**
    - **Retry limit**: Same step fails 3× → mark as blocked (`- [~]`), set `**Status**: blocked`, stop.
    - **No-change detection**: 2 consecutive steps with no file changes → ask user via AskUserQuestion: "Two steps with no changes. Expected?" Options: [Yes, continue] [No, investigate] [Abort]
    - **Completion stats**: After all steps, print steps completed/blocked and files changed.

13. **Verify acceptance criteria**: Check each criterion in the spec. For Truths: run commands. For Artifacts: read files. For Key Links: verify imports exist.

14. **Update CHANGELOG.md**: Insert under `## [Unreleased]`: `- **Spec NNN**: [title] — [summary]`.

15. **Verify implementation**: Spawn `verify-app` agent.
    - **PASS**: continue.
    - **FAIL**: Spawn Haiku Investigator once (model: haiku, tools: Read/Glob/Grep/Bash read-only, no Write/Edit). Pass error output. Apply suggested fix, re-run verify-app once. Second FAIL → set `in-review`, stop.

15a. **Test coverage check** (after verify-app PASS): Check if changed source files have corresponding test files. If coverage gaps exist, spawn `test-generator` agent (model: sonnet). Skip if spec is test-only or no test framework detected.

16. **Optional cleanup**: Offer `/simplify` before review. Skip if user declines.

17. **Update status**: Set `in-review` before spawning reviewers.

18. **Auto-review** (complexity-gated):
    - Low/Medium/unset: spawn `code-reviewer` only.
    - High: spawn `code-reviewer` + `staff-reviewer` in parallel.
    - **Conditional reviewers** (spawn in parallel with code-reviewer if applicable):
      - Spec touches auth, user input, API endpoints, or secrets → also spawn `security-reviewer`
      - Spec touches DB queries, loops, rendering, data fetching, or bundle imports → also spawn `performance-reviewer`
    - FAIL → leave `in-review`, report issues. PASS/CONCERNS → set `completed`, move to `specs/completed/`.

## Skill-Trimming Quality Gate

When a spec modifies SKILL.md files (trimming, condensing, refactoring): after all steps, before step 13, spawn a **quality-diff subagent** (model: haiku):

**Prompt**: "Compare the original and trimmed versions of these SKILL.md files. For each file:
1. Run `git diff HEAD -- <file>` to see what changed
2. List every REMOVED functional element (commands, decision tables, agent spawn instructions, output format templates, conditional logic, file paths, specific flags/options)
3. For each removed element: classify as REDUNDANT (obvious to Claude, derivable from context) or CRITICAL (specific values, formats, or logic that Claude would not infer)
4. Report: file, removed element, classification, risk if missing"

**Gate**: If any element is classified CRITICAL → stop, report to user, do NOT mark spec as completed. Re-add the critical elements before proceeding.

## Rules
- **ALWAYS update status and move the file when done.**
- Follow the spec exactly — nothing outside Steps and scope.
- Check off each step and commit after each (`spec(NNN): step N — <title>`).
- If blocked: leave unchecked, set `blocked`, ask user.
- **Skill-First**: If a step references a skill, invoke via `Skill` tool.
- `--complete` flag: skip steps 14–16, set `completed` directly.
- `--skip-validate` flag: skip step 3.

## Next Step

After implementation: `/spec-review NNN` to validate, then `/pr` or `/spec-board`.
