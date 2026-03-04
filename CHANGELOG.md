# Changelog

All notable changes are recorded here automatically when specs are completed via `/spec-work`.

Format: grouped by version. New entries go under `## [Unreleased]` and are moved to a versioned heading when `/release` is run.

---

<!-- Entries are prepended below this line, newest first -->

## [v1.2.4] — 2026-03-04

- **Mandatory plugins**: Context7, claude-mem, and all official plugins (code-review, feature-dev, frontend-design) now install automatically without prompts
- **Removed Playwright & GSD**: Playwright MCP removed from setup; GSD moved to README as optional extension
- **Token optimization**: 15 new deny patterns (lock files, cache dirs, minified assets, source maps), `plansDirectory` and `enableAllProjectMcpServers` settings added
- **Session tips**: CLAUDE.md template now includes `Esc Esc` rewind, `/rename`+`/resume`, commit-checkpoint advice
- **Reflect routing**: `/reflect` now routes architectural discoveries to ARCHITECTURE.md and stack decisions to STACK.md
- **Haiku routing rule**: New rule ensures Explore subagents always use haiku model (60x cost reduction)

## [v1.2.3] — 2026-03-02

- **OpenCode compatibility**: `generate_opencode_config()` generates `opencode.json` from `.claude/agents/`, `.claude/commands/`, and `.mcp.json` — translates model tiers, tool permissions, and MCP servers for OpenCode CLI compatibility
- **Haiku model routing**: Downgraded 4 mechanical commands/agents from sonnet to haiku — `commit.md`, `pr.md`, `spec-board.md`, `context-refresher.md` — reduces token cost for high-frequency low-complexity tasks
- **Agent/command sync**: Added missing `perf-reviewer.md`, `test-generator.md` agents and `analyze.md`, `context-full.md`, `reflect.md`, `release.md`, `spec-board.md` commands to project

## [v1.2.2] — 2026-03-01

- **MCP Health Hook**: `mcp-health.sh` SessionStart hook — validates `.mcp.json` JSON syntax, required fields per server type (`url` for http/sse, `command` for stdio), and base command availability via `command -v`; silent on success, warnings to stderr

## [Unreleased]
- **Spec 054**: Bang-Syntax Context Injection — `## Context` sections with `!git` commands in commit, review, pr commands eliminate 2-3 tool-call round-trips for context gathering
- **Spec 053**: Context Monitor Hook — PostToolUse hook warns agent at <=35% (WARNING) and <=25% (CRITICAL) remaining context via statusline bridge file and `additionalContext` injection
- **Spec 052**: Agent Delegation Rules — new `rules/agents.md` template with trigger/scope/model guidance for all 8 agents and anti-patterns to prevent over-delegation
- **Spec 051**: PreCompact Hook — prompt-type hook in `settings.json` that auto-instructs Claude to commit or write HANDOFF.md before context compaction
- **Spec 050**: Post-Edit Hooks — `post-edit-lint.sh` extended with `tsc --noEmit` type-check (TS files, blocking) and `console.log` warning (non-blocking stderr)

## [Unreleased]

- **Spec 049**: /evaluate command — project-local command for systematic evaluation of external ideas against existing template inventory

## [v1.2.1] — 2026-02-28

- **Spec 047**: Settings + hooks + agent memory — SessionStart hook, AUTOCOMPACT=30, ENABLE_TOOL_SEARCH, PostToolUse failure log, Stop quality gate, agent memory:project + isolation:worktree fields
- **Spec 046**: Statusline global install — optional `~/.claude/statusline.sh` setup with color-coded context bar, model, cost, and git branch display
- **Spec 045**: /grill enhancements — scope challenge step, A/B/C options format, "What already exists" + "NOT reviewed" sections, self-verification table
- **Spec 044**: .claude/rules/ template expansion — testing.md, git.md, typescript.md (conditional), opusplan model, CLAUDE.md memory + tips sections
- **Review fixes**: find precedence bug in TS detection, TS metadata tracking, statusline null-safety + jq guard, SessionStart matcher, idempotent statusline prompt

## [v1.2.0] — 2026-02-27

- **Update UX**: per-file [y/N] prompt before overwriting user-modified files; Update files option available without version change
- **Spec 043**: Self-Improvement Reflect System — new /reflect command detects session corrections and writes them as permanent CLAUDE.md/CONVENTIONS.md rules with user approval
- **Spec 042**: Feedback Loop Patterns — techdebt.md now verifies changes via verify-app, spec-work.md has progress checklist, test.md has explicit attempt tracking
- **Spec 041**: Skill Descriptions Best Practices — all 15 command descriptions now follow "what + when" format in third person, under 120 chars
- **Spec 040**: README & CHANGELOG sync — fix counts (15 cmds/8 agents/6 hooks), compact sections, /release validates all counts
- **Spec 039**: Claude-Mem as team standard — default Y, `<claude-mem-context>` in CLAUDE.md, documents as required plugin
- **Spec 038**: Global Definition of Done — DoD in CONVENTIONS.md, build-artifact rules, /spec-review DoD validation
- **Spec 037**: Claude Code best practices — SKILL.md frontmatter, disable-model-invocation, enriched settings.json, notify.sh
- **Spec 036**: Bash performance — parallel skills search/install, 8-job curl pool, parameter expansion (100+ second runtime reduction)
- **Spec 035**: /analyze command — 3 parallel Explore agents produce architecture/hotspots/risks overview
- **Spec 034**: /bug multi-agent verification — verify-app auto-runs after fix, code-reviewer after verification passes
- **Spec 033**: /pr + /review improvements — build-validator in /pr pipeline, /review covers full branch diff
- **Spec 032**: Local skill templates — bundles tailwind, pinia, drizzle, tanstack, vitest; skips slow skills.sh search
- **Spec 031**: CLAUDE.md generation timeout fix — 120s→180s, correct "timed out" error message
- **Spec 030**: Granular update regeneration — missing context detection, checkbox UI instead of binary prompt

## [v1.1.6] — 2026-02-24

- **Spec 029**: Add perf-reviewer and test-generator agent templates — two new universal agents for performance analysis (read-only, FAST/CONCERNS/SLOW verdict) and test generation (write-guarded to test directories only)
- **Spec 028**: Fully automatic agent integration — `verify-app` auto-runs after spec implementation (blocks code-reviewer on FAIL), `staff-reviewer` auto-runs in `/pr` before draft
- **Spec 027**: Add code-architect agent — new opus agent for architectural assessment, auto-spawned by `spec-work` when spec has `**Complexity**: high`
- **Spec 026**: Add code-reviewer Agent — new reusable `code-reviewer` agent (sonnet) wired automatically into `spec-work` and `spec-review`, replacing inline review logic
- **Spec 025**: Add .claude/rules/general.md template + agent max_turns — installs a universal coding safety rules file and caps agent turn counts as a cost guard
- **Spec 024**: Smoke Test for bin/ai-setup.sh — added tests/smoke.sh and npm test script for syntax and function-presence checks
- **Spec 023**: Fix git add -A in Worktree Prompt — replaced git add -A with git add -u in spec-work-all subagent commit step
- **Spec 022**: Deduplicate Auto-Review Logic — removed duplicated review criteria from spec-work.md auto-review step, replaced with compact summary referencing `/spec-review` for full criteria
- **Spec 021**: /release command and git tagging — added `/release` slash command template, reformatted CHANGELOG with `[Unreleased]` + versioned headings, updated `/spec-work` to target `[Unreleased]`, backfilled git tags v1.1.0–v1.1.4, bumped version to 1.1.5

## [v1.1.4] — 2026-02-23

- **Spec 020**: Granular template update selector — smart update now shows a 5-category checkbox UI (Hooks, Settings, Commands, Agents, Other) before processing templates, so users can update only the categories they want

- **Spec 019**: Shopify templates moved to skills — relocated 8 Shopify knowledge templates from `templates/commands/shopify/` to `templates/skills/shopify-*/prompt.md`, updated all install/update/uninstall references to target `.claude/skills/`, removed redundant `dragnoir/Shopify-agent-skills` marketplace entries

## [v1.1.3] — 2026-02-23

- **Spec 018**: Native worktree rewrite — replaced manual `git worktree add/remove` in spec-work-all with Claude Code's native `Task(isolation: "worktree")`; subagent now handles .env copy, dep install, and branch rename

- **Spec 016**: Worktree env and deps — `spec-work-all` now auto-copies `.env*` files and runs dependency install (bun/npm/pnpm/yarn) into each worktree before launching agents; failures are warnings, not blockers

## [v1.1.2] — 2026-02-22

- **Spec 015**: Spec workflow branch and review improvements — `/spec-work` now prompts for branch creation before starting and offers auto-review with corrections after execution; `/spec-review` APPROVED verdict no longer suggests PR commands

- **Spec 014**: Skills Discovery Section — added `## Skills Discovery` to `templates/CLAUDE.md` so Claude can search and install skills on demand using `npx skills find` and `npx skills add`

- **feat**: Mini-VibeKanban spec workflow — full status lifecycle (`draft` → `in-progress` → `in-review` → `completed` / `blocked`), `/spec-board` Kanban overview with step progress, `/spec-review NNN` Opus-powered review with PR drafting, `/spec-work-all` rewritten to use Git worktrees for isolated parallel execution, `/spec-work` updated with status transitions

- **Spec 013**: Dynamic Template Map — replaced hardcoded TEMPLATE_MAP array and install loops with dynamic generation from `templates/` directory

- **feat**: `/spec` challenge phase deepened — now thinks through implementation before verdict, mirrors plan mode
- **feat**: `/spec` challenge uses `AskUserQuestion` at decision points during analysis
- **feat**: `/spec` and `/spec-work` auto-load relevant installed skills from `.claude/skills/`
- **feat**: `update-check.sh` hook — notifies at session start when a new `@onedot/ai-setup` version is available
- **fix**: Circuit breaker auto-resets when user sends next message

## [v1.1.1] — 2026-02-21

- **Spec 012**: /bug command — added `/bug` slash command template with structured reproduce → root cause → fix → verify workflow

## [v1.1.0] — 2026-02-21

- **feat**: Merge `/challenge` into `/spec` — spec now challenges the idea first (GO/SIMPLIFY/REJECT verdict) before writing the spec; `/challenge` command removed
- **feat**: Interactive checkbox selector for regeneration — replaces y/N prompt with arrow+space UI; 4 options: CLAUDE.md, Context, Commands, Skills
- **feat**: Split regeneration Skills into Commands (internal slash commands/agents) and Skills (external skills.sh)
- **fix**: Replace full model IDs with short aliases (`sonnet`) in all command/agent frontmatter — fixes IDE validation errors
- **docs**: Add ccusage to README as recommended tool for session token usage analysis
- **Spec 011**: Bulk Spec Execution via Agents — adds `/spec-work-all` slash command for parallel spec execution via subagents
- **feat**: Add `/challenge` command to `templates/commands/`
- **feat**: Expand system skill sets with verified skills — Nuxt adds vue+vueuse, Shopify adds shopify-theme-dev, Next.js adds nextjs-app-router-patterns, Laravel adds eloquent-best-practices
- **fix**: Add skills.sh registry pre-check in `install_skill()` — invalid skills skipped with warning
- **feat**: Add Next.js/React system option with auto-detection and skill routing
- **Spec 010**: Aura Frog Quality Patterns — Added Task Complexity Routing, dual-condition verification gate, and conditional TDD enforcement to `templates/CLAUDE.md`
- **Spec 009**: Auto-Detect System from Codebase Signals — Added `detect_system()` to resolve `--system auto`
- **Spec 008**: Feature Challenge Skill — Added `.claude/commands/challenge.md` with GO/SIMPLIFY/REJECT decision
- **Spec 007**: Deny list security hardening — Added `git clean`, `git checkout --`, `git restore` to deny list
- **Spec (untracked)**: Context-Refresher Subagent + Auto-Trigger
- **Spec (untracked)**: Project Concept Documentation — Added `docs/` with CONCEPT.md, ARCHITECTURE.md, DESIGN-DECISIONS.md
- **Spec 007**: Auto-Updated CHANGELOG.md on Spec Completion
