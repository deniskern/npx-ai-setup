#!/bin/bash
# Skill curation and installation
# Network discovery removed — use /find-skills for on-demand search

SKILL_PATTERN='^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+@[a-zA-Z0-9_.-]+'

# Detect timeout command availability (used by install_skill)
TIMEOUT_CMD=""
command -v timeout &>/dev/null && TIMEOUT_CMD="timeout 30"
command -v gtimeout &>/dev/null && TIMEOUT_CMD="gtimeout 30"

# Returns space-separated skill IDs curated from the skills.sh directory.
# Bash 3.2 safe (no declare -A). Update this list when new skills are published.
get_keyword_skills() {
  local kw="$1"
  case "$kw" in
    vue)        echo "vuejs-ai/skills@vue-best-practices antfu/skills@vue" ;;
    react)      echo "0xbigboss/claude-code@react-best-practices wshobson/agents@react-state-management" ;;
    typescript) echo "wshobson/agents@typescript-advanced-types sickn33/antigravity-awesome-skills@typescript-expert" ;;
    shadcn)     echo "google-labs-code/stitch-skills@shadcn-ui" ;;
    playwright) echo "" ;;  # universal skill, installed for all projects
    prisma)     echo "sickn33/antigravity-awesome-skills@prisma-expert" ;;
    supabase)   echo "supabase/agent-skills@supabase-postgres-best-practices" ;;
    nestjs)     echo "kadajett/agent-nestjs-skills@nestjs-best-practices" ;;
    svelte)     echo "ejirocodes/agent-skills@svelte5-best-practices" ;;
    angular)    echo "analogjs/angular-skills@angular-component analogjs/angular-skills@angular-signals" ;;
    nuxt-ui)    echo "" ;;  # handled conditionally in system skills (nuxt case)
    vitest)     echo "antfu/skills@vitest" ;;
    pinia)      echo "vuejs-ai/skills@vue-pinia-best-practices" ;;
    tanstack)   echo "jezweb/claude-skills@tanstack-query" ;;
    tailwind)   echo "wshobson/agents@tailwind-design-system" ;;
    express)    echo "wshobson/agents@nodejs-backend-patterns" ;;
    hono)       echo "elysiajs/skills@elysiajs" ;;
    firebase)      echo "" ;;
    reka-ui)       echo "" ;;
    primevue)      echo "" ;;
    vuetify)       echo "" ;;
    element-plus)  echo "" ;;
    quasar)        echo "" ;;
    *)             echo "" ;;
  esac
}

# Install bundled local skill template as fallback when registry/network install is unavailable.
# Returns 0 when fallback was installed, 1 when no local template exists.
install_local_skill_template() {
  local sid="$1"
  local skill_name="${sid##*@}"
  local local_template="$SCRIPT_DIR/templates/skills/$skill_name/SKILL.md"
  local local_target_dir=".claude/skills/$skill_name"

  [ -f "$local_template" ] || return 1
  mkdir -p "$local_target_dir"
  cp "$local_template" "$local_target_dir/SKILL.md"
  printf "\r     ✅ %s (local template fallback)\n" "$sid"
  return 0
}

# Install a single skill with duplicate detection and local fallback
# Uses $TIMEOUT_CMD if available
install_skill() {
  local sid=$1
  local skill_name="${sid##*@}"

  # Check if already installed (local or global)
  if [ -d ".claude/skills/$skill_name" ] || [ -d "${HOME}/.claude/skills/$skill_name" ]; then
    printf "     ⏭️  %s (already installed)\n" "$sid"
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi

  printf "     ⏳ %s ..." "$sid"
  if ${TIMEOUT_CMD:-} npx -y skills@latest add "$sid" --agent claude-code --agent github-copilot -y </dev/null >/dev/null 2>&1; then
    printf "\r     ✅ %s\n" "$sid"
    return 0
  else
    if install_local_skill_template "$sid"; then
      return 0
    fi
    printf "\r     ❌ %s (install failed)\n" "$sid"
    return 1
  fi
}
