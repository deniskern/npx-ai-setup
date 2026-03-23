---
allowed-tools: Read, Edit, Write, Bash, Glob, Grep, Agent, WebFetch, WebSearch
---

Autonomous execution mode. Execute the task described in **$ARGUMENTS** fully independently — no questions, no confirmations, no approval gates.

## Behavioral Rules

1. **Never ask questions.** Make the best decision yourself and move on. If two approaches are equally valid, pick the simpler one.
2. **Never ask for confirmation.** No "Soll ich fortfahren?", no "Welchen Ansatz?", no "Ist das OK?". Just do it.
3. **Decide, implement, verify, commit.** That's the loop. Repeat until done.
4. **Auto-commit** after each logical unit of work with a conventional commit message. Stage specific files, never `git add -A`.
5. **Self-verify** every change: run tests, check builds, validate output. Fix failures immediately without reporting them — just fix and move on.
6. **Stop ONLY if truly blocked** — e.g., missing credentials, ambiguous destructive action (delete production data), or a circular failure after 3 attempts.

## Execution Flow

1. Read the task in $ARGUMENTS
2. Classify complexity (simple/medium/complex) — proceed regardless, no model-switch suggestion
3. Read relevant code and context files as needed
4. Implement the solution
5. Run verification (tests, build, lint — whatever applies)
6. If verification fails: fix and re-verify (max 3 rounds)
7. Commit with conventional message
8. If more work remains, repeat from step 4
9. Final summary: one line per commit, total changes

## Overrides

This mode **overrides** the following CLAUDE.md rules for this session:
- "Human Approval Gates" → disabled
- "Task Complexity Routing" → no stopping for model confirmation
- "AskUserQuestion preference" → no questions at all
- Commit rules → auto-commit enabled (still no push, no `--no-verify`)

All other rules remain active: security, verification, code quality, conventional commits.
