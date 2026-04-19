<!-- bundle: mcp-server v1 -->
---
abstract: "MCP conventions: snake_case tool names, LLM-readable descriptions, Zod schemas, isError return format."
---

# Conventions

## Tool Naming
- Tool names: `snake_case` (`search_documents`, `get_user_profile`)
- Descriptions: written for an LLM, not a human developer
  - State what the tool does, what it returns, when to use it
  - Include key parameter constraints (max length, format)
- Parameter names: `snake_case`, match Zod key names exactly

## Zod Schemas
- Every tool input must have a Zod schema — no untyped `any`
- Add `.describe()` to each field for LLM context
- Optional params use `.optional()` with `.default()` where sensible

## Error Returns
- Errors: `return { content: [{ type: "text", text: "Error: reason" }], isError: true }`
- Never throw inside a tool handler — catch and return isError format
- Log errors to stderr (`console.error`) for operator visibility

## Definition of Done
- [ ] `tsc --noEmit` passes (no TypeScript errors)
- [ ] Tool appears in `mcp list` output
- [ ] Tool runs without unhandled promise rejections
- [ ] All inputs covered by Zod schema with `.describe()` on each field
