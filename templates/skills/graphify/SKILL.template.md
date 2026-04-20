---
name: graphify
description: "Build and query a semantic knowledge graph for the project. Trigger: /graphify"
user-invocable: true
effort: medium
model: sonnet
stacks: [all]
allowed-tools:
  - Bash
  - Read
  - Glob
  - Grep
---

# Graphify — Semantic Knowledge Graph

Build a persistent community-detection graph (`graphify-out/graph.json`) for token-efficient
code navigation. Complements the auto-generated import graphs — it does NOT replace them.

## Graph Types in This Project

| File | What it maps | When present |
|------|-------------|--------------|
| `.agents/context/graph.json` | JS/TS import graph (auto-generated) | Always (JS/TS projects) |
| `.agents/context/liquid-graph.json` | Liquid section/snippet/template deps | Shopify only (spec 639) |
| `graphify-out/graph.json` | Semantic community graph (this skill) | After `/graphify build` |

## Prerequisites

```bash
pipx install graphifyy   # one-time, on dev machine
graphify --version       # verify
```

## Commands

```bash
graphify build .         # scan project, write graphify-out/graph.json
graphify query <term>    # find nodes matching term
graphify path <a> <b>    # shortest path between two nodes
graphify explain <node>  # community + incoming/outgoing edges for a node
```

## jq Query Patterns

```bash
# Top communities (cluster overview)
jq '.communities[] | {id, size: (.nodes | length), label}' graphify-out/graph.json

# Find which community a file belongs to
jq --arg f "components/Header.vue" \
  '.communities[] | select(.nodes[] == $f) | {id, label}' graphify-out/graph.json

# Files with most incoming edges (high-impact)
jq '[.nodes[] | {file: .id, incoming: (.edges_in | length)}]
  | sort_by(-.incoming) | .[0:10]' graphify-out/graph.json

# Files connected to a specific node
jq --arg f "stores/cart.ts" \
  '[.edges[] | select(.source == $f or .target == $f) | {source, target, type}]' \
  graphify-out/graph.json
```

## Usage Pattern

Use `graphify query` or `jq` on `graphify-out/graph.json` **before** spawning search agents.
A single `jq` query costs ~20 tokens vs 500+ tokens for a Grep round-trip.

Only run `graphify build` when the graph is stale (after large refactors or initial setup).
Add `graphify-out/` to `.gitignore` — graph is ephemeral, rebuilt on demand.
