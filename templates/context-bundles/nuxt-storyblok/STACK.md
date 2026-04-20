<!-- bundle: nuxt-storyblok v1 -->
---
abstract: "Nuxt 3 + Vue 3 + TypeScript + Storyblok headless CMS. SSR/ISR, Tailwind CSS, Pinia state, Vite build."
---

# Stack

## Runtime & Distribution
- Node 18+, npm or pnpm, Vite (via Nuxt)
- Deploy targets: Vercel, Netlify, Node server, static export

## Framework & Dependencies
- Nuxt 3 (auto-imports, composables, server routes)
- Vue 3 (Composition API, `<script setup>`)
- TypeScript strict mode
- @storyblok/nuxt (bridge, richtext, image service)
- Tailwind CSS via @nuxtjs/tailwindcss
- Pinia for global state

## Build & Tooling
- `nuxt build` → production; `nuxt generate` → static
- ESLint + @nuxtjs/eslint-config-typescript
- Vue TSC (`vue-tsc --noEmit`) for type checking
