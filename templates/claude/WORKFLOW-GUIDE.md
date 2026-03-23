# Claude Code — Developer Workflow Guide

Quick reference for the AI-assisted development workflow installed by `@onedot/ai-setup`.

---

## Quick Start

```bash
claude                # open Claude Code in your project
/spec-board           # see all active specs
/doctor               # verify setup health
```

---

## Onboarding

Run once when joining a new codebase or before starting a major initiative.

| Command | Description |
|---------|-------------|
| `/explore "topic"` | Read-only thinking partner — map codebase, surface tradeoffs, draw ASCII diagrams; never writes files (contrast: `/challenge` evaluates a specific idea with GO/SIMPLIFY/REJECT verdict) |
| `/analyze` | Codebase overview via 3 parallel agents — produces PATTERNS.md and AUDIT.md |
| `/discover` | Reverse-engineer draft specs from existing code |
| `/evaluate "tool"` | Deep-evaluate an external tool or pattern against the project |

---

## Development Cycle

The standard cycle for any task larger than a single-file fix.

```
/spec "task description"       # challenge idea, create structured spec
/spec-validate NNN             # score spec quality before executing
/spec-work NNN                 # execute step by step, commit after each step
/test                          # run tests + fix failures (up to 3 attempts)
/review                        # review uncommitted changes
/commit                        # stage + conventional commit message
/pr                            # build validation + staff review + PR draft
/release                       # bump version, update CHANGELOG, tag
```

**Spec lifecycle:** `draft` → `in-progress` → `in-review` → `completed`

Parallel execution: `/spec-work-all` runs all draft specs in isolated Git worktrees.

### All Development Commands

| Command | Description |
|---------|-------------|
| `/spec "task"` | Challenge idea first, then create structured spec |
| `/spec-work NNN` | Execute spec step by step with auto-verification |
| `/spec-work-all` | Execute all draft specs in parallel (isolated worktrees) |
| `/spec-review NNN` | Review against acceptance criteria + finishing gate |
| `/spec-validate NNN` | Score spec quality before executing |
| `/spec-board` | Kanban board of all specs |
| `/debug "description"` | Hypothesis-first bug investigation |
| `/build-fix` | Incremental build-error fixer (max 10 iterations) |
| `/test` | Run tests + fix failures (up to 3 attempts) |
| `/lint` | Run linter, auto-fix safe violations |
| `/review` | Review uncommitted changes (Quick Scan / Standard / Adversarial) |
| `/scan` | Security vulnerability scan (snyk/npm audit/pip-audit) |
| `/techdebt` | End-of-session sweep — dead code, unused imports |
| `/explore "topic"` | Read-only thinking partner — explore tradeoffs, map codebase, surface surprises (no file writes) |
| `/challenge "idea"` | Critically evaluate a feature idea before building (GO/SIMPLIFY/REJECT verdict) |
| `/commit` | Stage changes + conventional commit message |
| `/pr` | Build validation + staff review + PR draft |
| `/ci` | Check CI status via gh pr checks / gh run list, suggests next step |
| `/release` | Bump version, update CHANGELOG, tag release |

---

## Hotfix Flow

For production bugs that bypass the normal spec cycle.

```
/debug "symptom"               # isolate root cause with hypothesis-first approach
/test                          # verify fix with tests
/commit                        # conventional commit: fix(scope): description
/pr                            # fast-track PR with minimal review
```

No spec required for hotfixes — `/debug` output serves as the investigation record.

---

## Session & Maintenance

| Command | Description |
|---------|-------------|
| `/pause` | Capture session state, commit WIP checkpoint |
| `/resume` | Restore state, route to next action |
| `/reflect` | Save session learnings as permanent rules |
| `/doctor` | AI setup health check (hooks, settings, context, MCP) |
| `/update` | Check for ai-setup updates and install |

```
/pause                         # save state to .continue-here.md, commit WIP
/resume                        # restore state, route to next action
/reflect                       # capture learnings as permanent rules
```

---

## Subagents (12)

Spawned automatically during `/spec-work`, `/pr`, `/debug`. Also invocable directly.

| Agent | Purpose | Model |
|-------|---------|-------|
| `verify-app` | Run tests + build, report PASS/FAIL | sonnet |
| `build-validator` | Quick build check | haiku |
| `code-reviewer` | HIGH/MEDIUM confidence review (>80% threshold) | sonnet |
| `code-architect` | Architectural assessment before implementation | opus |
| `staff-reviewer` | Skeptical staff engineer review | opus |
| `security-reviewer` | OWASP Top 10, secrets detection, pattern table | sonnet |
| `perf-reviewer` | Performance analysis — FAST/CONCERNS/SLOW | sonnet |
| `test-generator` | Generate missing tests for changed files | sonnet |
| `context-refresher` | Regenerate `.agents/context/` files | haiku |
| `frontend-developer` | React, Vue, Nuxt, Next.js specialist | sonnet |
| `/analyze` | Produce PATTERNS.md and AUDIT.md | sonnet |
| `liquid-linter` | Validate Shopify Liquid templates | haiku |

---

## Hooks (14)

Run automatically — no manual invocation needed.

| Hook | Trigger | What it does |
|------|---------|-------------|
| `circuit-breaker` | PreToolUse | Stops infinite edit loops (3 edits same file) |
| `protect-files` | PreToolUse | Blocks edits to build output and lock files |
| `post-edit-lint` | PostToolUse | Runs linter after edits (when available) |
| `context-monitor` | PostToolUse | Warns at ≤35% context (WARNING) and ≤25% (CRITICAL) |
| `context-freshness` | UserPromptSubmit | Warns when context files are >7 days old |
| `context-reinforcement` | SessionStart | Re-injects critical rules after compaction |
| `update-check` | UserPromptSubmit | Checks for ai-setup updates |
| `mcp-health` | SessionStart | Validates MCP server health |
| `config-change-audit` | ConfigChange | Audits changes to settings files |
| `task-completed-gate` | TaskCompleted | Verification gate before marking tasks done |
| `notify` | Stop | Cross-platform notification on completion |
| `cli-health` | SessionStart | Validates CLI tool availability (rtk, gh, jq) |
| `post-tool-failure-log` | PostToolUseFailure | Logs tool failures for debugging |

---

## Context Files

Located in `.agents/context/` — auto-generated, committed, shared across team.

| File | Content |
|------|---------|
| `STACK.md` | Tech stack, versions, key dependencies |
| `ARCHITECTURE.md` | System architecture and data flows |
| `CONVENTIONS.md` | Naming patterns, coding standards, testing |
| `PATTERNS.md` | Established patterns to reuse (via `/analyze`) |
| `AUDIT.md` | Improvement opportunities (via `/analyze`) |

Regenerate: re-run `npx @onedot/ai-setup` → choose **Regenerate** → select **Context**.

---

## Claude Code Tips

| Shortcut | What |
|----------|------|
| `Esc Esc` | Rewind last response (recover tokens) |
| `Up arrow` | After interrupt: restore prompt + rewind |
| `! git status` | Run bash command directly (no token overhead) |
| `@src/index.ts` | Import file into context compactly |
| `ultrathink:` | Prefix for extended reasoning |
| `/compact` | Compress context at 80% usage |

---

## Token-Efficient Web Fetching

Reading web pages with WebFetch returns raw HTML — ~5× more tokens than needed. Two better options:

| Method | Usage |
|--------|-------|
| **defuddle** (CLI) | `defuddle parse https://example.com --md` |
| **markdown.new** (URL prefix) | `https://markdown.new/https://example.com` |

Both strip navigation, ads, and clutter — ~80% token savings. Use WebFetch only when JavaScript rendering is required.

---

## Troubleshooting

**Claude keeps editing the same file in a loop?**
Circuit-breaker triggers after 3 edits. Stop, re-describe the problem differently.

**Context is stale after a long session?**
Use `Esc Esc` to compress, or `/pause` + start fresh session + `/resume`.

**Spec steps partially checked after a crash?**
Re-run `/spec-work NNN` — it detects `[x]` steps and resumes from the first unchecked.

**Build fails after spec-work?**
Run `/build-fix` — it parses the first error, applies a minimal fix, rebuilds, repeats.

**Can't find a command?**
Type `/` in Claude Code for autocomplete, or check `.claude/commands/`.

**Pre-commit hook fails in sandbox (Nuxt/Next.js)?**
Sandbox permissions are auto-adjusted per framework during setup. If hooks still fail
(e.g. `.env` access needed), commit manually: `! git commit -m "msg"`

**Update ai-setup:**
```
/update
```

---

*Installed by `@onedot/ai-setup`. Not loaded into context automatically — reference `.claude/WORKFLOW-GUIDE.md` when needed.*
