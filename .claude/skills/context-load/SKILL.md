---
name: context-load
description: "Load context files on demand — STACK.md, ARCHITECTURE.md, CONVENTIONS.md, decisions.md. Triggers: /context-load, 'load architecture', 'show stack details', 'load conventions'."
---

# Context Load — On-Demand L2 Context

Load full `.agents/context/` files when the L0 abstracts from SessionStart are not enough.

## Usage

- `/context-load STACK.md` — load full STACK.md
- `/context-load ARCHITECTURE.md` — load full ARCHITECTURE.md
- `/context-load CONVENTIONS.md` — load full CONVENTIONS.md
- `/context-load all` — load all context files
- `/context-load STACK.md#runtime` — load only the "Runtime" section (case-insensitive match)

## Behavior

1. Read `$ARGUMENTS` to determine which file(s) to load
2. If no argument or `all`: read all 3 context files with the Read tool
3. If a file name is given: read that specific file
4. If `#section` is appended: read the file and extract only the matching `## Section` block
5. Present the loaded context inline — no summary, just the raw content

## When to Use

- Complex multi-file tasks where abstracts lack detail
- When you need specific conventions or patterns before implementing
- When the user references architecture or stack details not in the abstract

## When NOT to Use

- Simple tasks where the L0 abstract is sufficient
- When you can just read the file directly with the Read tool (this skill is a convenience shortcut)
