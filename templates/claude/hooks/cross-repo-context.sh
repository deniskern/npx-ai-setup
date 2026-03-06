#!/bin/bash
# cross-repo-context.sh — SessionStart hook
# Emits compact sibling-repo context across related repositories.
# Priority:
#   1) Explicit map: .agents/context/repo-group.json (framework-agnostic)
#   2) Fallback discovery: naming pattern sw-<module>-<suite>

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
REPO_NAME="$(basename "$PROJECT_DIR")"

resolve_path() {
  local base="$1"
  local target="$2"
  if [[ "$target" = /* ]]; then
    printf '%s\n' "$target"
    return 0
  fi
  (cd "$base" 2>/dev/null && cd "$target" 2>/dev/null && pwd) || return 1
}

repo_summary() {
  local repo="$1"
  local module="$2"
  local summary=""
  local file
  for file in "$repo/.agents/context/ROLE.md" "$repo/.agents/context/ARCHITECTURE.md" "$repo/.agents/context/STACK.md"; do
    if [ -f "$file" ]; then
      summary="$(sed -n '1,20p' "$file" | sed -E '/^[[:space:]]*$/d; /^#/d' | head -n1)"
      [ -n "$summary" ] && break
    fi
  done

  if [ -z "$summary" ]; then
    case "$module" in
      theme) summary="base storefront theme repository" ;;
      sub-theme) summary="project-specific storefront theme customizations" ;;
      plugin) summary="custom plugin and business logic repository" ;;
      shop) summary="integration/runtime repository" ;;
      frontend) summary="frontend application repository" ;;
      backend) summary="backend application repository" ;;
      api) summary="API/backend service repository" ;;
      *) summary="related project repository" ;;
    esac
  fi

  printf '%s' "$summary" | tr '\r\n' ' ' | sed 's/[[:space:]]\+/ /g' | cut -c1-180
}

emit_repo_line() {
  local repo="$1"
  local name="$2"
  local module="$3"

  local branch_info="no-git"
  if git -C "$repo" rev-parse --git-dir >/dev/null 2>&1; then
    local branch dirty state
    branch="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null)"
    dirty="$(git -C "$repo" status --porcelain -uno 2>/dev/null | head -n1)"
    state="clean"
    [ -n "$dirty" ] && state="dirty"
    branch_info="branch=${branch:-unknown},${state}"
  fi

  local marker=""
  [ "$name" = "$REPO_NAME" ] && marker=" (current)"

  printf -- "- %s%s [%s, %s]\n" "$name" "$marker" "${module:-unknown}" "$branch_info"
  printf "  context: %s\n" "$(repo_summary "$repo" "$module")"
}

# 1) Explicit repo-group map (recommended, works for any naming convention).
GROUP_FILE="$PROJECT_DIR/.agents/context/repo-group.json"
if [ -f "$GROUP_FILE" ] && command -v jq >/dev/null 2>&1; then
  GROUP_NAME="$(jq -r '.group // "workspace"' "$GROUP_FILE" 2>/dev/null)"
  ENTRY_COUNT="$(jq -r '.repos | length' "$GROUP_FILE" 2>/dev/null)"
  case "$ENTRY_COUNT" in
    ''|null|*[!0-9]*) ENTRY_COUNT=0 ;;
  esac

  if [ "$ENTRY_COUNT" -gt 0 ]; then
    printed=0
    echo "=== Cross-Repo Context (group: ${GROUP_NAME}) ==="
    while IFS= read -r entry; do
      rel_path="$(printf '%s' "$entry" | jq -r '.path // empty')"
      [ -n "$rel_path" ] || continue
      abs_path="$(resolve_path "$PROJECT_DIR" "$rel_path" || true)"
      [ -n "$abs_path" ] || continue
      [ -d "$abs_path" ] || continue

      name="$(printf '%s' "$entry" | jq -r '.name // empty')"
      module="$(printf '%s' "$entry" | jq -r '.module // empty')"

      [ -n "$name" ] || name="$(basename "$abs_path")"
      [ -n "$module" ] || module="unknown"

      emit_repo_line "$abs_path" "$name" "$module"
      printed=$((printed + 1))
    done < <(jq -c '.repos[]?' "$GROUP_FILE" 2>/dev/null)

    [ "$printed" -gt 1 ] && exit 0
    # If map exists but resolves to <=1 repo, silently continue to fallback.
  fi
fi

# 2) Fallback: Shopware suite naming like sw-theme-acme, sw-plugin-acme, ...
if [[ ! "$REPO_NAME" =~ ^sw-([a-z0-9-]+)-([a-z0-9]+)$ ]]; then
  exit 0
fi
SUITE_ID="${BASH_REMATCH[2]}"
PARENT_DIR="$(cd "$PROJECT_DIR/.." 2>/dev/null && pwd)"
[ -n "$PARENT_DIR" ] || exit 0

repos=()
while IFS= read -r repo_path; do
  repos+=("$repo_path")
done < <(find "$PARENT_DIR" -maxdepth 1 -mindepth 1 -type d -name "sw-*-${SUITE_ID}" | sort)

# If no sibling repos found, skip noise.
[ "${#repos[@]}" -gt 1 ] || exit 0

echo "=== Cross-Repo Context (suite: ${SUITE_ID}) ==="

for repo in "${repos[@]}"; do
  name="$(basename "$repo")"
  module="unknown"
  if [[ "$name" =~ ^sw-([a-z0-9-]+)-([a-z0-9]+)$ ]]; then
    module="${BASH_REMATCH[1]}"
  fi
  emit_repo_line "$repo" "$name" "$module"
done

exit 0
