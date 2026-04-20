<!-- bundle: nuxt-storyblok v1 -->
---
abstract: "Nuxt 3 app/ structure with Storyblok bridge. Pages driven by Storyblok stories; SSR/ISR via route rules."
---

# Architecture

## Directory Structure
- `app/` or project root: `pages/`, `components/`, `composables/`, `layouts/`, `middleware/`
- `storyblok/` — Storyblok component resolvers (maps content type to Vue component)
- `stores/` — Pinia stores for cart, user, UI state
- `server/api/` — Nuxt server routes (proxy, webhooks, revalidation)
- `public/` — static assets; `assets/` — processed by Vite

## Data Flow
1. Storyblok CDN → `useStoryblok()` composable fetches story JSON
2. Bridge injects live-preview script in Storyblok editor context
3. Story content mapped to Vue components via `<StoryblokComponent>`
4. SSR renders on server; ISR via `routeRules` in `nuxt.config.ts`

## Key Patterns
- i18n: `@nuxtjs/i18n` with Storyblok per-language stories or field-level translation
- Image optimization: `@storyblok/nuxt` `useStoryblokImageUrl()` helper
- Route rules: `{ '/blog/**': { isr: 3600 } }` for content-heavy pages
