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

## Daily Workflow

### Small tasks (single file, config, typo)
Describe it directly. Claude handles it.

### Larger tasks (3+ files, new feature, architecture)
Use spec-driven development:

```
/spec "task description"       # challenge idea, then create structured spec
/spec-validate NNN             # validate quality before executing
/spec-work NNN                 # execute step by step, commit after each step
/spec-review NNN               # review against acceptance criteria, finish gate
/spec-board                    # Kanban overview of all specs
```

**Lifecycle:** `draft` → `in-progress` → `in-review` → `completed`

Parallel execution: `/spec-work-all` runs all draft specs in isolated Git worktrees.

### Session management
```
/pause                         # save state to .continue-here.md, commit WIP
/resume                        # restore state, route to next action
```

### After a task
```
/commit                        # conventional commit message
/reflect                       # capture learnings as permanent rules
```

---

## Commands (24)

### Spec Workflow
| Command | Description |
|---------|-------------|
| `/spec "task"` | Challenge idea first, then create structured spec |
| `/spec-work NNN` | Execute spec step by step with auto-verification |
| `/spec-work-all` | Execute all draft specs in parallel (isolated worktrees) |
| `/spec-review NNN` | Review against acceptance criteria + finishing gate |
| `/spec-validate NNN` | Score spec quality before executing |
| `/spec-board` | Kanban board of all specs |

### Development
| Command | Description |
|---------|-------------|
| `/debug "description"` | Hypothesis-first bug investigation |
| `/build-fix` | Incremental build-error fixer (max 10 iterations, max 5% change) |
| `/test` | Run tests + fix failures (up to 3 attempts) |
| `/analyze` | Codebase overview via 3 parallel agents |
| `/discover` | Reverse-engineer draft specs from existing code |

### Review & Quality
| Command | Description |
|---------|-------------|
| `/review` | Review uncommitted changes (Quick Scan / Standard / Adversarial Grill) |
| `/scan` | Security vulnerability scan (snyk/npm audit/pip-audit/bundler-audit) |
| `/techdebt` | End-of-session sweep — dead code, unused imports |

### Strategic
| Command | Description |
|---------|-------------|
| `/evaluate "tool"` | Deep-evaluate external tool/pattern against project |
| `/challenge "idea"` | Critically evaluate a feature idea before building |

### Git & Release
| Command | Description |
|---------|-------------|
| `/commit` | Stage changes + conventional commit message |
| `/pr` | Build validation + staff review + PR draft |
| `/release` | Bump version, update CHANGELOG, tag release |

### Session & Maintenance
| Command | Description |
|---------|-------------|
| `/pause` | Capture session state, commit WIP checkpoint |
| `/resume` | Restore state, route to next action |
| `/reflect` | Save session learnings as permanent rules |
| `/doctor` | AI setup health check (hooks, settings, context, MCP) |
| `/update` | Check for ai-setup updates and install |

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
| `project-auditor` | Produce PATTERNS.md and AUDIT.md | sonnet |
| `liquid-linter` | Validate Shopify Liquid templates | haiku |

---

## Hooks (13)

Run automatically — no manual invocation needed.

| Hook | Trigger | What it does |
|------|---------|-------------|
| `circuit-breaker` | PostToolUse | Stops infinite edit loops (3 edits same file) |
| `protect-files` | PreToolUse | Blocks edits to build output and lock files |
| `post-edit-lint` | PostToolUse | Runs linter after edits (when available) |
| `context-monitor` | PostToolUse | Warns at ≤35% context (WARNING) and ≤25% (CRITICAL) |
| `context-freshness` | SessionStart | Warns when context files are >7 days old |
| `context-reinforcement` | SessionStart | Re-injects critical rules after compaction |
| `cross-repo-context` | SessionStart | Loads sibling repo context from repo-group.json |
| `update-check` | SessionStart | Checks for ai-setup updates |
| `mcp-health` | SessionStart | Validates MCP server health |
| `config-change-audit` | PostToolUse | Audits changes to settings files |
| `task-completed-gate` | PostToolUse | Verification gate before marking tasks done |
| `notify` | Stop | Cross-platform notification on completion |
| `post-tool-failure-log` | PostToolUse | Logs tool failures for debugging |

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

**Update ai-setup:**
```
/update
```

---

*Installed by `@onedot/ai-setup`. Not loaded into context automatically — reference `.claude/WORKFLOW-GUIDE.md` when needed.*
