#!/bin/bash
# Compatibility layers and config file installation
# Handles: OpenCode, Copilot, claudeignore, statusline
# Requires: core.sh ($TPL), setup.sh (_install_or_update_file)

# Install all GitHub templates (copilot instructions + workflows)
install_copilot() {
  mkdir -p .github
  while IFS= read -r -d '' _gh_path; do
    local _rel="${_gh_path#$TPL/github/}"
    local _target=".github/$_rel"
    _install_or_update_file "$_gh_path" "$_target"
  done < <(find "$TPL/github" -type f -print0 | sort -z)
}

# Map Claude Code model shorthand to OpenCode provider/model format
_oc_model() {
  case "$1" in
    haiku)  echo "anthropic/claude-haiku-4-5" ;;
    opus)   echo "anthropic/claude-opus-4-6" ;;
    *)      echo "anthropic/claude-sonnet-4-6" ;;
  esac
}

# Generate opencode.json for OpenCode compatibility
# Translates agents, commands, MCP servers from Claude Code format
generate_opencode_config() {
  if [ -f opencode.json ]; then
    echo "  opencode.json already exists, skipping."
    return 0
  fi

  command -v jq &>/dev/null || return 0

  # MCP servers from .mcp.json
  local mcp_block="{}"
  if [ -f .mcp.json ]; then
    mcp_block=$(jq '.mcpServers // {}' .mcp.json 2>/dev/null || echo "{}")
  fi

  # Agents from .claude/agents/*.md
  local agents_json="{}"
  if [ -d .claude/agents ]; then
    for agent_file in .claude/agents/*.md; do
      [ -f "$agent_file" ] || continue
      local aname amodel adesc atools
      aname=$(basename "$agent_file" .md)
      # Extract frontmatter fields (awk for macOS/BSD compat)
      adesc=$(awk '/^---$/{n++; next} n==1 && /^description:/{sub(/^description: */, ""); print}' "$agent_file" | head -1)
      amodel=$(awk '/^---$/{n++; next} n==1 && /^model:/{sub(/^model: */, ""); print}' "$agent_file" | head -1)
      atools=$(awk '/^---$/{n++; next} n==1 && /^tools:/{sub(/^tools: */, ""); print}' "$agent_file" | head -1)

      [ -z "$adesc" ] && adesc="$aname agent"

      # Map tools to OpenCode permissions
      local t_read=false t_write=false t_bash=false
      case "$atools" in *Read*|*Glob*|*Grep*) t_read=true ;; esac
      case "$atools" in *Write*|*Edit*) t_write=true ;; esac
      case "$atools" in *Bash*) t_bash=true ;; esac

      agents_json=$(printf '%s' "$agents_json" | jq -c \
        --arg name "$aname" \
        --arg desc "$adesc" \
        --arg model "$(_oc_model "$amodel")" \
        --arg file "$agent_file" \
        --argjson r "$t_read" --argjson w "$t_write" --argjson b "$t_bash" \
        '.[$name] = {
          "description": $desc,
          "mode": "subagent",
          "model": $model,
          "prompt": ("{file:" + $file + "}"),
          "tools": {"read": $r, "write": $w, "edit": $w, "bash": $b}
        }')
    done
  fi

  # Commands from .claude/commands/*.md
  local commands_json="{}"
  if [ -d .claude/commands ]; then
    for cmd_file in .claude/commands/*.md; do
      [ -f "$cmd_file" ] || continue
      local cname cmodel
      cname=$(basename "$cmd_file" .md)
      cmodel=$(awk '/^---$/{n++; next} n==1 && /^model:/{sub(/^model: */, ""); print}' "$cmd_file" | head -1)

      # Derive description from filename (kebab-case to words)
      local cdesc
      cdesc=$(echo "$cname" | tr '-' ' ')

      commands_json=$(printf '%s' "$commands_json" | jq -c \
        --arg name "$cname" \
        --arg desc "$cdesc" \
        --arg file "$cmd_file" \
        '.[$name] = {"description": $desc, "template": ("{file:" + $file + "}\\n\\n$ARGUMENTS")}')
    done
  fi

  # Assemble final config
  jq -n \
    --arg schema "https://opencode.ai/config.json" \
    --arg model "anthropic/claude-sonnet-4-6" \
    --arg small "anthropic/claude-haiku-4-5" \
    --argjson mcp "$mcp_block" \
    --argjson agents "$agents_json" \
    --argjson commands "$commands_json" \
    '{
      "$schema": $schema,
      "model": $model,
      "small_model": $small,
      "instructions": ["CLAUDE.md"],
      "mcp": $mcp,
      "agent": $agents,
      "command": $commands
    }' > opencode.json 2>/dev/null

  if [ -f opencode.json ]; then
    local ac=0 cc=0
    ac=$(echo "$agents_json" | jq 'keys | length' 2>/dev/null || echo 0)
    cc=$(echo "$commands_json" | jq 'keys | length' 2>/dev/null || echo 0)
    echo "  opencode.json created ($ac agents, $cc commands, OpenCode compatibility)"
  fi
}

# Install .claudeignore with universal patterns.
# Idempotent: merges new patterns into existing file, never removes user entries.
install_claudeignore() {
  if [ ! -f .claudeignore ]; then
    cp "$TPL/.claudeignore" .claudeignore
    echo "  📄 .claudeignore installed ($(wc -l < .claudeignore | tr -d ' ') patterns)"
  else
    # Merge: append template patterns not already present
    local added=0
    while IFS= read -r line; do
      # Skip comments and blank lines for dedup check
      [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
      if ! grep -qxF "$line" .claudeignore 2>/dev/null; then
        echo "$line" >> .claudeignore
        added=$((added + 1))
      fi
    done < "$TPL/.claudeignore"
    [ "$added" -gt 0 ] && echo "  📄 .claudeignore updated (+$added patterns)"
  fi

}

# Install statusline script globally from bundled template.
install_statusline_project() {
  local src="$TPL/scripts/statusline.sh"
  local dest="${CLAUDE_HOME}/statusline.sh"
  local settings="${CLAUDE_HOME}/settings.json"

  if [ ! -f "$src" ]; then
    tui_warn "statusline template not found: $src"
    return 0
  fi

  if ! mkdir -p "${CLAUDE_HOME}" 2>/dev/null; then
    tui_warn "Statusline skipped: cannot create ${CLAUDE_HOME}"
    return 0
  fi

  if ! cp "$src" "$dest" 2>/dev/null; then
    tui_warn "Statusline skipped: cannot write ${dest}"
    return 0
  fi
  chmod +x "$dest" 2>/dev/null || true

  # Register in settings.json
  if [ -f "$settings" ] && command -v node &>/dev/null; then
    if ! node - "$settings" "$dest" <<'NODESCRIPT'
const fs = require('fs');
const cfg_path = process.argv[2];
const script = process.argv[3];
let cfg = {};
try { cfg = JSON.parse(fs.readFileSync(cfg_path, 'utf8')); } catch(e) { process.exit(1); }
cfg.statusLine = script;
fs.writeFileSync(cfg_path, JSON.stringify(cfg, null, 2) + '\n');
NODESCRIPT
    then
      tui_warn "Statusline installed, but could not update ${settings}"
    fi
  fi

  tui_success "Statusline installed -> ${dest}"
  return 0
}
