<!-- bundle: nuxtjs v1 -->
---
abstract: "Nuxt 3 conventions: use-prefix composables, PascalCase components, kebab-case URLs, script setup."
---

# Conventions

## Naming
- Composables: `use` prefix always (`useAuth`, `useCart`)
- Components: PascalCase (`HeroSection.vue`, `ProductCard.vue`)
- Pages/routes: kebab-case (`/product-detail`, `/about-us`)
- Stores: camelCase filename, UPPER action names

## Vue Patterns
- `<script setup lang="ts">` — no Options API
- No direct DOM manipulation; use `useTemplateRef()` or template refs only
- Reactive state local to component: `ref()`/`computed()`; shared state: Pinia store
- Prefer `defineProps`/`defineEmits` compiler macros over explicit imports

## Nuxt Patterns
- Server routes: pure functions, no side-effects outside request scope
- Always use `useFetch()` or `$fetch()` — never `fetch()` directly in components
- Runtime config for all env values; no `process.env` in components
- Error handling: `throw createError({ statusCode, message })` in server handlers

## Definition of Done
- [ ] `nuxt build` passes without errors
- [ ] `eslint --fix` produces no remaining warnings
- [ ] `vue-tsc --noEmit` passes (no type errors)
- [ ] No runtime errors in dev console on page load
