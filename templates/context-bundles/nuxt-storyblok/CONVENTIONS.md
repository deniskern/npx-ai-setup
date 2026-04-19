<!-- bundle: nuxt-storyblok v1 -->
---
abstract: "Nuxt 3 conventions: use-prefix composables, PascalCase components, kebab-case URLs, v-editable directive."
---

# Conventions

## Naming
- Composables: `use` prefix always (`useStoryblok`, `useCart`)
- Components: PascalCase (`HeroSection.vue`, `ProductCard.vue`)
- Pages/routes: kebab-case (`/product-detail`, `/about-us`)
- Stores: camelCase filename, UPPER action names

## Vue Patterns
- `<script setup lang="ts">` — no Options API
- No direct DOM manipulation; use `useTemplateRef()` or `$el` only as last resort
- Reactive state local to component: `ref()`/`computed()`; shared state: Pinia store

## Storyblok
- Every Storyblok-mapped component must have `v-editable="blok"` on root element
- Access Storyblok assets via `useStoryblokImageUrl()` — not raw CDN URLs
- Never hardcode story slugs; use `useRoute().params` or passed props

## Definition of Done
- [ ] `nuxt build` passes without errors
- [ ] `eslint --fix` produces no remaining warnings
- [ ] `vue-tsc --noEmit` passes (no type errors)
- [ ] Component tested in Storyblok editor (bridge active, v-editable visible)
