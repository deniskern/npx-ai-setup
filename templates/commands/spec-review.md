---
model: opus
mode: plan
argument-hint: "[spec number]"
allowed-tools: Read, Glob, Grep, Bash, AskUserQuestion, Agent
---

Reviews spec $ARGUMENTS and its code changes against acceptance criteria. Use after spec-work to validate and close.

## Process

### 1. Find the spec
If `$ARGUMENTS` is a number (e.g. `011`), open `specs/011-*.md`. If it's a filename, open that directly. If empty, list all specs with status `in-review` in `specs/` and ask which one to review.

### 2. Validate status
The spec's status must be `in-review`. If it's `draft` or `in-progress`, report: "Spec is not ready for review (status: X). Run `/spec-work NNN` first." and stop. If it's `completed`, report: "Spec is already completed." and stop.

### 3. Read the spec
Understand Goal, Steps, Acceptance Criteria, Files to Modify, and Out of Scope. Note which steps and criteria are checked off.

### 4. Inspect code changes
Read the `**Branch**` field from the spec header. Then:

- If a branch exists (not `—`): run `git diff main...BRANCH` to see all changes on that branch
- If no branch: run `git diff` and `git diff --staged` to see uncommitted changes

For each changed file, read the full file to understand context around the changes. **Cap**: Read at most the 5 most significantly changed files in full; for remaining files, review only the diff hunks.

### 5. Review against spec

#### 5a — Spec compliance & acceptance criteria
- Are ALL steps checked off and matching what was described?
- Are acceptance criteria genuinely met (verify against diff, not checkboxes)?
- Was anything built that's listed in "Out of Scope"? Flag scope creep.

For structured acceptance criteria (Truths / Artifacts / Key Links), verify each category mechanically:
- **Truths**: Run the described command or check and confirm the output matches the stated behavior.
- **Artifacts**: Confirm the file exists, has real implementation (not a placeholder or stub), and meets any minimum line count specified.
- **Key Links**: Open the source file and confirm the stated import or reference is actually present.

#### 5b — Definition of Done
If `.agents/context/CONVENTIONS.md` contains a `## Definition of Done` section, verify the code changes satisfy those global quality gates. Report unmet gates as blocking issues.

#### 5c — Code quality (complexity-gated)
Read the `**Complexity**` field from the spec header.
- **Low / Medium / unset**: Spawn `code-reviewer` agent only via Agent tool.
- **High**: Spawn `code-reviewer` AND `staff-reviewer` agents in parallel via Agent tool. Both must return PASS or CONCERNS.
Pass the full spec content and branch name. Use each agent's verdict (PASS / CONCERNS / FAIL) and issue list as code quality input. Do NOT duplicate their analysis inline.

### 6. Verdict

Present the review findings, then choose exactly one:

**APPROVED** — All acceptance criteria met AND all review agents returned PASS or CONCERNS.
1. Status → `completed`, move to `specs/completed/NNN-*.md`
2. Report: "Spec NNN approved."

**CHANGES REQUESTED** — Any review agent returned FAIL, or acceptance criteria not met.
1. Add `## Review Feedback` with concrete issues and fix instructions
2. Status → `in-progress`
3. Report: "Run `/spec-work NNN` to address feedback, then `/spec-review NNN` again."

**REJECTED** — Critical security or regression issue found.
1. Status → `blocked`, add `## Review Feedback` with rejection reason
2. Report why and suggest next steps.

## Rules
- Do NOT make code changes. Only review and update spec status/feedback.
- Read the actual code before commenting — never speculate.
- Focus on what matters: spec compliance and bugs over style.
- If the diff is empty (no changes found), report this and ask the user to verify.
- Never push to remote or create PRs automatically.
