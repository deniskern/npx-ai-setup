#!/bin/bash
# Monorepo workspace auto-discovery
# Reads package.json workspaces, pnpm-workspace.yaml, lerna.json
# Sets: WORKSPACE_GLOBS (array), WORKSPACE_PACKAGES (array of resolved dirs)

# Detect workspace package globs from known monorepo configs.
# Populates WORKSPACE_GLOBS and WORKSPACE_PACKAGES.
detect_workspaces() {
  WORKSPACE_GLOBS=()
  WORKSPACE_PACKAGES=()

  # 1. npm/yarn/bun workspaces (package.json)
  if [ -f package.json ] && command -v node >/dev/null 2>&1; then
    local ws
    ws=$(node -e "
      try {
        const p = JSON.parse(require('fs').readFileSync('package.json','utf8'));
        const ws = Array.isArray(p.workspaces) ? p.workspaces :
                   (p.workspaces && p.workspaces.packages ? p.workspaces.packages : []);
        ws.forEach(w => console.log(w));
      } catch(e) {}
    " 2>/dev/null)
    while IFS= read -r glob; do
      [ -n "$glob" ] && WORKSPACE_GLOBS+=("$glob")
    done <<< "$ws"
  fi

  # 2. pnpm-workspace.yaml
  if [ -f pnpm-workspace.yaml ] && [ ${#WORKSPACE_GLOBS[@]} -eq 0 ]; then
    local in_packages=false
    while IFS= read -r line; do
      if [[ "$line" =~ ^packages: ]]; then
        in_packages=true
        continue
      fi
      if $in_packages && [[ "$line" =~ ^[[:space:]]*-[[:space:]]+ ]]; then
        local g
        g=$(echo "$line" | sed "s/^[[:space:]]*-[[:space:]]*//" | tr -d "'\"")
        [ -n "$g" ] && WORKSPACE_GLOBS+=("$g")
      elif $in_packages && [[ "$line" =~ ^[^[:space:]-] ]]; then
        in_packages=false
      fi
    done < pnpm-workspace.yaml
  fi

  # 3. lerna.json
  if [ -f lerna.json ] && [ ${#WORKSPACE_GLOBS[@]} -eq 0 ] && command -v node >/dev/null 2>&1; then
    local lerna_ws
    lerna_ws=$(node -e "
      try {
        const p = JSON.parse(require('fs').readFileSync('lerna.json','utf8'));
        (p.packages || []).forEach(w => console.log(w));
      } catch(e) {}
    " 2>/dev/null)
    while IFS= read -r glob; do
      [ -n "$glob" ] && WORKSPACE_GLOBS+=("$glob")
    done <<< "$lerna_ws"
  fi

  [ ${#WORKSPACE_GLOBS[@]} -eq 0 ] && return 0

  # Resolve globs to actual directories
  for glob in "${WORKSPACE_GLOBS[@]}"; do
    local base="${glob%/\*}"
    if [ -d "$base" ]; then
      for dir in "$base"/*/; do
        [ -d "$dir" ] && WORKSPACE_PACKAGES+=("${dir%/}")
      done
    fi
  done
}

# Generate repo-group.json from detected workspace packages.
# Skips if file already exists (idempotent).
generate_workspace_repo_group() {
  local group_file=".agents/context/repo-group.json"
  [ -f "$group_file" ] && return 0
  [ ${#WORKSPACE_PACKAGES[@]} -eq 0 ] && return 0
  command -v jq >/dev/null 2>&1 || return 0

  mkdir -p .agents/context

  local repos_json
  repos_json=$(jq -n --arg g "$(basename "$PWD")" '{group:$g,repos:[{name:".",module:"root",path:"."}]}')

  for pkg_path in "${WORKSPACE_PACKAGES[@]}"; do
    local pkg_name="${pkg_path##*/}"
    repos_json=$(echo "$repos_json" | jq \
      --arg n "$pkg_name" \
      --arg p "$pkg_path" \
      '.repos += [{name:$n,module:$n,path:$p}]')
  done

  echo "$repos_json" > "$group_file"
  echo "  🔗 Monorepo detected (${#WORKSPACE_PACKAGES[@]} packages) — repo-group.json generated"
}
