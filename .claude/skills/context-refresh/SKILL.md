---
name: context-refresh
description: "Regenerates .agents/context/ files (STACK.md, ARCHITECTURE.md, CONVENTIONS.md) and updates the .state hash. Triggers: /context-refresh, 'update context', 'context is stale', '[CONTEXT STALE]'."
---

# Context Refresh

Regenerates `.agents/context/` files and reliably updates `.state` so `context-freshness.sh` stops warning.

## Behavior

1. Spawn the `context-refresher` subagent with `model: haiku` — it regenerates STACK.md, ARCHITECTURE.md, CONVENTIONS.md.

2. Detect project system and run the matching Bash scanner (zero LLM tokens):
   - `theme.liquid` exists → `bash .claude/scripts/context-shopify.sh`
   - `nuxt.config.*` exists → `bash .claude/scripts/context-nuxt.sh`
   - `artisan` exists → `bash .claude/scripts/context-laravel.sh`
   - `composer.json` contains `shopware/core` → `bash .claude/scripts/context-shopware.sh`
   - `package.json` contains `@storyblok` → `bash .claude/scripts/context-storyblok.sh`
   - No match → skip (only standard 3 files)

3. **Always** run this directly after agents and scripts complete:
```bash
{
  echo "PKG_HASH=$(cksum package.json 2>/dev/null | cut -d' ' -f1,2)"
  echo "TSCONFIG_HASH=$(cksum tsconfig.json 2>/dev/null | cut -d' ' -f1,2)"
  echo "GIT_HASH=$(git rev-parse HEAD 2>/dev/null)"
} > .agents/context/.state
```
4. Confirm: "Context refreshed. .state updated to $(git rev-parse --short HEAD)."

## Why step 3 is mandatory

The agent may silently skip the `.state` write. Running it here guarantees `.state` always matches reality — otherwise `context-freshness.sh` warns on every prompt forever.

## System scanners

Installed to `.claude/scripts/` by `ai-setup`. Run in < 1s, zero LLM cost. Write a system-specific `.agents/context/*.md` with frontmatter abstract — loaded automatically by `context-loader.sh` at SessionStart.
