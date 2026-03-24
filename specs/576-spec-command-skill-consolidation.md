# Spec 576 — Spec Command/Skill Consolidation

**Status**: open
**Goal**: Eliminate dual-implementation of spec commands. Skills become the single source of truth; commands become thin wrappers (3 lines each).

## Problem

Spec functionality exists in two parallel systems:
- `.claude/commands/spec-*.md` — full implementations (48–188 lines)
- `.claude/skills/spec-*/SKILL.md` — partial reimplementations (36–113 lines)

When `/spec-work` is typed, the **command** executes (not the skill). Both can diverge silently. Maintenance overhead doubles.

## Solution

**Skills win.** Full implementation goes into SKILL.md. Commands become 3-line redirectors:

```markdown
---
model: sonnet
argument-hint: "[spec number]"
---
$ARGUMENTS — invoke via the `Skill` tool with skill `spec-work`.
```

Actually: commands can't programmatically invoke the Skill tool. The correct thin wrapper is an instruction to Claude:

```markdown
---
model: sonnet
argument-hint: "[spec number]"
---
Use the Skill tool: `Skill({skill: "spec-work", args: "$ARGUMENTS"})`.
```

## Steps

- [ ] Step 1: Audit — diff each command vs its skill, identify which has more complete/correct content per pair
- [ ] Step 2: Merge `spec-work` — expand SKILL.md with full command content, strip command to 5-line wrapper
- [ ] Step 3: Merge `spec` (create) — expand `spec-create` SKILL.md, strip `spec.md` command
- [ ] Step 4: Merge `spec-review`, `spec-validate`, `spec-board`, `spec-work-all`
- [ ] Step 5: Sync templates — mirror all changes to `templates/commands/` and `templates/skills/`
- [ ] Step 6: Update `lib/setup.sh` if installation logic references command content

## Acceptance Criteria

- [ ] Each spec command file is ≤10 lines
- [ ] Each spec SKILL.md contains the full, merged implementation
- [ ] `/spec-work 074` still executes correctly (via Skill tool invocation)
- [ ] No content exists only in the command that isn't in the SKILL.md
- [ ] Template files match installed files

## Files to Modify

**Commands (→ thin wrappers):**
- `templates/commands/spec.md` + `.claude/commands/spec.md`
- `templates/commands/spec-work.md` + `.claude/commands/spec-work.md`
- `templates/commands/spec-review.md` + `.claude/commands/spec-review.md`
- `templates/commands/spec-validate.md` + `.claude/commands/spec-validate.md`
- `templates/commands/spec-board.md` + `.claude/commands/spec-board.md`
- `templates/commands/spec-work-all.md` + `.claude/commands/spec-work-all.md`

**Skills (→ full implementation):**
- `templates/skills/spec-create/SKILL.md` + `.claude/skills/spec-create/SKILL.md`
- `templates/skills/spec-work/SKILL.md` + `.claude/skills/spec-work/SKILL.md`
- `templates/skills/spec-review/SKILL.md` + `.claude/skills/spec-review/SKILL.md`
- `templates/skills/spec-validate/SKILL.md` + `.claude/skills/spec-validate/SKILL.md`
- `templates/skills/spec-board/SKILL.md` + `.claude/skills/spec-board/SKILL.md`
- `templates/skills/spec-work-all/SKILL.md` + `.claude/skills/spec-work-all/SKILL.md`
