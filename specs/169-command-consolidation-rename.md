# Spec: Slash Command Consolidation — /evaluate → /research + /spec Phase 1 Triage

> **Spec ID**: 169 | **Created**: 2026-03-23 | **Status**: in-progress | **Complexity**: medium | **Branch**: —

## Goal
Eliminate command confusion by renaming `/evaluate` to `/research`, streamlining `/spec` Phase 1 with a triage gate that recommends `/challenge` for complex ideas, and sharpening `/challenge` differentiation.

## Context
`/challenge` and `/spec` Phase 1 overlap 90% (both do concept fit, necessity, overhead, alternatives, GO/SIMPLIFY/REJECT verdict). `/evaluate` name is confusing vs `/challenge`. Solution: keep `/challenge` as fast read-only gate, add triage to `/spec` that recommends `/challenge` when complexity is high, rename `/evaluate` → `/research` for clarity.

### Verified Assumptions
- `/challenge` stays standalone (Sonnet, read-only, no file output) — Evidence: user decision | Confidence: High
- `/spec` Phase 1 gets triage gate, not full challenge repeat — Evidence: user decision | Confidence: High
- `/evaluate` → `/research` is pure rename (same content, new name) — Evidence: user decision | Confidence: High
- CHANGELOG and completed specs are NOT modified — Evidence: convention | Confidence: High
- All Next Step cross-references updated — Evidence: grep shows 8+ files with refs | Confidence: High

## Steps
- [x] Step 1: Rename `templates/commands/evaluate.md` → `templates/commands/research.md` and `.claude/commands/evaluate.md` → `.claude/commands/research.md` — update internal text references from "evaluate" to "research"
- [x] Step 2: Streamline `/spec` Phase 1 in both `templates/commands/spec.md` and `.claude/commands/spec.md` — remove phases 1c (Concept Fit), 1d (Necessity), 1f (Overhead & Risk), 1g (Simpler Alternatives), 1h (Verdict). Replace with a Quick Triage gate after 1b (Clarify): check complexity indicators (>5 files, new dependency/system, architectural keywords like "migrate", "rewrite", "new pattern"). If complex → AskUserQuestion recommending `/challenge` first. Keep Phase 1e (Think It Through) and 1e-bis (Surface Assumptions) — these are spec-specific. Triage must still catch obvious REJECTs (misaligned with CONCEPT.md, clearly out of scope) without doing the full multi-phase deep dive
- [x] Step 3: Sharpen `/challenge` in both `templates/commands/challenge.md` and `.claude/commands/challenge.md` — add clear "When to Use" vs "When NOT to Use" section, add Next Step pointing to `/spec` after GO verdict
- [x] Step 4: Update `README.md` — rename evaluate→research in command table, improve descriptions for /challenge vs /spec distinction
- [ ] Step 5: Update `WORKFLOW-GUIDE.md` in both `.claude/` and `templates/claude/` — rename evaluate→research, add decision flowchart for when to use /challenge vs /spec vs /research

## Acceptance Criteria

### Truths
- [ ] `grep -r '/evaluate' templates/ .claude/commands/ README.md .claude/WORKFLOW-GUIDE.md` returns 0 matches (excluding CHANGELOG/completed specs)
- [ ] `/research` command file exists in both `templates/commands/` and `.claude/commands/`
- [ ] `/spec` Phase 1 contains an AskUserQuestion offering to run `/challenge` when complexity indicators are detected (>5 files, new system, architectural change)

### Artifacts
- [ ] `templates/commands/research.md` — renamed from evaluate.md (min 100 lines)
- [ ] `.claude/commands/research.md` — renamed from evaluate.md (min 100 lines)

### Key Links
- [ ] `/spec` Phase 1 references `/challenge` as recommendation for complex ideas
- [ ] `/challenge` Next Step references `/spec` for GO verdict follow-up

## Files to Modify
- `templates/commands/evaluate.md` → delete, create `templates/commands/research.md`
- `.claude/commands/evaluate.md` → delete, create `.claude/commands/research.md`
- `templates/commands/spec.md` — streamline Phase 1
- `.claude/commands/spec.md` — streamline Phase 1
- `templates/commands/challenge.md` — add When to Use/Avoid
- `.claude/commands/challenge.md` — add When to Use/Avoid
- `README.md` — command table update
- `.claude/WORKFLOW-GUIDE.md` — rename + flowchart
- `templates/claude/WORKFLOW-GUIDE.md` — rename + flowchart

## Risk Mitigation
Users who run `/spec` directly (skipping `/challenge`) currently get a thorough challenge in Phase 1. After this change they get a lighter triage. Mitigation: the triage gate still checks CONCEPT.md alignment and catches obvious REJECT cases. For anything non-trivial, it actively recommends `/challenge`. Phase 1e (Think It Through) and 1e-bis (Surface Assumptions) remain — these ensure spec quality even without a prior `/challenge`.

## Out of Scope
- CHANGELOG.md, completed specs, brainstorm files (historical references stay)
- Content changes to /research beyond the rename
- Changes to /analyze or /discover (separate concern)
- `/explore` skill internal files (no `/challenge` or `/evaluate` references found)
