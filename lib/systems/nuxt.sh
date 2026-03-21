#!/bin/bash
# System plugin: Nuxt

# System plugin interface: default skills for AI-curated installation
system_get_default_skills() {
  SYSTEM_SKILLS+=(
    "antfu/skills@nuxt"
    "onmax/nuxt-skills@nuxt"
    "onmax/nuxt-skills@vue"
    "onmax/nuxt-skills@vueuse"
    "vuejs-ai/skills@vue-best-practices"
    "vuejs-ai/skills@vue-testing-best-practices"
  )
  # Only add nuxt-ui skill if project actually uses it
  if [[ " ${KEYWORDS[*]} " =~ " nuxt-ui " ]]; then
    SYSTEM_SKILLS+=("nuxt/ui@nuxt-ui")
  fi
}
