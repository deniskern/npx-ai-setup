# Agent Frontmatter Schema

## Required Fields
- `name` — machine identifier (kebab-case, matches filename)
- `description` — one-sentence purpose used for agent discovery
- `tools` — comma-separated list of allowed tools
- `model` — haiku | sonnet | opus (match task complexity)

## Optional Fields
- `emoji` — single emoji for quick visual identification
- `max_turns` — cap on agent turns (default: unlimited)
- `memory` — memory scope: project | global
- `vibe` — one-liner personality / behavioral stance
- `permissionMode` — plan (read-only) | default
- `isolation` — worktree (for agents that write files)
