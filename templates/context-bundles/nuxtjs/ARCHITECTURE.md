<!-- bundle: nuxtjs v1 -->
---
abstract: "Nuxt 3 app/ structure with pages, components, composables, server routes. Vite bundler, SSR/ISR via route rules."
---

# Architecture

## Directory Structure
- `app/` or project root: `pages/`, `components/`, `composables/`, `layouts/`, `middleware/`
- `stores/` — Pinia stores
- `server/api/` — Nuxt server routes (REST, webhooks)
- `server/middleware/` — global request middleware
- `public/` — static assets; `assets/` — processed by Vite
- `plugins/` — Nuxt plugins (client/server/universal)

## Data Flow
1. External APIs or database reached via `server/api/` handlers
2. Pages use `useFetch()` / `$fetch()` composables to hit own `server/api/`
3. SSR renders on server; client hydrates and takes over
4. ISR/SWR via `routeRules` in `nuxt.config.ts`

## Key Patterns
- Composables auto-imported from `composables/`
- Components auto-imported from `components/` (PascalCase or nested dirs)
- Server utils shared via `server/utils/`
- Runtime config: `useRuntimeConfig()` for env-driven values
- Route rules: `{ '/blog/**': { isr: 3600 } }` for content-heavy pages
