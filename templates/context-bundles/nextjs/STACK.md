<!-- bundle: nextjs v1 -->
---
abstract: "Next.js 14+ App Router, React 18, TypeScript, Tailwind CSS. Vercel deployment, Node 18+."
---

# Stack

## Runtime & Distribution
- Node 18+, npm or pnpm
- Deploy target: Vercel (primary), Docker, or static export

## Framework & Dependencies
- Next.js 14+ with App Router (`app/` directory)
- React 18 (Server Components default, Client Components opt-in)
- TypeScript strict mode
- Tailwind CSS via PostCSS
- SWR or React Query for client-side data fetching

## Build & Tooling
- `next dev` → development; `next build` → production bundle
- ESLint via `next lint`
- `tsc --noEmit` for type checking
- Lighthouse CI for performance auditing
