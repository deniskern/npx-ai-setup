# Spec 078 — WORKFLOW-GUIDE: Local API Dumps Section

**Status:** completed
**Created:** 2026-03-12

## Goal

Add a "Local API Dumps — MCP Acceleration" section to `templates/claude/WORKFLOW-GUIDE.md` documenting the generic pattern of dumping API data locally before MCP-intensive tasks.

## Context

When working with CMS/API-backed MCP servers (Storyblok, Shopify, etc.), Claude currently makes blind discovery calls — listing stories, searching by slug, paginating results. A local dump file lets Claude read all IDs/slugs instantly and make only targeted MCP calls. This pattern is already proven in ONEDOT Storyblok projects via `npm run storyblok-dump`.

WORKFLOW-GUIDE already documents similar workflow accelerators (repomix, squirrelscan, defuddle). This section follows the same style.

## Steps

- [x] **1. Read current WORKFLOW-GUIDE.md** to confirm insertion point (after "defuddle + markdown.new" section, before closing italic note at line 223)
- [x] **2. Write the new section** between the last `---` separator and the closing italic note. Content:
  - H3 heading: `Local API Dumps — MCP Acceleration`
  - One-sentence explanation of the pattern (dump → local read → targeted MCP calls)
  - Bold "Why:" — list benefits (fewer roundtrips, instant ID lookup, batch analysis)
  - Bold "Example:" — Storyblok dump with `npm run storyblok-dump`, showing output format (JSONL with summary header)
  - Bold "Pattern:" — generic 3-step workflow (1. dump, 2. read dump, 3. targeted MCP call)
  - Match existing section style: code blocks, bold labels, concise prose
- [x] **3. Verify** the file renders correctly (no broken markdown, proper heading hierarchy)

## Acceptance Criteria

- [x] New section appears in Advanced Techniques between "defuddle" and closing note
- [x] Section follows existing WORKFLOW-GUIDE style (h3, bold labels, code blocks)
- [x] Content is 15-20 lines, in English, no umlauts
- [x] Explains the generic pattern, not just the Storyblok-specific script
- [x] Storyblok shown as concrete example with `npm run storyblok-dump`
- [x] No other files modified

## Files to Modify

- `templates/claude/WORKFLOW-GUIDE.md` — insert new section

## Out of Scope

- The storyblok-dump script itself (separate spec)
- Auto-install logic for Storyblok projects (separate spec)
- Changes to README.md or other documentation files
