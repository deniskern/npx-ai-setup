#!/bin/bash
# Skill installation: global skills + boilerplate-pulled skills
# Stack-specific skills are handled by boilerplate repos or /find-skills on demand

# Detect timeout command availability (used by install_skill)
TIMEOUT_CMD=""
command -v timeout &>/dev/null && TIMEOUT_CMD="timeout 30"
command -v gtimeout &>/dev/null && TIMEOUT_CMD="gtimeout 30"

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
  printf "\r\033[K"
  tui_success "${sid} (local template fallback)"
  return 0
}

# Install a single skill with duplicate detection and local fallback
# Uses $TIMEOUT_CMD if available
install_skill() {
  local sid=$1
  local skill_name="${sid##*@}"

  # Check if already installed (local or global)
  if [ -d ".claude/skills/$skill_name" ] || [ -d "${HOME}/.claude/skills/$skill_name" ]; then
    tui_info "${sid} (already installed)"
    return 0
  fi

  tui_spinner_start "Installing skill ${sid}"
  if ${TIMEOUT_CMD:-} npx -y skills@latest add "$sid" --agent claude-code --agent github-copilot -y </dev/null >/dev/null 2>&1; then
    tui_spinner_stop ok "${sid}"
    return 0
  else
    if install_local_skill_template "$sid"; then
      return 0
    fi
    tui_spinner_stop error "${sid} (install failed)"
    return 1
  fi
}

# Install global skills (universal, project-independent).
# Stack-specific skills come from boilerplate repos (lib/boilerplate.sh).
# Sets: $INSTALLED (number of skills installed)
run_skill_installation() {
  set +e
  echo ""
  tui_section "Shared Skills" "Installing reusable skills bundled with this setup"
  INSTALLED=0

  local GLOBAL_SKILLS=(
    "vercel-labs/agent-browser@agent-browser"
    "vercel-labs/skills@find-skills"
    "github/awesome-copilot@gh-cli"
  )

  echo ""
  tui_step "Installing skills"
  for skill_id in "${GLOBAL_SKILLS[@]}"; do
    if install_skill "$skill_id"; then
      INSTALLED=$((INSTALLED + 1))
    fi
  done

  tui_hint \
    "Run /find-skills in Claude Code to discover skills matched to your project" \
    "Skills that understand your actual codebase are more effective than generic ones."

  set -e
  return 0
}
