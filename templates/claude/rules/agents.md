# Agent Delegation Rules

## CRITICAL: Model Routing

Always set `model:` when spawning subagents. Haiku costs 12× less than Sonnet — use it for all search and explore work.

| Model | Use for |
|-------|---------|
| `haiku` | **CRITICAL** — ALL Explore agents, file search, codebase questions, simple research |
| `sonnet` | Implementation, code generation, test writing |
| `opus` | Architecture review, complex analysis, spec creation |

Never spawn an Explore or search agent without `model: haiku`.

## Agent Dispatch

Full trigger/model table: see `.claude/docs/agent-dispatch.md`.
