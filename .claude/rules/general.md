# General Coding Rules

## Read Before Modify
Always read a file before modifying it. Never assume contents from memory or prior context.
After context compaction, re-read files before continuing work — do not assume what was already done.

## Check Before Creating
Before creating a new file, check if one already exists:
- Run `ls` or Glob to find existing files matching the concept
- Run `git ls-files` to see tracked files that may not be visible

## Verify, Don't Guess
Never assume import paths, function names, or API routes. Verify by reading the relevant file.
Never fabricate configuration formats or assume config file schemas exist — check docs or existing examples first.
When unsure about current state, run `git diff` to see what has actually changed this session.

## Human Approval Gates
Before finalizing any deliverable, present a summary and ask for confirmation.
Never proceed to the next workflow phase without explicit user approval.

## Skill-First
Before implementing anything manually, check installed skills:
1. Run `ls .claude/skills/` to list available skills
2. If a skill matches the task, invoke it via the `Skill` tool — do not reimplement
3. If no skill matches, ask the user before proceeding with manual implementation

This applies everywhere: direct chat, spec steps, and delegated agents.

## Web Fetching
Library/API docs: use Context7 MCP (`use context7`). Web pages: `defuddle parse <url> --md`.
Use WebFetch only when defuddle is unavailable or the page requires JavaScript rendering.

## Destructive Operations
Before confirming deletion, revert, or disable operations as "correct behavior", trace through the actual code path that would be affected. Show the specific lines, not just reasoning. Past pattern: Claude confirmed destructive behavior as correct twice before users found the real bug.

## Sandbox Safety
Never set `dangerouslyDisableSandbox: true` on a Bash tool call without first:
1. Explaining to the user why the sandbox blocks the command
2. Receiving explicit user confirmation to bypass the sandbox

Silent retries with sandbox disabled are not allowed — even if a previous attempt failed.
