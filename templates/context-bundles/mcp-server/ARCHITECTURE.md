<!-- bundle: mcp-server v1 -->
---
abstract: "MCP server: src/index.ts registers tools via Tool-Registry pattern. stdio or HTTP transport. Zod validates inputs."
---

# Architecture

## Directory Structure
- `src/index.ts` — server entry: creates `Server`, registers tools, connects transport
- `src/tools/` — one file per tool or domain group (`src/tools/search.ts`)
- `src/lib/` — shared utilities (HTTP client, formatters, error helpers)
- `dist/` — compiled output (do not edit)

## Tool-Registry Pattern
1. Define Zod schema for tool inputs
2. Export `{ name, description, schema, handler }` from tool file
3. `src/index.ts` imports and registers: `server.tool(name, schema, handler)`
4. Handler receives validated `args`, returns `{ content: [{type, text}] }`

## Transport
- stdio (default): `server.connect(new StdioServerTransport())`
- HTTP: `server.connect(new StreamableHTTPServerTransport({ port }))`

## Error Handling
- Tool errors: return `{ content: [{type: "text", text: "Error: ..."}], isError: true }`
- Never throw unhandled — caught by SDK and returned as protocol error
- Validate all external calls; set timeouts on HTTP requests
