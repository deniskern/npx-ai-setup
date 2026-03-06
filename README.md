# @onedot/ai-setup

Production-ready AI infrastructure for Claude Code. One command installs hooks, slash commands, subagents, project context, and AI-curated skills — then Claude analyzes the codebase and populates everything automatically.

```bash
npx github:onedot-digital-crew/npx-ai-setup
```

Supports Shopify, Nuxt, Next.js, Laravel, Shopware, Storyblok, or auto-detection.

---

## What it installs

| Layer | What |
|-------|------|
| **CLAUDE.md** | Communication protocol, task routing (simple/medium/complex), verification gate |
| **AGENTS.md** | Universal passive context for Cursor, Windsurf, Cline, and AGENTS.md-compatible tools |
| **Settings** | Granular bash permissions, opusplan model, AUTOCOMPACT=30, ENABLE_TOOL_SEARCH |
| **Hooks** | protect-files, auto-lint, circuit-breaker, context-freshness, update-check, cross-repo-context, notifications, SessionStart context reload, PostToolUseFailure log, ConfigChange audit, TaskCompleted gate, Stop quality gate |
| **Rules** | `.claude/rules/` — general, testing, git, typescript (conditional) |
| **Commands** | 16 slash commands for spec-driven development, reviews, releases, debugging |
| **Agents** | 8 subagent templates for parallel verification, review, and architectural assessment |
| **Context** | `.agents/context/` — STACK.md, ARCHITECTURE.md, CONVENTIONS.md (auto-generated) |
| **GitHub** | `.github/copilot-instructions.md` + `.github/workflows/release-from-changelog.yml` |
| **Skills** | AI-curated Claude Code skills matched to your stack via skills.sh |

---

## Multi-Repo Context (without naming convention)

For projects split across multiple repositories (e.g. Shopware theme/plugin/shop or Laravel frontend/backend), add an optional map file:

` .agents/context/repo-group.json `

Example:

```json
{
  "group": "or24",
  "repos": [
    { "name": "sw-theme-or24", "module": "theme", "path": "../sw-theme-or24" },
    { "name": "sw-sub-theme-or24", "module": "sub-theme", "path": "../sw-sub-theme-or24" },
    { "name": "sw-plugin-or24", "module": "plugin", "path": "../sw-plugin-or24" },
    { "name": "sw-shop-or24", "module": "shop", "path": "../sw-shop-or24" }
  ]
}
```

On `SessionStart`, the `cross-repo-context` hook reads this file and injects a compact sibling-repo summary automatically.

If the file is absent, it falls back to automatic discovery for `sw-<module>-<project>` naming.

During `ai-setup`, you can create this file via an interactive prompt (`Multi-Repo Context` wizard).

---

## Slash Commands

| Command | Model | Description |
|---------|-------|-------------|
| `/spec "task"` | Opus | Challenge idea first, then create structured spec |
| `/spec-work 001` | Sonnet | Execute a spec step by step |
| `/spec-work-all` | Sonnet | Execute all draft specs in parallel via Git worktrees |
| `/spec-review 001` | Opus | Review spec changes against acceptance criteria |
| `/spec-board` | Sonnet | Kanban-style overview of all specs |
| `/bug "description"` | Sonnet | Reproduce → root cause → fix → verify → code review |
| `/commit` | Sonnet | Stage changes + create descriptive commit |
| `/pr` | Sonnet | Draft PR title/body, run build validation |
| `/review` | Opus | Review uncommitted changes — bugs, security, performance |
| `/test` | Sonnet | Run tests + fix failures (up to 3 attempts) |
| `/techdebt` | Sonnet | End-of-session sweep — dead code, unused imports |
| `/release` | Sonnet | Bump version, update CHANGELOG, commit + git tag |
| `/grill` | Opus | Adversarial code review — blocks until all issues resolved |
| `/analyze` | Sonnet | 3 parallel agents — architecture, hotspots, risks |
| `/reflect` | Sonnet | Detect session corrections → write as permanent CLAUDE.md rules |
| `/context-full` | Sonnet | Full codebase snapshot via repomix |

## Subagents

| Agent | Purpose |
|-------|---------|
| `verify-app` | Run tests + build, report PASS/FAIL |
| `build-validator` | Quick build check (Haiku) |
| `code-reviewer` | HIGH/MEDIUM confidence review — PASS/CONCERNS/FAIL |
| `code-architect` | Architectural assessment before implementation |
| `staff-reviewer` | Skeptical staff engineer review |
| `perf-reviewer` | Performance analysis — FAST/CONCERNS/SLOW |
| `test-generator` | Generate missing tests for changed files |
| `context-refresher` | Regenerate `.agents/context/` on `[CONTEXT STALE]` |

---

## Installation flags

```bash
npx github:onedot-digital-crew/npx-ai-setup [flags]

--system nuxt,storyblok   # Set framework (auto, shopify, nuxt, next, laravel, shopware, storyblok)
--regenerate              # Re-run Auto-Init without reinstalling files
```

---

## Update

Run the same command again — the script auto-detects and offers:

- **Update files** — compare each template, ask before overwriting user-modified files
- **Regenerate** — re-run Claude analysis (CLAUDE.md, AGENTS.md, context, commands, skills)
- **Clean reinstall** — remove all managed files, fresh install

---

## Testing

Run local smoke checks before publishing:

```bash
npm test
```

CI also runs `tests/smoke.sh` automatically on every pull request and push to `main`.

To enforce tests before every push, install the tracked git hook once per clone:

```bash
npm run hooks:install
```

Check current hook path:

```bash
npm run hooks:status
```

Temporary bypass (only if needed):

```bash
SKIP_PREPUSH_TESTS=1 git push
```

---

## GitHub Releases (Slack-ready)

AI Setup installs `.github/workflows/release-from-changelog.yml` into target projects.
When you push a version tag like `v1.2.5`, it creates or updates the GitHub Release body from the matching `CHANGELOG.md` section:

- Required heading format: `## [vX.Y.Z]`
- Fallback if tag push is delayed: `gh workflow run release-from-changelog.yml -f tag=vX.Y.Z`
- Slack GitHub App (`/github subscribe owner/repo releases`) will show this release body in channel notifications.

---

## Requirements

- Node.js >= 18 + npm
- `jq` — `brew install jq`
- Claude Code CLI (`claude`) — for Auto-Init (optional, Copilot as fallback)

---

## Built-in Plugins & Extensions

All plugins and integrations are installed automatically — no flags needed.

| Plugin | What it does |
|--------|-------------|
| **claude-mem** | Persistent memory across sessions, MCP search tools |
| **claude-plugin@coderabbitai** | CodeRabbit PR review companion plugin for Claude Code |
| **code-review** | 4 parallel review agents — `/code-review` |
| **feature-dev** | 7-phase feature workflow — `/feature-dev` |
| **frontend-design** | Anti-generic design guidance for frontend projects |
| **Context7** | Up-to-date library docs in context — "use context7" |

Team sharing: marketplace plugins via `extraKnownMarketplaces` in `.claude/settings.json`, MCP servers via `.mcp.json` — both committed to git.

---

## Optional Extensions

### GSD (Get Shit Done)

Phase planning, codebase mapping, and session management. Install separately:

```bash
npx get-shit-done-cc@latest --claude --global
```

More info: [GSD workflow engine](https://github.com/get-shit-done-cc/get-shit-done-cc)

### rtk (Reduce Token Cost)

CLI proxy that compresses command outputs before they hit the context window. 60-90% token reduction on git, grep, test outputs.

```bash
brew install rtk && rtk init --global
```

More info: [rtk-ai/rtk](https://github.com/rtk-ai/rtk)

---

## Default skills by system

| System | Skills installed |
|--------|-----------------|
| **Shopify** | shopify-development, shopify-expert, shopify-theme-dev |
| **Nuxt / Vue** | nuxt, vue, vueuse |
| **Next.js / React** | vercel-react-best-practices, nextjs-developer, nextjs-app-router-patterns |
| **Laravel** | laravel-specialist, eloquent-best-practices |
| **Shopware** | shopware6-best-practices |
| **Storyblok** | storyblok-best-practices |

---

---

## Links

- [Skills marketplace](https://skills.sh/)
- [Claude-Mem](https://claude-mem.ai)
- [CodeRabbit Claude Plugin](https://github.com/coderabbitai/claude-plugin)
- [Context7](https://github.com/upstash/context7)
- [Claude Code Docs](https://docs.anthropic.com/en/docs/claude-code)
- [Concept & Design Decisions](.agents/context/CONCEPT.md)
