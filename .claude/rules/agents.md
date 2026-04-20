# Agent Delegation Rules

## Model Routing (CRITICAL)

Always set `model:` when spawning subagents.

| Model | Use for |
|-------|---------|
| `haiku` | ALL Explore/search/read-only agents (12× cheaper than Sonnet) |
| `sonnet` | Implementation, code generation, tests (default for impl subagents) |
| `opus` | Architecture review, spec creation |

Never spawn Explore/search without `haiku`. Code-writing agents must use `sonnet`.

## Effort Levels (Opus 4.7)

`/effort` oder `--effort` setzen: `medium` → `high` → `xhigh` → `max`.
Default für Pro/Max: `high`. `xhigh` nur Opus 4.7 — andere Modelle fallen auf `high` zurück.
Für Arch-Review/Spec-Arbeit: `xhigh`. Für normale Code-Tasks: default `high`.

## Dispatch

- Threshold: spawn agents only for tasks requiring ≥3 distinct tool calls
- Escalation rule: if you've already made 8 tool calls on a task with no subagents, parallelize the remaining work

Full trigger/model table: `.claude/docs/agent-dispatch.md`.

## Graph-Assisted Navigation

If `.agents/context/graph.json` exists, query it before spawning search agents:

```bash
jq -r '.stats.top_hubs[] | "\(.imported_by)x \(.file)"' .agents/context/graph.json
jq -r --arg f "path/file.ts" '.edges[] | select(.target==$f) | .source' .agents/context/graph.json
```

20 tokens instead of 500 for a grep. Skip if graph.json missing or no JS/TS.
