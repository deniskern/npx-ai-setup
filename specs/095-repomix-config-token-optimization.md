# Spec: Repomix Config Token Optimization

> **Spec ID**: 095 | **Created**: 2026-03-16 | **Status**: draft | **Branch**: —

## Goal
Reduce repomix snapshot token consumption by ~15-20% via XML style and comment/whitespace stripping.

## Context
Current template uses `style: markdown` and omits `removeComments`/`removeEmptyLines`. Anthropic recommends XML for structured LLM input. The CLI fallback in `lib/setup.sh` and all command/agent templates must stay in sync with the config template.

## Steps
- [ ] Step 1: Update `templates/repomix.config.json` — set `style: "xml"`, add `removeComments: true`, `removeEmptyLines: true`, change `filePath` to `.agents/repomix-snapshot.xml`
- [ ] Step 2: Update `lib/setup.sh` `generate_repomix_snapshot()` — change CLI fallback flags to `--style xml`, add `--remove-comments --remove-empty-lines`, update output path and existence check to `.xml`
- [ ] Step 3: Update `templates/commands/context-full.md` — change repomix flags and output path to `.xml`
- [ ] Step 4: Update `templates/agents/context-refresher.md` — change repomix flags and output path to `.xml`
- [ ] Step 5: Update all ignore patterns referencing `repomix-snapshot.md` → `.xml` (`.gitignore`, `repomix.config.json` self-reference)
- [ ] Step 6: Verify by running `./bin/ai-setup.sh` on a test project and confirming XML output

## Acceptance Criteria
- [ ] Snapshot generates as `.agents/repomix-snapshot.xml` with XML formatting
- [ ] All 4 locations (config template, CLI fallback, context-full command, context-refresher agent) use consistent flags
- [ ] Running setup twice does not regenerate the snapshot (idempotency preserved)

## Files to Modify
- `templates/repomix.config.json` — add XML style and stripping options
- `lib/setup.sh` — update CLI fallback flags and file path checks
- `templates/commands/context-full.md` — update repomix invocation
- `templates/agents/context-refresher.md` — update repomix invocation
- `.gitignore` — update snapshot filename

## Out of Scope
- Repomix version pinning
- Split-output for monorepos
- Token count reporting in config
