# Spec: /simplify in spec-work + Advanced Tools Documentation

> **Spec ID**: 076 | **Created**: 2026-03-10 | **Status**: in-progress | **Branch**: —

<!-- Status lifecycle: draft → in-progress → in-review → completed (or blocked at any stage) -->

## Goal
Add an optional `/simplify` cleanup step to `spec-work`, document `ralph-loop` and `defuddle`/`markdown.new` in `WORKFLOW-GUIDE.md`, and add a web-fetching preference rule to `general.md`.

## Context
`/simplify` is a bundled Claude Code skill (always available) that spawns 3 parallel agents to fix code reuse, quality, and efficiency issues. Currently `spec-work` goes verify-app → code-reviewer — a `/simplify` pass between the two improves code quality before review.

`ralph-loop` is already installed globally as a plugin. Its Stop-hook mechanism conflicts with our hook safety rules — do NOT add to installer, but document for advanced users.

`defuddle` (CLI) and `markdown.new` (URL prefix: `https://markdown.new/<url>`) both convert web pages to clean markdown with ~80% fewer tokens than raw HTML. Neither is referenced in any current rule or template, so Claude defaults to WebFetch unnecessarily.

## Steps

- [x] Step 1: In `templates/commands/spec-work.md`, insert a new step 14 between verify-app (step 13) and status update (current step 14): "Offer to run `/simplify` to clean up the implementation. If the user confirms or no user input is expected, invoke it. This step is optional — skip if already clean or user declines." Renumber subsequent steps (14→15, 15→16).
- [x] Step 2: Apply the same change to `.claude/commands/spec-work.md` (installed copy).
- [ ] Step 3: In `templates/claude/rules/general.md`, add a `## Web Fetching` section: "Prefer `defuddle parse <url> --md` over WebFetch for reading web pages — it removes navigation and clutter, saving ~80% tokens. Alternative: prepend `https://markdown.new/` to any URL for instant markdown conversion. Use WebFetch only when defuddle is unavailable or the page requires JS rendering."
- [ ] Step 4: Apply same rule change to `.claude/rules/general.md` (installed copy).
- [ ] Step 5: In `templates/claude/WORKFLOW-GUIDE.md`, add `## Advanced Techniques` section covering: (a) ralph-loop — iterative task loops, usage example, `/cancel-ralph`; (b) defuddle + markdown.new — token-efficient web fetching with examples.
- [ ] Step 6: Verify smoke tests pass: `bash tests/smoke.sh`

## Acceptance Criteria
- [ ] `spec-work` includes an optional `/simplify` step between verify-app and status update
- [ ] `templates/claude/rules/general.md` has a Web Fetching section preferring defuddle/markdown.new
- [ ] `WORKFLOW-GUIDE.md` documents ralph-loop and defuddle/markdown.new with examples
- [ ] ralph-loop is NOT added to the installer or setup flow
- [ ] Smoke tests pass (83/83)

## Files to Modify
- `templates/commands/spec-work.md` — insert simplify step, renumber
- `.claude/commands/spec-work.md` — same change (installed copy)
- `templates/claude/rules/general.md` — add Web Fetching section
- `.claude/rules/general.md` — same change (installed copy)
- `templates/claude/WORKFLOW-GUIDE.md` — add Advanced Techniques section

## Out of Scope
- Installing ralph-loop via the setup script (Stop-hook conflicts with safety rules)
- Making `/simplify` blocking or mandatory
- Installing defuddle via the setup script (already a global skill)
