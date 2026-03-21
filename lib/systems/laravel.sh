#!/bin/bash
# System plugin: Laravel

# System plugin interface: default skills for AI-curated installation
system_get_default_skills() {
  SYSTEM_SKILLS+=(
    "jeffallan/claude-skills@laravel-specialist"
    "iserter/laravel-claude-agents@eloquent-best-practices"
  )
}
