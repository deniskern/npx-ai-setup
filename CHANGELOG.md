# Changelog

All notable changes are recorded here automatically when specs are completed via `/spec-work`.

Format: grouped by version. New entries go under `## [Unreleased]` and are moved to a versioned heading when `/release` is run.

---

<!-- Entries are prepended below this line, newest first -->

## [Unreleased]

## [1.3.4] — 2026-03-15
- **Spec 094**: Circuit Breaker spec-aware — raises block threshold (8→20) when a spec is in-progress; prevents false positives during planned migrations

## [1.3.3] — 2026-03-15
- **Spec 093**: Fast --patch flag — sync specific template files without full update flow (e.g. `--patch spec-work`)
- **Spec 092**: spec-work low complexity executes directly — no subagent overhead for simple specs; subagents only for medium (Sonnet) and high (Opus)
- **Spec 091**: Complexity-based Model Routing in spec-work — Haiku/Sonnet/Opus automatically selected for implementation based on `**Complexity**` field; Opus sets the field when creating specs
- **Spec 090**: Validation Gate in spec-work — spec-work now scores specs on 10 criteria before executing; blocks weak specs with actionable feedback
- **Spec 089**: Personal Config Token Optimization — MEMORY.md deduplicated, unused skills archived, context7 duplicate removed, global BASH_MAX_OUTPUT_LENGTH and MAX_MCP_OUTPUT_TOKENS set
- **Spec 088**: Template Token Optimization — BASH_MAX_OUTPUT_LENGTH added to template settings, agents.md dispatch table extracted to docs/, CLAUDE.md Context Management trimmed

## [Unreleased]

- **Spec 087**: Token Optimization: Config and Template Cleanup — reduced per-session token overhead by removing duplicate rules, trimming CLAUDE.md, scoping rules files with paths: frontmatter, capping MCP output, and fixing skill descriptions.
- **fix**: Remove autocompactBuffer from powerline config — reclaims ~20% context per session.
- **fix**: Remove ineffective paths: scoping from git.md and agents.md — both load unconditionally as intended.
- **fix**: Register context-monitor.sh as PostToolUse hook (was installed but never executed).
- **fix**: AUTOCOMPACT threshold 70% → 80%, aligns with /compact guidance and buffer removal.
- **fix**: circuit-breaker whitelist for specs/*.md and HANDOFF.md; fix substring count bug.
- **fix**: update command PRE_UPDATE_SHA via temp file (bash vars don't persist between blocks).
- **fix**: Remove empty claude-mem-context tag from template CLAUDE.md.
- **fix**: Default model opusplan → sonnet in template settings (Opus reserved for /spec creation).

## [v1.3.2] — 2026-03-13

### Spec Quality & Execution Improvements (Specs 081–086)

Six improvements to the spec-driven workflow, porting patterns from GSD-2 evaluation.

**Understanding Confirmation (Spec 081)**
`spec-work` now shows a 3-bullet summary (Goal, Approach, Files) and asks for confirmation before creating a branch for `Complexity: high` specs — preventing wasted execution on misunderstood specs.

**Decisions Register (Spec 082)**
New `decisions.md` template installed at project root — an append-only table for tracking architectural decisions across sessions. `spec-work` prompts to append decisions after meaningful steps; `reflect` appends architectural signals automatically. `CLAUDE.md` instructs reading it before planning.

**Structured Verification (Spec 083)**
Acceptance criteria in spec templates now use three checkable categories: **Truths** (observable behaviors), **Artifacts** (files with real implementation), **Key Links** (imports/wiring between files). `spec-review` and `verify-app` verify each category mechanically.

**Debugging Discipline (Spec 084)**
New 6-point debugging methodology added to `bug.md` and `spec-work` verification failure path: hypothesis first, one variable at a time, read completely, distinguish know vs. assume, stop after 3 failed fixes, don't fix symptoms.

**Context Budget Awareness (Spec 085)**
`CLAUDE.md` Context Management section now includes a context budget rule: when context is running low, stop implementing and prioritize writing a handoff. `spec-work` execution loop adds the same reminder at step level.

**Challenge & Evaluate in Templates (Spec 086)**
`challenge.md` and `evaluate.md` added to `templates/commands/` so all projects installed via `npx @onedot/ai-setup` receive them. Both generalized: challenge reads `.agents/context/CONCEPT.md` for project principles; evaluate scans `.claude/` and `templates/` (whichever exist) instead of hardcoded paths.

## [v1.3.1] — 2026-03-11

### Skill-First Principle (Spec 078 + 079)
Claude now discovers installed skills before implementing anything manually — spec creation scans `.claude/skills/`, references matching skills as `/skill-name` in steps, and spec-work invokes them via the Skill tool instead of reimplementing. A `Skill-First` rule was added to `rules/general.md` (templates + active copy), `templates/CLAUDE.md` Working Style, and agent definitions (code-reviewer, verify-app).

### Fix: PreCompact Auto-Commit (Issue #3)
The auto-save hook on context compaction now stages only tracked modified files (`git add -u` instead of `git add -A`) and uses a proper conventional commit message (`chore: save session state before context compaction`). The `--no-verify` flag that bypassed hooks was removed.

### Fix: Silent Sandbox Bypass Prevention (Issue #4)
A new `## Sandbox Safety` rule in `rules/general.md` explicitly prohibits using `dangerouslyDisableSandbox: true` without first explaining the restriction to the user and receiving explicit confirmation. Silent retries with sandbox disabled are not allowed.

### Fix: Silent Early Exit in Setup Script (Issue #3 related)
`_install_or_update_file` now returns `0` (not `1`) for skip and user-modified cases, preventing `set -e` from killing the script mid-loop during `install_rules` and TypeScript detection.

## [v1.3.0] — 2026-03-10

- **Spec 076**: /simplify in spec-work + Advanced Tools — added optional `/simplify` cleanup step to spec-work between verify-app and code-reviewer; added Web Fetching rule preferring defuddle and markdown.new over WebFetch; documented ralph-loop and defuddle/markdown.new in WORKFLOW-GUIDE.md Advanced Techniques section.

- **Spec 073**: Generation reliability and install coverage — raised Claude generation turn budgets, added single-retry fallbacks for no-op or partial outputs, and added an offline integration test that verifies installed command templates on a fresh setup.

- **Spec 075**: Replace Statusline with claude-powerline — `install_statusline_project()` now wires `@owloops/claude-powerline` via npx with a dark powerline theme and copies a default `.claude/claude-powerline.json` config; the custom `statusline.sh` script is removed.

- **Spec 074**: Multi-Tool Skills Symlinks — skills installed in `.claude/skills/` are now automatically linked to `.codex/skills` and `.opencode/skills` when the respective CLIs are installed, enabling all three tools to share the same skill library without duplication.

### Developer Workflow Guide (Spec 071)
New developers know exactly what to do right after setup — no documentation digging required. Every install now drops `.claude/WORKFLOW-GUIDE.md` with a Quick Start, the full spec workflow, all 20 slash commands with examples, a subagent and hook overview, and a troubleshooting section.
*Technical: `templates/claude/WORKFLOW-GUIDE.md` → `_install_or_update_file` → `.claude/WORKFLOW-GUIDE.md`; checksum logic preserves user edits; not referenced in CLAUDE.md (zero token cost); tip in `templates/CLAUDE.md` points developers to the file.*

### Spec Workflow: Crash Resilience and Self-Healing (Spec 072)
Specs interrupted mid-execution (context compaction, crashes) can now resume seamlessly — no work lost. `/spec-work` detects already-completed steps and skips them automatically. Each completed step is committed immediately, so re-running picks up exactly where it left off. `/spec-board` detects inconsistent states (steps done but status still `in-progress`) and offers to fix them in one confirmation. `/spec` auto-splits oversized or mixed-layer tasks into separate specs before execution.
*Technical: `spec-work` — resume check at step 9 (scans `- [x]`), per-step commit `spec(NNN): step N`, status set to `in-review` before code-reviewer agent. `spec-board` — removed `mode: plan`, added `Write, Edit, AskUserQuestion`, Step 6 Consistency Check (Type A: stale in-progress, Type B: completed but not moved). `spec-work-all` — explicit blocked fallback when subagent fails or returns no result. `spec` — auto-split on >60 lines / >8 steps / mixed architectural layers.*

### Faster, More Reliable Commands and Subagents
Commands now pre-load git context before execution — no extra tool-call round-trips. Subagents run with stricter turn limits and remember project conventions across invocations.
*Technical: All commands migrated from `Task` → `Agent`; added `argument-hint`, `disable-model-invocation`, and inline `Context` blocks with `!git` prefetching (commit, pr, review, spec-work). Agents: `max_turns` for build-validator (10), context-refresher (15), verify-app (20), staff-reviewer (20); `memory: project` for code-reviewer and staff-reviewer. context-refresher: optional repomix snapshot step (best-effort, silent on failure).*

### Stricter Quality Gates: /spec-review and /grill
Specs are now scored on 10 measurable metrics — a clear pass/fail system instead of subjective judgment. Code reviews check for duplicate logic before flagging issues and verify every finding against an exact file and line number.
*Technical: `spec-review` — 10-metric scoring (0–100, threshold 85 avg / 70 min), Definition-of-Done gate from CONVENTIONS.md, file-read cap (5 files). `grill` — Scope Challenge step 0 with A/B/C choice, Grep pass before flagging, A/B/C resolution options per issue, NOT-reviewed exclusions list, self-verification table as final step.*

### /reflect: Capture More from Every Session
`/reflect` now captures architectural discoveries and stack decisions — not just corrections. Less knowledge lost between sessions.
*Technical: New signal categories ARCHITECTURAL and STACK; writes to `ARCHITECTURE.md` and `STACK.md` in addition to `CLAUDE.md` and `CONVENTIONS.md`.*

### New Monitoring Hooks and Coding Rules
Five new hooks automatically monitor config changes, MCP health, and failed tool calls. Four rule files document coding standards, git conventions, testing requirements, and agent delegation — always available in every session.
*Technical: config-change-audit.sh, context-monitor.sh, mcp-health.sh, post-tool-failure-log.sh, task-completed-gate.sh. Rules: agents.md, general.md, git.md, testing.md in `.claude/rules/`. liquid-linter agent added.*

### /spec-validate and /update
Specs can be quality-checked before execution with a 10-metric score. The ai-setup system can now be updated from within Claude Code — no terminal switch needed.
*Technical: `/spec-validate` and `/update` installed from templates.*

### Automated GitHub Releases
GitHub Releases are now automatically populated with the matching CHANGELOG section when a version tag is pushed.
*Technical: Note added to `release` command — `.github/workflows/release-from-changelog.yml` catches `vX.Y.Z` tags and populates the release body from `CHANGELOG.md`.*

## [v1.2.8] — 2026-03-09

### Smarter Agent Skill Injection
Agents installed by ai-setup now automatically receive the right skills for the detected project type — Shopify, Shopware, or generic. No manual configuration needed.
*Technical: Installer injects `skills:` into agent YAML headers post-copy based on detected system — Shopify agents get `shopify-liquid`/`shopify-theme-dev`, Shopware agents get `shopware6-best-practices`, `test-generator` gets `vitest` when available. Idempotent; skips if already present.*

### Agent Delegation Rules
A new rules file tells Claude exactly when to delegate to which agent — and when not to. Prevents over-delegation and keeps simple tasks fast.
*Technical: New `templates/claude/rules/agents.md` with trigger-condition table for all 9 agents, scope limits, and anti-patterns.*

### Spec Backlog Cleanup
The backlog went from 11 specs to zero — dead weight removed, good ideas documented.
*Technical: Deleted 10 obsolete/redundant specs, consolidated 4 documentation specs into #069, added `BACKLOG.md` with rejected ideas and evaluation items.*

### Token Savings: ~11% Context Reduction
Claude starts each session with ~2,600 fewer tokens consumed by templates — leaving more room for actual work.
*Technical: Compressed `spec.md` Phase 1e (30 lines → 5-line checklist), deduplicated 4 identical example blocks in `reflect.md`, consolidated emit logic in `cross-repo-context.sh`, removed bash commentary in `update.md`, replaced spec-work duplication in `spec-work-all.md` with reference, removed AGENTS.md table duplication in hooks README.*

### Deadloop Prevention Hardening
Claude is less likely to get stuck in an edit loop — warnings are clearer, hooks use advisory language instead of commands.
*Technical: Circuit-breaker WARNING now says "DO NOT edit this file again"; context-monitor switched from imperative ("Commit current work") to advisory ("Consider saving state"); post-edit-lint.sh documents output suppression reason; hooks README adds deadloop prevention notes.*

## [v1.2.7] — 2026-03-06

### Reliable GitHub Releases
Releases no longer fail silently when tag events arrive late — a fallback trigger ensures the release notes always get created.
*Technical: `release-from-changelog` now supports `create` tag events as fallback for delayed push events; release docs and command include manual workflow trigger backup.*

### Automatic CodeRabbit Integration
CodeRabbit code review is installed and activated automatically — teams get AI-assisted PR reviews out of the box.
*Technical: Auto-registers `coderabbitai/claude-plugin` in `extraKnownMarketplaces` + `enabledPlugins`; CLI install with fallback (`claude-plugin@coderabbitai` / `coderabbitai/claude-plugin`); summary and README coverage added.*

### Always-Visible Update Notifications
Developers are informed of available ai-setup updates at session start and on every prompt — no more stale installs going unnoticed.
*Technical: `update-check` now runs on `SessionStart` and `UserPromptSubmit`; version source fallback chain (npm → GitHub Release → GitHub Tag); CLI update notice and statusline badge `ai-setup vX → vY`.*

### Cross-Repo Context for Multi-Repo Projects
Claude now automatically loads context from sibling repositories — useful for monorepos and multi-service setups.
*Technical: New `cross-repo-context` SessionStart hook with preferred `.agents/context/repo-group.json` map and optional Shopware naming fallback. Multi-repo setup wizard creates the map via interactive parent-directory discovery.*

## [v1.2.6] — 2026-03-06

### Commands Use the Correct Tool API
All command templates and documentation updated to current Claude Code semantics — `Agent` instead of the deprecated `Task` tool. Subagent calls now work reliably.
*Technical: Migrated all command templates and docs from `Task` → `Agent` wording.*

### More Hooks Out of the Box
Three new hook types are installed automatically — catching tool failures, config changes, and task completion. Teams get observability without manual setup.
*Technical: Added `PostToolUseFailure` logging, `ConfigChange` auditing guard, and `TaskCompleted` gate hook templates with settings wiring.*

### Faster Statusline
The statusline updates more efficiently and no longer causes delays in large repos.
*Technical: Switched to workspace JSON fields, added lightweight git caching, standardized `statusLine` settings (`type: command`, `padding`).*

### Safer Shopify and Shopware Detection
Project type detection is more accurate and credentials are never written into shared config files.
*Technical: Improved Shopware/Shopify auto-detection signals, local Shopware skill fallback, hardened Shopware MCP setup to avoid writing credentials into `.mcp.json`.*

### Smarter Setup Runs
Re-running the setup is faster — expensive steps are skipped when nothing changed.
*Technical: Skipped context regeneration in skills-only runs; deduplicated skill installs.*

## [v1.2.5] — 2026-03-05

- **Spec 054**: Bang-Syntax Context Injection — `## Context` sections with `!git` commands in commit, review, pr commands eliminate 2-3 tool-call round-trips for context gathering
- **Spec 053**: Context Monitor Hook — PostToolUse hook warns agent at <=35% (WARNING) and <=25% (CRITICAL) remaining context via statusline bridge file and `additionalContext` injection
- **Spec 052**: Agent Delegation Rules — new `rules/agents.md` template with trigger/scope/model guidance for all 8 agents and anti-patterns to prevent over-delegation
- **Spec 051**: PreCompact Hook — prompt-type hook in `settings.json` that auto-instructs Claude to commit or write HANDOFF.md before context compaction
- **Spec 050**: Post-Edit Hooks — `post-edit-lint.sh` extended with `tsc --noEmit` type-check (TS files, blocking) and `console.log` warning (non-blocking stderr)
- **Spec 049**: /evaluate command — project-local command for systematic evaluation of external ideas against existing template inventory
- **Slack-ready releases**: Added `release-from-changelog.yml` workflow to create/update GitHub releases from `CHANGELOG.md` on pushed `v*` tags
- **Template rollout**: Added workflow template under `templates/github/workflows/` so generated projects get the same release-note automation by default
- **Installer hardening**: `install_copilot()` now installs all files under `templates/github/` recursively, not only `copilot-instructions.md`
- **Release docs/command updates**: README and `/release` command now document the automatic changelog-to-Slack release flow

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

- **Spec 018**: Native worktree rewrite — replaced manual `git worktree add/remove` in spec-work-all with Claude Code's native `Agent(isolation: "worktree")`; subagent now handles .env copy, dep install, and branch rename

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
