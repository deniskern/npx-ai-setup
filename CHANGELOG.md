# Changelog

All notable changes are recorded here automatically when specs are completed via `/spec-work`.

Format: grouped by version. New entries go under `## [Unreleased]` and are moved to a versioned heading when `/release` is run.

---

<!-- Entries are prepended below this line, newest first -->

## [Unreleased]

### Developer Workflow Guide (Spec 071)
Neue Entwickler wissen nach dem Setup sofort, was sie tun können — ohne die Dokumentation durchsuchen zu müssen. Die Datei `.claude/WORKFLOW-GUIDE.md` wird bei jedem Setup installiert und enthält: Quick Start, den vollständigen Spec-Workflow, alle 20 Slash-Commands mit Beispielen, eine Übersicht über Subagents und Hooks sowie eine Troubleshooting-Sektion.
*Technisch: Template `templates/claude/WORKFLOW-GUIDE.md` → `_install_or_update_file` → `.claude/WORKFLOW-GUIDE.md`; Checksum-Logik erhält Nutzer-Änderungen; kein Context-Load (keine Token-Kosten); Tipp in `templates/CLAUDE.md` zeigt Entwicklern den Einstiegspunkt.*

### Spec-Workflow: Crash-Resilience und Selbstheilung (Spec 072)
Specs die mitten in der Ausführung abbrechen (Context-Komprimierung, Abstürze) können jetzt nahtlos fortgesetzt werden — ohne verlorene Arbeit. `/spec-work` erkennt bereits abgehakte Schritte und überspringt sie automatisch. Jeder abgeschlossene Schritt wird sofort committed, sodass beim Neustart nichts verloren ist. `/spec-board` erkennt inkonsistente Zustände (Schritte fertig, Status noch `in-progress`) und bietet an, sie mit einem Klick zu bereinigen. `/spec` teilt zu große oder mehrschichtige Tasks automatisch in separate Specs auf.
*Technisch: `spec-work` — Resume-Check bei Schritt 9 (scannt `- [x]`), per-Step-Commit `spec(NNN): step N`, Status auf `in-review` vor code-reviewer. `spec-board` — YAML `mode: plan` entfernt, `Write, Edit, AskUserQuestion` hinzugefügt, Step 6 Consistency Check (Type A: stale in-progress, Type B: completed aber nicht verschoben). `spec-work-all` — expliziter Fallback bei fehlgeschlagenem Subagent → Status `blocked`. `spec` — auto-split bei >60 Zeilen / >8 Steps / mixed layers.*

### Robustere Commands und Subagents
Commands antworten schneller und präziser, weil Kontextdaten jetzt vorab geladen werden — ohne extra Tool-Calls. Subagents laufen zuverlässiger mit klar definierten Grenzen und erinnern sich an Projektkonventionen.
*Technisch: Alle Commands von `Task` → `Agent` migriert; `argument-hint`, `disable-model-invocation` und inline `Context`-Blöcke mit `!git`-Prefetching (commit, pr, review, spec-work). Agents: `max_turns` für build-validator (10), context-refresher (15), verify-app (20), staff-reviewer (20); `memory: project` für code-reviewer und staff-reviewer. context-refresher: optionaler Repomix-Snapshot (best-effort, silent).*

### Qualitätssicherung: /spec-review und /grill verschärft
Specs werden jetzt nach 10 messbaren Metriken bewertet — ein klares Ampelsystem statt subjektiver Einschätzung. Code-Reviews prüfen zuerst, ob ähnliche Logik bereits existiert, und validieren jeden Befund gegen eine konkrete Zeile im Code.
*Technisch: `spec-review` — 10-Metrik-Scoring (0–100, Schwelle 85 avg / 70 min), Definition-of-Done-Gate aus CONVENTIONS.md, Datei-Lesecap (5 Dateien). `grill` — Scope Challenge Step 0 mit A/B/C-Auswahl, Grep-Pass vor Flagging, A/B/C-Optionen pro Issue, NOT-reviewed-Ausschlussliste, Self-Verification-Table.*

### /reflect: Lernen aus der Session
`/reflect` erfasst jetzt auch Architektur-Entdeckungen und Stack-Entscheidungen aus der Session — nicht nur Korrekturen. Das bedeutet: weniger vergessenes Wissen zwischen Sessions.
*Technisch: Neue Signalkategorien ARCHITECTURAL und STACK; schreibt in `ARCHITECTURE.md` und `STACK.md` zusätzlich zu `CLAUDE.md` und `CONVENTIONS.md`.*

### Neue Monitoring-Hooks und Regeln
Fünf neue Hooks überwachen Config-Änderungen, MCP-Gesundheit und fehlgeschlagene Tool-Calls — und protokollieren sie automatisch. Vier Regeldateien dokumentieren Coding-Standards, Git-Konventionen, Testing-Anforderungen und Agent-Delegation.
*Technisch: config-change-audit.sh, context-monitor.sh, mcp-health.sh, post-tool-failure-log.sh, task-completed-gate.sh. Rules: agents.md, general.md, git.md, testing.md in `.claude/rules/`. liquid-linter Agent hinzugefügt.*

### /spec-validate und /update
Specs können jetzt vor der Ausführung auf Qualität geprüft werden — 10 Metriken, klares Scoring. Updates des ai-setup-Systems sind direkt aus Claude Code heraus möglich, ohne das Terminal zu verlassen.
*Technisch: `/spec-validate` und `/update` aus Templates installiert.*

### Release-Automation
GitHub Releases werden jetzt automatisch mit dem passenden CHANGELOG-Abschnitt befüllt, wenn ein Version-Tag gepusht wird.
*Technisch: Hinweis in `release`-Command, dass `.github/workflows/release-from-changelog.yml` das `vX.Y.Z`-Tag abfängt und den Release-Body aus `CHANGELOG.md` befüllt.*

## [v1.2.8] — 2026-03-09

- **Agent skill injection**: installer now injects `skills:` into agent YAML headers based on detected system — Shopify agents get `shopify-liquid`/`shopify-theme-dev`, Shopware agents get `shopware6-best-practices`, and `test-generator` gets `vitest` when available. Idempotent; skips if already present.
- **Agent delegation rules**: new `templates/claude/rules/agents.md` with trigger-condition table for all 9 agents, scope limits, and anti-patterns to prevent over-delegation.
- **Spec backlog cleanup**: pruned 11 backlog specs to 0 — deleted 10 obsolete/redundant specs, consolidated 4 documentation specs into #069, added `BACKLOG.md` with rejected ideas and evaluation items.
- **Template token optimization** (Spec 060): ~2,600 tokens (~11%) saved across 6 templates — compressed `spec.md` Phase 1e from 30 lines to 5-line checklist, deduplicated 4 identical example blocks in `reflect.md`, consolidated duplicated emit logic in `cross-repo-context.sh`, removed inline bash commentary in `update.md`, replaced spec-work duplication in `spec-work-all.md` with reference, removed AGENTS.md table duplication in hooks README.
- **Deadloop prevention hardening** (Spec 059): circuit-breaker WARNING now explicitly says "DO NOT edit this file again" (matches BLOCK tone), context-monitor switched from imperative directives ("Commit current work") to advisory language ("Consider saving state"), post-edit-lint.sh documents why all output is suppressed (deadloop prevention), hooks README adds dead-loop prevention notes section.

## [v1.2.7] — 2026-03-06

- **Release automation hardening**: `release-from-changelog` now supports `create` tag events as a fallback for delayed push events; release docs/command include a manual workflow trigger backup.
- **CodeRabbit plugin integration**: automatic registration of `coderabbitai/claude-plugin` in `extraKnownMarketplaces` + `enabledPlugins`, CLI install with fallback (`claude-plugin@coderabbitai` and `coderabbitai/claude-plugin`), plus installation summary and README coverage.
- **Update visibility improvements**: `update-check` now runs on `SessionStart` and `UserPromptSubmit`; version source fallback chain (`npm` -> GitHub Release -> GitHub Tag); added CLI update notice and statusline badge `ai-setup vX -> vY`.
- **Cross-repo context (framework-agnostic)**: new `cross-repo-context` SessionStart hook with preferred `.agents/context/repo-group.json` map and optional Shopware naming fallback.
- **Multi-repo setup wizard**: `ai-setup` now offers an interactive prompt to create `.agents/context/repo-group.json` with parent-directory repo discovery and module assignment.
- **Quality gates/tests**: smoke tests expanded for new functions and hook wiring (`show_cli_update_notice`, `setup_repo_group_context`, SessionStart hooks incl. `cross-repo-context`, and `repo-group.json` support).


## [v1.2.6] — 2026-03-06

- **Template modernization**: migrated command templates and docs from deprecated `Task` tool wording to `Agent` wording for current Claude Code semantics
- **Hooks expansion**: added `PostToolUseFailure` logging, `ConfigChange` auditing guard, and `TaskCompleted` gate hook templates with settings wiring
- **Statusline improvements**: switched to workspace JSON fields, added lightweight git caching, and standardized generated `statusLine` settings (`type: command`, `padding`)
- **Detection + safety**: improved Shopware/Shopify auto-detection signals, introduced local Shopware skill fallback, and hardened Shopware MCP setup to avoid writing credentials into `.mcp.json`
- **Setup efficiency**: skipped expensive context regeneration in skills-only runs and deduplicated skill installs
- **Quality gates**: added CI smoke workflow for PRs/main pushes and a tracked pre-push hook that runs `npm test`

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
