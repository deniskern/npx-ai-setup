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

## Agent Selection

Each agent file contains `## When to Use` and `## Avoid If` sections. Read these before spawning an agent.

**Selection rules:**
- Match the task against `When to Use` bullet points — all conditions should broadly apply
- Check `Avoid If` first — if any condition matches, pick a different agent
- When two agents seem applicable, `Avoid If` sections will indicate which one to defer to
- Never spawn an agent if the task has fewer than 3 tool calls worth of work
