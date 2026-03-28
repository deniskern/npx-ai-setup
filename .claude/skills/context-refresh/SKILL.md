---
name: context-refresh
description: Regenerates .agents/context/ files (STACK.md, ARCHITECTURE.md, CONVENTIONS.md) and updates the .state hash. Triggers: /context-refresh, 'update context', 'context is stale', '[CONTEXT STALE]'.
---

# Context Refresh

Regenerates `.agents/context/` files and reliably updates `.state` so `context-freshness.sh` stops warning.

## Behavior

1. Spawn the `context-refresher` subagent with `model: haiku` — it regenerates STACK.md, ARCHITECTURE.md, CONVENTIONS.md.
2. After the agent completes, **always** run this directly (not via the agent):
```bash
{
  echo "PKG_HASH=$(cksum package.json 2>/dev/null | cut -d' ' -f1,2)"
  echo "TSCONFIG_HASH=$(cksum tsconfig.json 2>/dev/null | cut -d' ' -f1,2)"
  echo "GIT_HASH=$(git rev-parse HEAD 2>/dev/null)"
} > .agents/context/.state
```
3. Confirm: "Context refreshed. .state updated to $(git rev-parse --short HEAD)."

## Why step 2 is mandatory

The agent may silently skip or fail the `.state` write due to sandbox restrictions. Running it here guarantees `.state` always matches reality — otherwise `context-freshness.sh` warns on every prompt forever.
