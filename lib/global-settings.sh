#!/bin/bash
# global-settings.sh — Installs global Claude settings, commands, and rules
# Requires: SCRIPT_DIR

CLAUDE_HOME="${HOME}/.claude"
GLOBAL_BASELINE_PERMS=("Bash(rtk:*)")
GLOBAL_OPTIONAL_BROAD_PERMS=("Bash(git:*)" "Bash(npm:*)" "Bash(npx:*)")

# ==============================================================================
# INTERNAL HELPERS
# ==============================================================================

# Copy a file only if target does not exist yet (idempotent, preserves user edits)
_gs_copy_if_missing() {
  local src="$1"
  local dest="$2"
  local label="${3:-$dest}"

  mkdir -p "$(dirname "$dest")"

  if [ ! -f "$dest" ]; then
    cp "$src" "$dest"
    tui_success "$label installed"
    return 0
  else
    tui_info "$label already exists, kept"
    return 0
  fi
}

# ==============================================================================
# GLOBAL settings.json
# Installs a narrow workstation baseline and only adds broader shell grants
# when the operator explicitly opts in.
# ==============================================================================
_gs_json_merge_permissions() {
  local target="$1"
  local broad_opt_in="$2"

  if ! command -v node &>/dev/null; then
    tui_warn "~/.claude/settings.json skipped merge (node not found)"
    return 1
  fi

  node - "$target" "$broad_opt_in" <<'NODESCRIPT'
const fs = require('fs');
const path = process.argv[2];
const broadOptIn = process.argv[3] === '1';
let cfg = {};
try { cfg = JSON.parse(fs.readFileSync(path, 'utf8')); } catch (e) {
  process.stderr.write('ERROR: ' + path + ' is not valid JSON: ' + e.message + '\n');
  process.exit(1);
}
cfg.permissions = cfg.permissions || {};
cfg.permissions.allow = cfg.permissions.allow || [];
cfg.permissions.deny = cfg.permissions.deny || [];
cfg._governanceOwnership = cfg._governanceOwnership || 'Global settings stay workstation-local. Broad shell grants are optional operator choices.';
cfg._governanceProfile = cfg._governanceProfile || 'global-baseline';
cfg._governanceOptionalBroadShellGrants = broadOptIn;

const baseline = ['Bash(rtk:*)'];
const optionalBroad = ['Bash(git:*)', 'Bash(npm:*)', 'Bash(npx:*)'];

for (const p of baseline) {
  if (!cfg.permissions.allow.includes(p)) cfg.permissions.allow.push(p);
}
if (broadOptIn) {
  for (const p of optionalBroad) {
    if (!cfg.permissions.allow.includes(p)) cfg.permissions.allow.push(p);
  }
}

if (!cfg.statusLine) {
  cfg.statusLine = '{cwd} | {gitBranch} | claude';
}

fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + '\n');
NODESCRIPT
}

_install_global_settings_json() {
  local target="${CLAUDE_HOME}/settings.json"
  local broad_opt_in="${AI_SETUP_ENABLE_GLOBAL_BROAD_PERMS:-0}"
  mkdir -p "$CLAUDE_HOME"

  # Build the baseline settings object
  local base_settings
  base_settings=$(cat <<EOF
{
  "_governanceProfile": "global-baseline",
  "_governanceOwnership": "Global settings stay workstation-local. Broad shell grants are optional operator choices.",
  "_governanceOptionalBroadShellGrants": $( [ "$broad_opt_in" = "1" ] && echo true || echo false ),
  "permissions": {
    "allow": [
      "Bash(rtk:*)"
    ],
    "deny": []
  },
  "statusLine": "{cwd} | {gitBranch} | claude"
}
EOF
)

  if [ ! -f "$target" ]; then
    echo "$base_settings" > "$target"
    if [ "$broad_opt_in" = "1" ]; then
      _gs_json_merge_permissions "$target" "$broad_opt_in" >/dev/null || true
      tui_success "~/.claude/settings.json created with optional broad shell grants"
    else
      tui_success "~/.claude/settings.json created"
      tui_info "Global broad shell grants skipped — opt in with AI_SETUP_ENABLE_GLOBAL_BROAD_PERMS=1"
    fi
    return 0
  fi

  _gs_json_merge_permissions "$target" "$broad_opt_in" || return 0
  tui_success "~/.claude/settings.json baseline merged"
  if [ "$broad_opt_in" = "1" ]; then
    tui_info "Optional broad shell grants enabled for this workstation"
  else
    tui_info "Optional broad shell grants left disabled"
  fi
}

# ==============================================================================
# GLOBAL COMMANDS
# Installs commit.md, pr.md from templates/commands/ to ~/.claude/commands/
# ==============================================================================
_install_global_commands() {
  local cmd_src="${SCRIPT_DIR}/templates/commands"
  local cmd_dest="${CLAUDE_HOME}/commands"

  # Only install the workflow-critical global commands, not all project commands
  local GLOBAL_COMMANDS=("commit.md" "pr.md")

  for cmd in "${GLOBAL_COMMANDS[@]}"; do
    local src="${cmd_src}/${cmd}"
    local dest="${cmd_dest}/${cmd}"
    if [ -f "$src" ]; then
      _gs_copy_if_missing "$src" "$dest" "~/.claude/commands/${cmd}"
    fi
  done
}

# ==============================================================================
# GLOBAL RULES
# Installs general.md, git.md from templates/claude/rules/ to ~/.claude/rules/
# ==============================================================================
_install_global_rules() {
  local rules_src="${SCRIPT_DIR}/templates/claude/rules"
  local rules_dest="${CLAUDE_HOME}/rules"

  local GLOBAL_RULES=("general.md" "git.md")

  for rule in "${GLOBAL_RULES[@]}"; do
    local src="${rules_src}/${rule}"
    local dest="${rules_dest}/${rule}"
    if [ -f "$src" ]; then
      _gs_copy_if_missing "$src" "$dest" "~/.claude/rules/${rule}"
    fi
  done
}

# ==============================================================================
# STATUSLINE CONFIG
# Adds statusLine entry to ~/.claude/settings.json if not already present.
# Governance metadata is handled by _install_global_settings_json.
# ==============================================================================
_install_statusline_config() {
  local target="${CLAUDE_HOME}/settings.json"

  if [ ! -f "$target" ]; then
    return 0
  fi

  if grep -q '"statusLine"' "$target" 2>/dev/null; then
    tui_info "statusLine config already set, kept"
    return 0
  fi

  if command -v node &>/dev/null; then
    node - "$target" <<'NODESCRIPT'
const fs = require('fs');
const path = process.argv[2];
let cfg = {};
try { cfg = JSON.parse(fs.readFileSync(path, 'utf8')); } catch(e) {
  process.stderr.write('ERROR: ' + path + ' is not valid JSON: ' + e.message + '\\n');
  process.exit(1);
}
if (!cfg.statusLine) {
  cfg.statusLine = "{cwd} | {gitBranch} | claude";
}
fs.writeFileSync(path, JSON.stringify(cfg, null, 2) + '\n');
NODESCRIPT
    tui_success "statusLine config added"
  fi
}

# ==============================================================================
# PUBLIC: check_global_settings (--check mode, no writes)
# ==============================================================================
check_global_settings() {
  _check_item() {
    local label="$1"
    local path="$2"
    if [ -f "$path" ]; then
      tui_success "$label"
    else
      tui_warn "$label not installed"
    fi
  }

  _check_item "~/.claude/settings.json"           "${CLAUDE_HOME}/settings.json"
  _check_item "~/.claude/commands/commit.md"       "${CLAUDE_HOME}/commands/commit.md"
  _check_item "~/.claude/commands/pr.md"           "${CLAUDE_HOME}/commands/pr.md"
  _check_item "~/.claude/rules/general.md"         "${CLAUDE_HOME}/rules/general.md"
  _check_item "~/.claude/rules/git.md"             "${CLAUDE_HOME}/rules/git.md"

  # Check permissions in settings.json
  if [ -f "${CLAUDE_HOME}/settings.json" ]; then
    if grep -q '"Bash(rtk:\*)"' "${CLAUDE_HOME}/settings.json" 2>/dev/null; then
      tui_success "global baseline permissions in settings.json"
    else
      tui_warn "global baseline permissions not set in settings.json"
    fi
    if grep -q '"_governanceProfile"[[:space:]]*:[[:space:]]*"global-baseline"' "${CLAUDE_HOME}/settings.json" 2>/dev/null; then
      tui_success "global governance metadata"
    else
      tui_warn "global governance metadata missing"
    fi
    if grep -q '"statusLine"' "${CLAUDE_HOME}/settings.json" 2>/dev/null; then
      tui_success "statusLine config"
    else
      tui_warn "statusLine not configured"
    fi
  fi
}

# ==============================================================================
# DELTA GIT CONFIG
# Configures delta as git pager/diff tool — idempotent, only when delta is installed
# ==============================================================================
_install_delta_config() {
  if ! command -v delta &>/dev/null; then
    return 0
  fi

  local already_set
  already_set=$(git config --global core.pager 2>/dev/null)
  if [ "$already_set" = "delta" ]; then
    tui_info "delta git config already set, kept"
    return 0
  fi

  git config --global core.pager delta
  git config --global interactive.diffFilter "delta --color-only"
  git config --global delta.navigate true
  git config --global delta.side-by-side false
  git config --global merge.conflictstyle diff3
  git config --global diff.colorMoved default
  tui_success "delta configured as git pager"
}

# ==============================================================================
# PUBLIC: install_global_settings
# ==============================================================================
install_global_settings() {
  _install_global_settings_json
  _install_global_commands
  _install_global_rules
  _install_statusline_config
  _install_delta_config
}
