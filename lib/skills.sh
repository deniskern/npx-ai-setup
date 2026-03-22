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

# Install global skills (universal, project-independent).
# Stack-specific skills come from boilerplate repos (lib/boilerplate.sh).
# Sets: $INSTALLED (number of skills installed)
run_skill_installation() {
  set +e
  echo ""
  echo "🔌 Installing global skills..."
  INSTALLED=0

  local GLOBAL_SKILLS=(
    "vercel-labs/agent-browser@agent-browser"
    "vercel-labs/skills@find-skills"
    "github/awesome-copilot@gh-cli"
  )

  echo ""
  echo "  📦 Installing skills..."

  # Install in parallel; tally results after all complete
  local tmpdir
  tmpdir=$(mktemp -d)
  local pids=()

  for skill_id in "${GLOBAL_SKILLS[@]}"; do
    (
      install_skill "$skill_id"
      echo $? > "$tmpdir/$(printf '%s' "$skill_id" | tr -cd 'a-zA-Z0-9_-').exit"
    ) &
    pids+=($!)
  done

  for pid in "${pids[@]}"; do
    wait "$pid" 2>/dev/null || true
  done

  for skill_id in "${GLOBAL_SKILLS[@]}"; do
    local safe_id
    safe_id=$(printf '%s' "$skill_id" | tr -cd 'a-zA-Z0-9_-')
    local exit_code
    exit_code=$(cat "$tmpdir/${safe_id}.exit" 2>/dev/null || echo "1")
    if [ "$exit_code" = "0" ]; then
      INSTALLED=$((INSTALLED + 1))
    fi
  done
  rm -rf "$tmpdir"

  echo ""
  echo "  💡 Run /find-skills in Claude Code to discover skills matched to your project."
  echo "     Skills that understand your actual codebase are more effective than generic ones."

  set -e
  return 0
}
