# MCP Server Priority

Project `.mcp.json` is loaded automatically by Claude Code and **overrides global servers** with the same name.
Check `.mcp.json` in the project root before assuming a server is configured globally.

```bash
claude mcp list          # show all active servers (global + project)
claude mcp disable <name>  # deactivate globally without removing from .mcp.json
```

For non-interactive `claude -p` runs: `--bare` disables all MCP servers (reproducible CI runs).
Subagents inherit the parent session's MCP config — project servers are included automatically.
