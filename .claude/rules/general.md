# General Coding Rules

## Read Before Modify
Always read a file before modifying it. Never assume contents from memory or prior context.
After context compaction, re-read files before continuing work — do not assume what was already done.

## Check Before Creating
Before creating a new file, check if one already exists:
- Run `ls` or Glob to find existing files matching the concept
- Run `git ls-files` to see tracked files that may not be visible

## Human Approval Gates
Before finalizing any deliverable, present a summary and ask for confirmation.
Never proceed to the next workflow phase without explicit user approval.

## Web Fetching
Prefer `defuddle parse <url> --md` over WebFetch for reading web pages — it strips navigation and clutter, saving ~80% tokens.
Alternative: prepend `https://markdown.new/` to any URL for instant markdown conversion without a CLI.
Use WebFetch only when defuddle is unavailable or the page requires JavaScript rendering.

## Research & Spec Gate
Before /research creates specs: validate candidates against CONCEPT.md and project philosophy first — 3 of 4 specs in one session were cancelled post-creation for violating existing decisions.
Before creating a spec from session-optimize findings: verify the finding still applies by reading the current file state — findings may describe issues already fixed.

## Sandbox Safety
Never set `dangerouslyDisableSandbox: true` on a Bash tool call without first:
1. Explaining to the user why the sandbox blocks the command
2. Receiving explicit user confirmation to bypass the sandbox

Silent retries with sandbox disabled are not allowed — even if a previous attempt failed.
