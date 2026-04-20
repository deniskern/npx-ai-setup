# MCP Server Rules

## Project vs Global

Project `.mcp.json` overrides global servers with the same name.
Global servers live in `~/.claude/mcp.json` and apply to all projects.

```bash
claude mcp list               # list all active servers
claude mcp disable <name>     # deactivate without removing from .mcp.json
```

## Default MCPs

`context7` — Library/API docs lookup. Add "use context7" to any prompt for up-to-date docs.
Installed globally or via `.mcp.json`. Run `npx @onedot/ai-setup` to add it to a project.

`shopify-dev-mcp` — Liquid/GraphQL schema reference (Shopify stacks only).
Auto-suggested by ai-setup when `theme.liquid` / `shopify.*` detected.

To opt out of a default MCP: remove its entry from `.mcp.json` and run `claude mcp list` to verify.
No auth, no tokens — both MCPs are pure npx commands.
