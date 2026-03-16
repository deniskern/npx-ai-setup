# Spec: Monorepo Auto-Discovery

> **Spec ID**: 105 | **Created**: 2026-03-16 | **Status**: completed | **Branch**: — | **Complexity**: medium

## Goal
Auto-detect monorepo workspace packages and generate `repo-group.json` without manual wizard input.

## Context
The multi-repo context feature (`repo-group.json`) currently requires manual configuration. Standard monorepo setups (npm/yarn/pnpm workspaces, Turborepo, Lerna) declare packages in `package.json` or `pnpm-workspace.yaml`. Auto-reading these eliminates friction for the most common case.

## Steps
- [x] Step 1: Create `lib/monorepo.sh` — `detect_workspaces()` reads `package.json` workspaces array, `pnpm-workspace.yaml` packages array, `lerna.json` packages array; resolves globs to actual directories
- [x] Step 2: In `lib/setup.sh` — after system detection, call `detect_workspaces`; if packages found and no `repo-group.json` exists, generate it with discovered packages as entries
- [x] Step 3: Add `lib/monorepo.sh` to `_loader.sh` source chain
- [x] Step 4: Test: create mock workspace structure, verify `repo-group.json` is generated with correct paths
- [x] Step 5: Skip generation if `repo-group.json` already exists (idempotent)

## Acceptance Criteria
- [x] npm/yarn workspaces detected from `package.json` `workspaces` field
- [x] pnpm workspaces detected from `pnpm-workspace.yaml`
- [x] Existing `repo-group.json` is never overwritten
- [x] Non-monorepo projects are unaffected (no file created)

## Files to Modify
- `lib/monorepo.sh` — create workspace detection logic
- `lib/_loader.sh` — add monorepo.sh to source chain
- `lib/setup.sh` — call workspace detection after system detection

## Out of Scope
- Multi-repo (separate git roots) auto-discovery
- Workspace-level ai-setup runs (only root-level detection)
