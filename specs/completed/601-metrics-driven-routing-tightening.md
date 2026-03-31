# Spec: Metrics-Driven Routing Tightening

> **Spec ID**: 601 | **Created**: 2026-03-31 | **Status**: completed | **Complexity**: medium | **Branch**: spec/601-metrics-driven-routing-tightening

## Goal
Tighten model and subagent routing so routine work defaults cheaper, heavy work escalates deliberately, and session data feeds back into clearer routing rules.

## Context
Recent session analysis showed strong Sonnet dominance, near-zero Haiku usage, and low subagent usage in workflows that still accumulate many tool calls. Current guidance in `CLAUDE.md`, `.claude/rules/agents.md`, and spec skills is partly aligned but still leaves too much discretion, especially for routine exploration and medium-complexity spec execution.

### Risks & Blockers
- `.claude/skills` is sandbox-protected — edits to SKILL.md files require `dangerouslyDisableSandbox: true` or user confirmation per project rules.
- Skill-Trimming Quality Gate in `spec-work` applies: any SKILL.md changes will be audited for CRITICAL removed elements before the spec can close.
- Step 4 scope: "adjacent routing-sensitive skill text" is bounded to `spec-review/SKILL.md` only — no other skills in scope.

### Verified Assumptions
- Routing guidance in `CLAUDE.md` and `.claude/rules/agents.md` materially influences session behavior — Evidence: both files define explicit model and subagent defaults | Confidence: High | If Wrong: behavior changes must happen in skills only.
- `spec-work` is a meaningful lever because it currently routes medium complexity directly to Sonnet subagents and high to Opus — Evidence: `.claude/skills/spec-work/SKILL.md` | Confidence: High | If Wrong: the main routing pressure sits elsewhere, such as review or global session startup guidance.
- `spec-review` already avoids Opus and is not the primary model-cost problem — Evidence: `.claude/skills/spec-review/SKILL.md` uses Sonnet reviewers for both complexity tiers | Confidence: High | If Wrong: review routing must be part of the same change.

## Steps
- [x] Step 1: Refine routing rules in `CLAUDE.md` so Haiku is the explicit default for exploration, lookup, and lightweight codebase work, Sonnet is reserved for implementation, and Opus requires clearer escalation conditions.
- [x] Step 2: Tighten `.claude/rules/agents.md` so subagent spawning is recommended only above a concrete work threshold, while still pushing Haiku-first routing for bounded exploration and simple edits.
- [x] Step 3: Update `.claude/skills/spec-work/SKILL.md` to reduce unnecessary Sonnet/Opus escalation for low-to-medium spec execution, while preserving review and verification safety gates.
- [x] Step 4: Review `.claude/skills/spec-review/SKILL.md` and any adjacent routing-sensitive skill text to ensure the new guidance is consistent and does not reintroduce implicit expensive defaults.
- [x] Step 5: Add or extend smoke-test assertions in `tests/smoke.sh` to verify the tightened routing language and key model-selection rules remain present in tracked files.
- [x] Step 6: Run routing-related verification and summarize the intended behavioral change against the session-optimize findings that motivated it.

## Acceptance Criteria
- [x] `CLAUDE.md` explicitly makes Haiku the routine default for exploration/search-style work and narrows Opus to deliberate escalation cases.
- [x] `.claude/rules/agents.md` contains the literal string `haiku` as the default model label, and `spec-work/SKILL.md` no longer routes medium-complexity without an explicit Haiku-first rationale or threshold comment.
- [x] Smoke tests assert the presence of the new routing rules so future edits cannot silently weaken them.
- [x] The resulting guidance is internally consistent across `CLAUDE.md`, agent-routing rules, and the touched spec skills.

## Files to Modify
- `CLAUDE.md` - tighten top-level model-routing guidance
- `.claude/rules/agents.md` - sharpen subagent and model thresholds
- `.claude/skills/spec-work/SKILL.md` - reduce unnecessary expensive routing in spec execution
- `.claude/skills/spec-review/SKILL.md` - align adjacent review routing if needed
- `tests/smoke.sh` - lock in the routing guidance via assertions

## Out of Scope
- Rewriting every skill with model routing in one pass
- Adding new models or external routing infrastructure
- Changing session-extract metrics again beyond using their findings as motivation
