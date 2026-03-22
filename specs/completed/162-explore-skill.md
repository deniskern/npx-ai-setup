# Spec: Read-Only Explore Skill

> **Spec ID**: 162 | **Created**: 2026-03-22 | **Status**: completed | **Complexity**: low | **Branch**: —

## Goal
Add a `/explore` skill as a read-only thinking partner that can read code but never write files, helping users explore solution spaces before committing to a spec.

## Context
Inspired by OpenSpec's `/opsx:explore`. We have `/challenge` for critical idea evaluation (GO/SIMPLIFY/REJECT), but no open-ended exploration mode. `/explore` fills a different role: curious, not prescriptive. It reads codebase, draws ASCII diagrams, explores tradeoffs, and exits by suggesting `/spec` when the user is ready to commit. Key constraint: MUST NOT use Write, Edit, or NotebookEdit tools.

## Steps
- [x] Step 1: Create `templates/skills/explore/SKILL.md` — read-only skill that can use Read, Glob, Grep, Bash (read-only commands), WebFetch, WebSearch. Explicit tool deny-list: Write, Edit, NotebookEdit. Include exit triggers (user wants to implement → suggest `/spec`)
- [x] Step 2: Copy to `.claude/skills/explore/SKILL.md`
- [x] Step 3: Add `/explore` to WORKFLOW-GUIDE.md in the Onboarding/Planning section, document the difference to `/challenge`

## Acceptance Criteria

### Truths
- [x] "The explore skill SKILL.md does not list Write, Edit, or NotebookEdit in its tools"
- [x] "WORKFLOW-GUIDE.md mentions /explore with a one-line description"

### Artifacts
- [x] `templates/skills/explore/SKILL.md` — read-only thinking partner skill (min 25 lines)

## Files to Modify
- `templates/skills/explore/SKILL.md` — new skill
- `.claude/skills/explore/SKILL.md` — copy
- `templates/WORKFLOW-GUIDE.md` — add entry

## Out of Scope
- Changes to /challenge skill
- Adding /explore to the spec creation flow
