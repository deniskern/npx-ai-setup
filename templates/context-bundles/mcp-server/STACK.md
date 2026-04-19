<!-- bundle: mcp-server v1 -->
---
abstract: "Node.js 18+ TypeScript MCP server using @modelcontextprotocol/sdk. Zod validation, stdio or HTTP transport."
---

# Stack

## Runtime & Distribution
- Node.js 18+, npm
- Published as npm package or run via `npx`
- Transport: stdio (default) or Streamable HTTP

## Framework & Dependencies
- @modelcontextprotocol/sdk (Server, Tool, Resource, Prompt classes)
- Zod for input schema validation
- tsx or ts-node for development (`tsx watch src/index.ts`)
- TypeScript 5+, strict mode

## Build & Tooling
- `tsc --noEmit` — type check only (no emit in dev)
- `tsc` → `dist/` for production
- `node dist/index.js` → production server
- No test framework required; validate via `mcp list` and manual calls
