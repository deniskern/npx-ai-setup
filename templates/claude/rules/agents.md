# Agent Delegation Rules

## Model Routing (CRITICAL)

Always set `model:` when spawning subagents.

| Model | Use for |
|-------|---------|
| `haiku` | ALL Explore/search/read-only agents (12× cheaper than Sonnet) |
| `sonnet` | Implementation, code generation, tests (default for impl subagents) |
| `opus` | Architecture review, spec creation |

Never spawn Explore/search without `haiku`. Code-writing agents must use `sonnet`.

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

## Graph-Before-Read Enforcement

The `graph-before-read.sh` hook (PreToolUse: Read/Grep/Glob) enforces this rule automatically:
- Read on a file >500 lines → stderr hint to check graph.json first
- 4× Grep in a row without a graph query → hint to use graph instead

Opt-out: `.claude/settings.local.json` `{ "graphBeforeRead": false }`. Hook never blocks.

## Shopify Liquid Graph Navigation

If `.agents/context/liquid-graph.json` exists (shopify-liquid profile), query it before searching Liquid files:

```bash
# Who renders a given snippet?
jq -r --arg s "snippets/product-card.liquid" '.edges[] | select(.target==$s) | .source' .agents/context/liquid-graph.json

# Top rendered snippets (hub ranking)
jq -r '.stats.top_hubs[] | "\(.imported_by)x \(.file)"' .agents/context/liquid-graph.json | head -10

# Orphan snippets (safe to remove candidates)
jq -r '.stats.orphans[]' .agents/context/liquid-graph.json
```

Refresh graph: `bash .claude/scripts/liquid-graph-refresh.sh` (no-op if up to date).
