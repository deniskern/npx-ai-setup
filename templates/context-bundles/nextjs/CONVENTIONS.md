<!-- bundle: nextjs v1 -->
---
abstract: "Next.js App Router conventions: use client sparingly, kebab-case files, PascalCase components, no useEffect for data."
---

# Conventions

## Naming
- Files/directories: `kebab-case` (`product-card.tsx`, `user-profile/`)
- Components: `PascalCase` (`ProductCard`, `UserAvatar`)
- Hooks: `use` prefix (`useCart`, `useSession`)
- Route segments: kebab-case (`/product-detail/[slug]`)

## Component Rules
- Default to Server Component — add `"use client"` only when required
- Triggers for `"use client"`: `useState`, `useEffect`, event handlers, browser APIs
- Never import server-only modules (DB, fs) inside `"use client"` files
- No `useEffect` for data fetching — use server component `fetch()` or SWR/React Query

## TypeScript
- Strict mode enabled — no `as any` without comment explaining why
- Prefer `interface` for object shapes, `type` for unions and primitives
- Explicit return types on all exported functions

## Definition of Done
- [ ] `next build` passes without errors
- [ ] `next lint` passes (no ESLint errors)
- [ ] `tsc --noEmit` passes
- [ ] Lighthouse Performance score >= 85 on key pages
