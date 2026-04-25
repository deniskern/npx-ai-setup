# Context-Scan Reference

Spawn the `context-scanner` subagent **before** Phase 1b clarifying questions.

```
Agent({
  description: "Scan project context + stack",
  subagent_type: "context-scanner",
  model: "haiku"
})
```

Use the returned `stack_profile` and key versions to:
- Pre-fill the Stack Coverage AskUserQuestion with the detected profile as default
- Inform Phase 1d sketch (which files to touch per stack)
- Surface missing context files as a warning

If `lib/detect-stack.sh` is absent (non-npx-ai-setup target), infer stack from file patterns:
- `nuxt.config.*` → nuxt-storyblok or nuxtjs
- `shopify.theme.toml` / sections/*.liquid → shopify-liquid
- `artisan` / `composer.json` → laravel
- `next.config.*` → nextjs
- Default → generic
