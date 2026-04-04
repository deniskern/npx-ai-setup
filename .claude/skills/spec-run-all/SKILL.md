---
name: ais:spec-run-all
model: sonnet
description: "Run full pipeline for all draft specs in parallel. Triggers: /spec-run-all, 'run all specs', 'implement everything', 'do all the drafts'."
---

# Spec Run All — Full Pipeline for All Draft Specs

Executes all draft specs in `specs/` in dependency-aware waves using isolated Git worktrees.

## Process

### 1. Discover draft specs
Scan `specs/` for `NNN-*.md` (excluding `specs/completed/`). Only `Status: draft`. Read Goal and Out of Scope for dependency map. No drafts → report and stop.

### 2. Dependency detection
A spec depends on another if Out of Scope names a spec number. Group into parallel (no deps) and sequential (run after dependency).

### 3. Execute in waves

**Setup** per spec: derive branch `spec/NNN-title`, set status to `in-progress` and branch in spec header.

**Execution**: Max 2 concurrent worktree agents per wave. Launch via Agent tool with `isolation: "worktree"`, `model: sonnet`.

**Subagent prompt** must include:
1. `git branch -m spec/NNN-title`
2. Copy .env from main repo: `MAIN_REPO=$(git worktree list | head -1 | awk '{print $1}')` then copy all `.env*` except `.env.example` and `.env.template`
3. Install deps: check for `bun.lockb` → `bun install --frozen-lockfile`, else `package-lock.json` → `npm ci`, else `pnpm-lock.yaml` → `pnpm install --frozen-lockfile`, else `yarn.lock` → `yarn install --frozen-lockfile`
4. Run full pipeline: invoke `/spec-run NNN` — validates, implements, reviews (self-healing), and commits

Low-complexity specs (1-2 files, no build) can run directly in main repo.

**Post-processing per subagent:**

Failed: set `blocked`, add `## Review Feedback`, remove worktree, report.

Succeeded:
1. Verify spec status is `completed` (set by `/spec-run`)
2. Remove worktree (branch preserved for merge)

### 4. Final summary
```bash
git worktree prune && rm -rf .claude/worktrees/* 2>/dev/null
```
Report completed/failed specs with IDs, titles, branches. Next: `/spec-review NNN` or `/spec-board`.

## Skill-Trimming Quality Gate

When a spec modifies SKILL.md files: after subagent completes but before marking `in-review`, spawn a **quality-diff subagent** (model: haiku) that compares `git diff` of each changed SKILL.md. It must classify every removed element as REDUNDANT or CRITICAL. Any CRITICAL removal blocks the spec — set `blocked` instead of `in-review`, report findings.

## Rules
- Max 2 concurrent worktree agents — more causes auth failures
- Follow specs exactly — no scope creep
- Blocked steps: mark unchecked, continue remaining
- Always report failures with reason

## Next Step

> 📋 Naechster Schritt: `/spec-board` — Ergebnisse pruefen und offene Specs reviewen
