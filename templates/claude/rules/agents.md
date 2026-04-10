# Agent Delegation Rules

## CRITICAL: Model Routing

Always set `model:` when spawning subagents. Sonnet is the default for implementation subagents. Haiku costs 12× less — use it for all search and explore work.

| Model | Use for |
|-------|---------|
| `haiku` | **CRITICAL** — ALL Explore agents, file search, codebase questions, simple research |
| `sonnet` | Implementation, code generation, test writing (default for subagents) |
| `opus` | Architecture review, complex analysis, spec creation |

Never spawn an Explore or search agent without `model: haiku`. Haiku is never for implementation — code-writing agents must use Sonnet.

## Agent Dispatch

Full trigger/model table: see `.claude/docs/agent-dispatch.md`.

## Agent Selection

Use Claude Code's built-in agent types (code-reviewer, security-reviewer, staff-reviewer, etc.) instead of custom agents.

**Selection rules:**
- Threshold: spawn agents only for tasks requiring ≥3 distinct tool calls
- Never let subagents inherit your session context — construct exactly what they need in the prompt
- Escalation rule: if you've already made 8 tool calls on a task with no subagents, consider parallelizing the remaining work

## Graph-Assisted Navigation

If `.agents/context/graph.json` exists, query it before spawning search agents or writing grep-heavy prompts:

```bash
# Hub files (most imported — start here for broad changes)
jq -r '.stats.top_hubs[] | "\(.imported_by)x \(.file)"' .agents/context/graph.json

# Who imports a specific file (impact analysis)
jq -r --arg f "app/composables/useBlokSeo.ts" '.edges[] | select(.target==$f) | .source' .agents/context/graph.json

# What a file depends on (context before editing)
jq -r --arg f "app/pages/[...slug].vue" '.edges[] | select(.source==$f) | "\(.kind): \(.target)"' .agents/context/graph.json
```

Inject the result into the agent prompt — 20 tokens instead of 500 for a grep. Skip if graph.json is missing or the project has no JS/TS files.

## Hallucination Prevention

- Never invent or guess file paths — verify with Glob/Grep before referencing
- Never assume import paths, function names, or API routes exist — read the file first
- When reporting issues, be specific: "Edge at index 14 references non-existent target `file:src/missing.ts`" — not generic descriptions
- If an agent reports a file path or symbol, verify it exists before acting on the report
