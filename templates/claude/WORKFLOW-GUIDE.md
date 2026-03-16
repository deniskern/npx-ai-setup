# Claude Code — Developer Workflow Guide

Quick reference for the AI-assisted development workflow installed by `@onedot/ai-setup`.

---

## Quick Start

```bash
# Open Claude Code in your project
claude

# Check what's available
/spec-board      # see all active specs
/analyze         # understand the codebase before making changes
```

---

## Daily Workflow

### 1. Before you start a task
- Check `.agents/context/STACK.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` for project context
- For small tasks (single file, typo, config tweak) → just describe it to Claude
- For larger tasks → create a spec first

### 2. Spec-driven development (3+ files, new features, architecture)

```
/spec "task description"       # Create a spec (Claude challenges and plans it)
/spec-validate NNN             # Validate quality before executing
/spec-work NNN                 # Execute the spec step by step
/spec-review NNN               # Review completed work, close or send back
/spec-board                    # See all specs and their status
```

**Spec lifecycle:** `draft` → `in-progress` → `in-review` → `completed`

Completed specs move to `specs/completed/`.

### 3. After a task
```
/commit          # Stage and write a conventional commit message
/reflect         # Capture learnings as permanent rules (run before ending session)
```

---

## Commands Reference

| Command | What it does | Example |
|---|---|---|
| `/spec` | Create a structured spec with challenge-first analysis | `/spec "add product filter to collection page"` |
| `/spec-validate` | Validate spec quality before executing (10-metric score) | `/spec-validate 043` |
| `/spec-work` | Execute a spec step by step with auto-verification | `/spec-work 043` |
| `/spec-work-all` | Execute all draft specs in parallel (isolated worktrees) | `/spec-work-all` |
| `/spec-review` | Review completed spec against acceptance criteria | `/spec-review 043` |
| `/spec-board` | Kanban board of all specs with status | `/spec-board` |
| `/analyze` | Codebase overview via 3 parallel agents | `/analyze` |
| `/review` | Review uncommitted changes for bugs and security issues | `/review` |
| `/commit` | Stage changes and write a conventional commit message | `/commit` |
| `/pr` | Build validation + staff review + PR draft | `/pr` |
| `/grill` | Adversarial review — blocks until all issues resolved | `/grill` |
| `/bug` | Investigate and fix a bug with root-cause analysis | `/bug "cart count wrong after variant change"` |
| `/test` | Run project test suite and fix failures | `/test` |
| `/release` | Bump version, update CHANGELOG, tag release | `/release` |
| `/reflect` | Save session learnings as permanent rules | `/reflect` |
| `/techdebt` | Scan recently changed files for tech debt | `/techdebt` |
| `/context` | Show context usage, identify bloat, get optimization tips | `/context` |
| `/context-full` | Generate full codebase snapshot via repomix | `/context-full` |
| `/evaluate` | Evaluate external idea/tool/pattern against project | `/evaluate "use Zustand instead of Pinia"` |
| `/challenge` | Critically evaluate a feature idea before building | `/challenge "add live chat widget"` |
| `/update` | Check for ai-setup updates and install from Claude Code | `/update` |

---

## Claude Code Essentials

### Keyboard shortcuts
- `Esc Esc` — rewind / summarize the last response (recover tokens)
- `Up arrow` — after interrupting Claude, restores the interrupted prompt and rewinds in one step
- `Ctrl+C` — cancel current generation

### Inline shortcuts
- `! git status` — run a bash command directly (no extra tokens)
- `@src/index.ts` — import a file into context compactly
- `ultrathink:` — prefix to trigger extended reasoning

### Context files (read-only, auto-generated)
Located in `.agents/context/`:
- `STACK.md` — tech stack, versions, key dependencies
- `ARCHITECTURE.md` — system architecture and data flows
- `CONVENTIONS.md` — naming patterns, coding standards, testing

Regenerate with: `claude "regenerate context files"` or re-run `npx @onedot/ai-setup`.

### Subagents
Claude spawns specialized agents automatically during `/spec-work`, `/pr`, and `/bug`. You can also invoke them directly:

| Agent | When it helps |
|---|---|
| `build-validator` | After code changes, before committing |
| `code-reviewer` | After a feature or spec branch |
| `staff-reviewer` | Final review before merging |
| `verify-app` | Runs tests + build to confirm everything works |
| `liquid-linter` | After editing Shopify Liquid templates |

### Hooks (run automatically)
- `circuit-breaker.sh` — prevents infinite edit loops on the same file
- `protect-files.sh` — blocks edits to build output and lock files
- `cross-repo-context.sh` — loads sibling repo context on session start
- `post-edit-lint.sh` — runs linter on save (when available)

---

## Troubleshooting

**Claude keeps editing the same file in a loop?**
The circuit-breaker will trigger after 3 edits. If it fires, stop and re-describe the problem.

**Context is stale after a long session?**
Use `Esc Esc` to compress, or start a fresh session and reference the spec number.

**Spec steps are partially checked off after a crash?**
Re-run `/spec-work NNN` — it detects already-checked steps and resumes from where it left off.

**Build fails after spec-work?**
The Haiku Investigator runs automatically once to diagnose the error. If it can't fix it, read the diagnosis output and fix manually.

**Can't find a command?**
List all available commands: type `/` in Claude Code to see the autocomplete menu, or check `.claude/commands/`.

**Update ai-setup from inside Claude Code:**
```
/update
```

---

## Advanced Techniques

### squirrelscan — Website Audit (SEO, Performance, Security, Accessibility)

240+ rules across 21 categories. Install once as a local binary — faster than npx, no network dependency per run.

**Install:**
```bash
curl -fsSL https://squirrelscan.com/install | bash
```

**CLI usage:**
```bash
squirrelscan https://example.com              # full audit
squirrelscan https://example.com --format llm # LLM-optimized output (40% smaller)
squirrelscan https://example.com --format json # machine-readable for CI/CD
```

**Claude Code Skill** (lets Claude run audits autonomously and fix issues):
```bash
npx skills install squirrelscan/skills
```
Then use `/audit-website` in Claude Code.

---

### ralph-loop — Iterative Task Loops

`ralph-loop` is a Stop-hook-based loop that keeps Claude working on a task across multiple iterations — useful for complex, multi-round implementations where a single session is not enough.

```
/ralph-loop "Build a REST API for todos. Requirements: CRUD, validation, tests. Output <promise>COMPLETE</promise> when done." --completion-promise "COMPLETE" --max-iterations 50
```

Claude will work, try to exit, get intercepted by the Stop hook, and re-start with the same prompt — each time seeing the files and git history from the previous iteration. Cancel at any time:

```
/cancel-ralph
```

**When to use:** Long iterative tasks, multi-round refactors, tasks that need repeated test-fix cycles.
**Note:** ralph-loop uses a Stop hook. Do not combine with other Stop hooks.

---

### repomix — Full Codebase Snapshot

Generates a compressed, token-efficient snapshot of the entire codebase. Use before large refactors or architecture reviews.

**Via Claude:**
```
/context-full
```

**Direct CLI:**
```bash
npx repomix --compress --style markdown \
  --ignore "node_modules,dist,.git,.next,.nuxt,coverage,*.lock" \
  --output .agents/repomix-snapshot.md
```

Output is written to `.agents/repomix-snapshot.md` (gitignored). Claude reads it automatically when you run `/context-full`.

---

### defuddle + markdown.new — Token-Efficient Web Fetching

Reading web pages with WebFetch returns raw HTML — ~5× more tokens than needed. Two better options:

**defuddle CLI** (strips navigation, ads, clutter — returns clean markdown):
```bash
defuddle parse https://example.com/docs --md
```

**markdown.new** (URL prefix — no CLI required, works in browser and via WebFetch):
```
https://markdown.new/https://example.com/docs
```

Both reduce token usage by ~80% compared to raw HTML. Use WebFetch only when the page requires JavaScript rendering.

---

### Local API Dumps — MCP Acceleration

MCP servers (Storyblok, Shopify, etc.) require discovery calls to find IDs and slugs. A local dump lets Claude read all entries instantly and make only targeted MCP calls — no pagination, no blind search.

**Why:**
- Instant ID/slug lookup without roundtrips
- Batch analysis across all entries in one read
- Reduces MCP calls by 80%+ on typical tasks

**Example (Storyblok):**
```bash
npm run storyblok-dump
# writes: scripts/storyblok-dump.json (JSONL with summary header)
```

**Pattern:**
1. Run dump script → produces local JSONL/JSON file
2. Read dump to find the IDs/slugs you need
3. Make targeted MCP calls (`storyblok_get_story(id)`) — no discovery needed

Any CMS or API with a list endpoint can follow this pattern.

---

*This guide is installed and kept up to date by `@onedot/ai-setup`. Do not reference it in CLAUDE.md (it is not loaded into context automatically).*
