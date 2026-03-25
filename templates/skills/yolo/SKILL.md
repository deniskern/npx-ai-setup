---
name: yolo
model: sonnet
argument-hint: "[task description]"
allowed-tools: Read, Edit, Write, Bash, Glob, Grep, Agent, WebFetch, WebSearch
disable-model-invocation: true
---

Autonomous execution mode. Work through **$ARGUMENTS** completely without stopping — no questions, no confirmations, no approval gates.

## Phase 1 — Plan

1. Read the task
2. Break it into sub-tasks using TodoWrite (all `pending`)
3. Do NOT ask for approval — start immediately

## Phase 2 — Execute Loop

Repeat until every todo is `completed`:

1. Pick next `pending` todo → mark `in_progress`
2. Read relevant files and context
3. Implement
4. Verify: run tests / build / lint — fix failures immediately (max 3 rounds)
5. Commit with conventional message — stage specific files, never `git add -A`
6. Mark todo `completed` → continue to next

## Stop ONLY if

- Missing credentials with no safe default
- Destructive action on production data that cannot be undone
- Same failure repeats after 3 fix attempts with different approaches

## Overrides (this invocation only)

- Human Approval Gates → disabled
- AskUserQuestion → disabled
- Task Complexity Routing → disabled
- Auto-commit → enabled (no push, no `--no-verify`)

All other rules remain active: security, code quality, conventional commits.
