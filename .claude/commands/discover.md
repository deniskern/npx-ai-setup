---
model: opus
mode: plan
allowed-tools: Read, Glob, Grep, Bash, Agent, Write, AskUserQuestion
---

Reverse-engineers draft specs from an existing codebase. Use for legacy projects and onboarding — where code exists but specs don't.

## Step 0 — Scope

Ask the user before scanning:

```
AskUserQuestion: What should /discover scan?
Options:
  A) Full codebase (recommended for first run)
  B) Specific subdirectory (enter path)
  C) Cancel
```

If B: ask for the path. Store as `SCAN_ROOT` (default: `.`).

## Phase 1 — Codebase Inventory

Spawn all three agents simultaneously using the Agent tool in parallel:

**Agent 1 — Entry Points**

```
You are an Entry Points agent. Scan the codebase rooted at SCAN_ROOT and report:

1. Identify all entry points: main files, index files, CLI entrypoints (bin/), server bootstraps, cron/job runners.
2. For each entry point: file path, what it starts/exports, its direct dependencies.
3. List framework or runtime detected (Node, Python, Ruby, Go, PHP, etc.).

Return a concise report under: ## Entry Points
Include: file path, role, key dependencies. Max 30 lines.
```

**Agent 2 — Module Boundaries**

```
You are a Module Boundaries agent. Scan the codebase rooted at SCAN_ROOT and report:

1. Identify top-level directories and their responsibilities.
2. Map logical modules: groups of files with a shared concern (auth, payments, api, ui, db, etc.).
3. For each module: directory/files, inferred responsibility, external dependencies.
4. Note cross-module coupling (modules that import from each other heavily).

Return a concise report under: ## Module Boundaries
Include: module name, path, responsibility, notable dependencies. Max 30 lines.
```

**Agent 3 — Data Flows**

```
You are a Data Flows agent. Scan the codebase rooted at SCAN_ROOT and report:

1. Trace primary data flows: input sources → processing → output/storage.
2. Identify persistence layers (databases, files, queues, caches).
3. Identify external integrations (APIs, webhooks, third-party services).
4. Note where data is validated, transformed, or serialized.

Return a concise report under: ## Data Flows
Include: source, transformation steps, sink. Max 30 lines.
```

After all three agents return, present a combined inventory:

```
## Codebase Inventory

### Entry Points
[Agent 1 output]

### Module Boundaries
[Agent 2 output]

### Data Flows
[Agent 3 output]
```

## Phase 2 — 5W Analysis

For each discovered module from Agent 2, produce a structured 5W summary:

| Module | What | Why | Who | When | Where |
|--------|------|-----|-----|------|-------|
| [name] | what it does | why it exists | who uses/calls it | when it runs | key files |

Present the table to the user. Keep each cell to one sentence.

## Phase 3 — Spec Generation

Ask the user which modules to spec:

```
AskUserQuestion: Which modules should get draft specs?
Options:
  A) All modules
  B) Select specific modules (enter comma-separated names)
  C) Skip — inventory only
```

If A or B: for each selected module, generate a draft spec file at `specs/DDD-[module-name].md` using the standard template:

```markdown
# Spec: [Module Name] — [inferred goal]

> **Spec ID**: DDD | **Created**: [today] | **Status**: draft | **Complexity**: medium | **Branch**: —

## Goal
[One sentence: what this module does or should do]

## Context
[Why it exists — inferred from codebase analysis]

## Steps
- [ ] Step 1: Review and validate this spec against actual code
- [ ] Step 2: [Next actionable improvement or refactor identified]
- [ ] Step 3: Add tests for core behaviour

## Acceptance Criteria
- [ ] Module behaviour matches spec Goal
- [ ] Key data flows documented and tested

## Files to Modify
- [list key files from module boundary analysis]

## Out of Scope
- Rewriting unrelated modules
- Changing external API contracts without explicit decision
```

Use the next available spec number (scan `specs/` for the highest existing NNN, increment by 1 for each generated spec).

After writing all specs, report:
- How many specs were generated
- File paths created
- Suggested first spec to execute

## Rules

- Launch Phase 1 agents simultaneously — do not wait for one before starting the next.
- Each agent works independently — no shared state between them.
- Never overwrite an existing spec file — skip and warn if `specs/NNN-*.md` already exists with that number.
- Keep generated specs concise: max 60 lines per file.
- If a command fails (e.g. git not available), note it and continue with available data.

## Next Step

After generating draft specs, run `/spec-validate NNN` to score each spec, then `/spec-work NNN` to implement the highest-priority one.
