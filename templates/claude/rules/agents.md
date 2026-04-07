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

Each agent file contains `## When to Use` and `## Avoid If` sections. Read these before spawning an agent.

**Selection rules:**
- Match the task against `When to Use` bullet points — all conditions should broadly apply
- Check `Avoid If` first — if any condition matches, pick a different agent
- When two agents seem applicable, `Avoid If` sections will indicate which one to defer to
- Threshold: spawn agents only for tasks requiring ≥3 distinct tool calls
- Never let subagents inherit your session context — construct exactly what they need in the prompt
- Escalation rule: if you've already made 8 tool calls on a task with no subagents, consider parallelizing the remaining work

## Hallucination Prevention

- Never invent or guess file paths — verify with Glob/Grep before referencing
- Never assume import paths, function names, or API routes exist — read the file first
- When reporting issues, be specific: "Edge at index 14 references non-existent target `file:src/missing.ts`" — not generic descriptions
- If an agent reports a file path or symbol, verify it exists before acting on the report
