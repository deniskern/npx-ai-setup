# Agent Delegation Rules

## CRITICAL: Model Routing

Always set `model:` when spawning subagents. Haiku costs 12× less than Sonnet — use it for all search and explore work.

| Model | Use for |
|-------|---------|
| `haiku` | **CRITICAL** — ALL Explore agents, file search, codebase questions, simple research |
| `sonnet` | Implementation, code generation, test writing |
| `opus` | Architecture review, complex analysis, spec creation |

Never spawn an Explore or search agent without `model: haiku`.

## Context Isolation

Never let subagents inherit your session context — construct exactly what they need in the prompt. This keeps agents focused and preserves your own context for coordination.

## Agent Dispatch

Full trigger/model table: see `.claude/docs/agent-dispatch.md`.

## Hallucination Prevention

- Never invent or guess file paths — verify with Glob/Grep before referencing
- Never assume import paths, function names, or API routes exist — read the file first
- When reporting issues, be specific: "Edge at index 14 references non-existent target `file:src/missing.ts`" — not generic descriptions
- If an agent reports a file path or symbol, verify it exists before acting on the report
