# CLAUDE.md

## Project Context
@.agents/context/SUMMARY.md
Details on demand: `@.agents/context/STACK.md` | `ARCHITECTURE.md` | `CONVENTIONS.md`.

## Investigation vs. Action
- Debug/fix requests: max 8 tool calls for discovery. Then STOP and state (1) hypothesis, (2) files to change, (3) exact edits. Wait for approval.
- Hypothesis-first: before 3+ exploratory calls, list top 3 hypotheses ranked by likelihood with a 1-line test each. Revise after each failed check.
- Scope-guard: never expand beyond what was asked. "Review component X" ≠ "audit all components". List related issues as follow-ups, don't fix.
- Revert-first when stuck. 3+ failed fixes = architectural problem, question the approach.

## Model Routing (CRITICAL)
Main session: Opus — orchestrator. Delegate implementation to subagents with explicit `model:`.
- `haiku` — ALL Explore/search/read-only agents (12x cheaper)
- `sonnet` — code generation, tests (default for impl subagents)
- `opus` — architecture review, spec creation
Inline edits only when <3 tool calls needed; otherwise spawn subagent.

## File Navigation
Glob/Grep → targeted Read (offset+limit) → full Read. Never open files to "check if something exists" — Grep first.
Subagent outputs >2KB: write to `$TMPDIR/agent-output-<task>.md`, return path only.

## Context Offload (CRITICAL)
Broad exploration = delegate to Haiku Explore subagent. Keep Main context lean.
Trigger: any task needing >5 reads/greps to map unfamiliar code. Subagent returns 1-page summary with `file:line` refs.
Example prompt: "Explore how X works across [area]. Return ≤1 page with file:line refs. Do NOT edit."

## Verify, Don't Guess
Never assume import paths, function names, API routes, config schemas. Read the file or check docs first.
Library/API docs: Context7 first (`mcp__context7__*`), then `defuddle parse <url> --md`, WebFetch last resort.

## Frontend Visual Verification (MANDATORY)
After ANY edit to `*.vue`, `*.tsx`, `*.jsx`, `*.liquid`, `*.css`, `*.scss`: invoke `/agent-browser` to open dev server and screenshot affected route. Type-check passes ≠ rendered correctly. Never declare frontend work done without visual verification.

## RTK
Always prefix shell commands with `rtk`. Hook rewrites automatically where possible. Reference: `.claude/docs/rtk-reference.md`.

## Build Artifacts
Never read/search: `dist/`, `.output/`, `.nuxt/`, `.next/`, `build/`, `coverage/`. Blocked via `permissions.deny`.

## Skill Shell Execution
Skills in this setup use `!` shell-exec prefix in prep scripts (ci, test, doctor, etc.). If org policy sets `disableSkillShellExecution: true`, those skills fail silently. Fallback: run the `.sh` directly via Bash tool.

## Destructive Operations
Before confirming delete/revert/disable as "correct": trace the actual code path with file:line. Never `dangerouslyDisableSandbox: true` without explicit user confirmation.

## Git
Conventional commits: `type(scope): description`. Branch: `feat/*` `fix/*` `chore/*` `spec/NNN-*`. Stage specific files, never `git add -A`. Body explains *why*, diff shows *what*.

## Skills & Workflows
Before implementing manually: `ls .claude/skills/` — invoke via Skill tool if match.
Workflow hints on-demand: `/workflow-hint` for "what's next" logic. Don't stack suggestions.

## CLI Shortcuts (zero tokens)
CI `! bash .claude/scripts/ci-prep.sh` | Lint `! bash .claude/scripts/lint-prep.sh` | Test `! bash .claude/scripts/test-prep.sh` | Health `! bash .claude/scripts/doctor.sh` | Quality-gate `! bash .claude/scripts/quality-gate.sh` | Debug `! bash .claude/scripts/debug-prep.sh`

## Automation (Agent SDK CLI)
Non-interactive: `claude -p "<prompt>" --output-format json`. CI: `--bare` disables hooks/skills/MCP. Cost: `--max-budget-usd 0.50` / `--max-turns 20`.
