# CLAUDE.md

## Communication Protocol
No small talk. Just do it.
Confirmations one word (Done, Fixed). Show code changes as diff only.
If you edit the same file 3+ times without progress, stop and ask for guidance.

## Project Context (read before complex tasks)
Before multi-file changes or new features, read `.agents/context/`:
- `STACK.md` - Technology stack, versions, key dependencies, and what to avoid
- `ARCHITECTURE.md` - System architecture, directory structure, and data flow
- `CONVENTIONS.md` - Coding standards, naming patterns, error handling, and testing

## Commands
- `npx @onedot/ai-setup` — run the setup tool (installs Claude Code config, hooks, skills)
- `./bin/ai-setup.sh` — run directly from repo root
- No npm scripts defined; all logic lives in the shell script

## Critical Rules

### Shell Script Style
- Use `bash` strictly; avoid bashisms that break on `sh`
- Quote all variable expansions: `"$var"`, `"${var}"`, `"$@"`
- Use `local` for all function-scoped variables
- Check exit codes explicitly; prefer `|| return 1` over silent failures

### File and Path Conventions
- Templates live in `templates/` and are copied verbatim to the target project
- Do not modify template files for project-specific content — use generation logic in `bin/ai-setup.sh`
- All generated content must be in English; no umlauts or non-ASCII characters

### Safety and Idempotency
- All install steps must be idempotent — running twice must not corrupt state
- Check for existing files before overwriting; prompt or skip, never silently clobber
- Never `rm -rf` without an explicit user confirmation gate in the script

## Task Complexity Routing
Before starting, classify and state the task tier:

- **Simple** (typos, single-file fixes, config tweaks): proceed directly
- **Medium** (new feature, 2-3 files, component): use plan mode
- **Complex** (architecture, refactor, new system): stop and tell the user to run
  `/gsd:set-profile quality` or restart with `claude --model claude-opus-4-6`

Never start a complex task without flagging the model requirement first.

## Verification
After completing work, verify before marking done:
- Run tests if available (`/test`)
- For UI changes: use browser tools or describe expected result
- For API changes: make a test request
- Check the build still passes

Never mark work as completed without BOTH:
1. Automated checks pass (tests green, linter clean, build succeeds)
2. Explicit statement: "Verification complete: [what was checked and result]"

## Context Management
Your context will be compacted automatically — this is normal. Before compaction:
- Commit current work or save state to HANDOFF.md
- Track remaining work in the spec or a todo list
After fresh start: review git log, open specs, check test state.

Run /compact when context reaches 80% — quality degrades beyond this threshold.

If you see `[CONTEXT STALE]` in your context: note that project context files may be outdated, but continue with the current task. Do not interrupt work to refresh context.

## Spec-Driven Development
Specs live in `specs/` — structured task plans created before coding.

**When to suggest a spec:** Changes across 3+ files, new features, architectural changes, ambiguous requirements.
**Skip specs for:** Single-file fixes, typos, config changes.

See `specs/README.md` for details.

## Documentation Lookup
Always use Context7 MCP when you need library/API documentation, code generation,
setup or configuration steps. Add "use context7" to prompts or it will be auto-invoked.
