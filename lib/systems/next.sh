#!/bin/bash
# System plugin: Next.js

# System plugin interface: default skills for AI-curated installation
system_get_default_skills() {
  SYSTEM_SKILLS+=(
    "vercel-labs/agent-skills@vercel-react-best-practices"
    "vercel-labs/next-skills@next-best-practices"
    "vercel-labs/next-skills@next-cache-components"
    "jeffallan/claude-skills@nextjs-developer"
    "wshobson/agents@nextjs-app-router-patterns"
    "sickn33/antigravity-awesome-skills@nextjs-best-practices"
  )
}
