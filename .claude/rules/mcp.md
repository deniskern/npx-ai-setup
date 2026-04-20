# MCP Server Rules

## Project vs Global

This project's `.mcp.json` pins `context7` project-local (so every contributor gets it without global setup).
Other MCP servers come from `~/.claude/mcp.json` (workstation-global) — add project entries only when overrides are needed.

```bash
claude mcp list               # list all active servers
claude mcp disable <name>     # deactivate globally without removing from .mcp.json
```

## Expected Global Servers

The following MCP servers are expected to be configured globally (not in project `.mcp.json`):

| Server | Purpose | Install |
|--------|---------|---------|
| `context7` | Library and API documentation lookup | `claude mcp add context7 -- npx -y @upstash/context7-mcp` |

If `use context7` fails, the server is not active globally. Verify with `claude mcp list`.
