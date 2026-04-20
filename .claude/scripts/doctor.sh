#!/usr/bin/env bash
# doctor.sh — Health check for Claude Code AI setup
# Usage: bash .claude/scripts/doctor.sh
# Requires: bash 3.2+, git
set -euo pipefail

PASS="[OK]"
FAIL="[FAIL]"
WARN="[WARN]"

SETTINGS_FILE=".claude/settings.json"
KNOWN_CURRENT_MODELS="
claude-opus-4-6
claude-sonnet-4-6
claude-haiku-4-6
"

ok=0
fail=0
warn=0
rows=""

add_row() {
  local status="$1" label="$2" detail="$3"
  rows="${rows}${status}|${label}|${detail}"$'\n'
  case "$status" in
    "$PASS") ok=$((ok + 1)) ;;
    "$FAIL") fail=$((fail + 1)) ;;
    "$WARN") warn=$((warn + 1)) ;;
  esac
}

is_known_current_model() {
  local candidate="$1"
  local known_model

  while IFS= read -r known_model; do
    [ -z "$known_model" ] && continue
    if [ "$candidate" = "$known_model" ]; then
      return 0
    fi
  done <<EOF
$KNOWN_CURRENT_MODELS
EOF

  return 1
}

check_model_version() {
  local model=""

  if [ ! -f "$SETTINGS_FILE" ]; then
    add_row "$WARN" "Model version" "settings.json missing — skipping model freshness check"
    return 0
  fi

  if command -v python3 >/dev/null 2>&1; then
    if model="$(python3 -c 'import json,sys; path=sys.argv[1]; data=json.load(open(path)); print(data.get("model",""))' "$SETTINGS_FILE" 2>/dev/null)"; then
      :
    else
      add_row "$WARN" "Model version" "Cannot read model from settings.json — invalid JSON"
      return 0
    fi
  elif command -v jq >/dev/null 2>&1; then
    if model="$(jq -r '.model // empty' "$SETTINGS_FILE" 2>/dev/null)"; then
      :
    else
      add_row "$WARN" "Model version" "Cannot read model from settings.json"
      return 0
    fi
  else
    add_row "$WARN" "Model version" "Cannot inspect model — python3 and jq both missing"
    return 0
  fi

  if [ -z "$model" ]; then
    add_row "$WARN" "Model version" "No model configured in settings.json"
    return 0
  fi

  if is_known_current_model "$model"; then
    add_row "$PASS" "Model version" "$model recognized as current"
  else
    add_row "$WARN" "Model version" "$model is not in KNOWN_CURRENT_MODELS"
  fi
}

# 1. Hooks directory exists
if [ -d ".claude/hooks" ]; then
  hooks_list="$(find .claude/hooks -name "*.sh" 2>/dev/null)"
  count="$(printf '%s\n' "$hooks_list" | grep -c '.' 2>/dev/null || echo 0)"
  if [ "$count" -gt 0 ]; then
    add_row "$PASS" "Hooks"               "${count} hook script(s) found"
  else
    add_row "$FAIL" "Hooks"               ".claude/hooks/ missing or empty"
  fi
else
  add_row "$FAIL" "Hooks"               ".claude/hooks/ missing or empty"
fi

# 2. Hooks are executable
if [ -d ".claude/hooks" ]; then
  non_exec="$(find .claude/hooks -name "*.sh" ! -perm -u+x 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$non_exec" = "0" ]; then
    add_row "$PASS" "Hooks executable"   "All hook scripts are +x"
  else
    add_row "$FAIL" "Hooks executable"   "${non_exec} hook(s) not executable (chmod +x)"
  fi
fi

# 3. settings.json valid JSON
if [ -f "$SETTINGS_FILE" ]; then
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import json,sys; json.load(open(sys.argv[1]))" "$SETTINGS_FILE" 2>/dev/null; then
      add_row "$PASS" "settings.json"    "Valid JSON"
    else
      add_row "$FAIL" "settings.json"    "Invalid JSON — run: python3 -m json.tool $SETTINGS_FILE"
    fi
  elif command -v jq >/dev/null 2>&1; then
    if jq empty "$SETTINGS_FILE" 2>/dev/null; then
      add_row "$PASS" "settings.json"    "Valid JSON"
    else
      add_row "$FAIL" "settings.json"    "Invalid JSON"
    fi
  else
    add_row "$WARN" "settings.json"    "Cannot validate — python3 and jq both missing"
  fi
else
  add_row "$FAIL" "settings.json"      "$SETTINGS_FILE not found"
fi

# 4. Model version
check_model_version

# 5. CLAUDE.md present
if [ -f "CLAUDE.md" ]; then
  lines="$(wc -l < CLAUDE.md | tr -d ' ')"
  add_row "$PASS" "CLAUDE.md"           "Present (${lines} lines)"
else
  add_row "$FAIL" "CLAUDE.md"           "CLAUDE.md not found"
fi

# 6. CLAUDE.md size guard (>200 lines is a smell)
if [ -f "CLAUDE.md" ]; then
  lines="$(wc -l < CLAUDE.md | tr -d ' ')"
  if [ "$lines" -gt 200 ]; then
    add_row "$WARN" "CLAUDE.md size"    "${lines} lines — consider trimming (token cost)"
  else
    add_row "$PASS" "CLAUDE.md size"    "${lines} lines (OK)"
  fi
fi

# 7. Context files
context_found=0
for f in STACK.md ARCHITECTURE.md CONVENTIONS.md; do
  [ -f ".agents/context/$f" ] && context_found=$((context_found + 1))
done
if [ "$context_found" -eq 3 ]; then
  add_row "$PASS" "Context files"       "STACK, ARCHITECTURE, CONVENTIONS present"
elif [ "$context_found" -gt 0 ]; then
  add_row "$WARN" "Context files"       "${context_found}/3 present — run the update flow and choose Regenerate"
else
  add_row "$WARN" "Context files"       "None found in .agents/context/ — run the update flow and choose Regenerate"
fi

# 8. .mcp.json present
if [ -f ".mcp.json" ]; then
  add_row "$PASS" "MCP config"          ".mcp.json found"
else
  add_row "$WARN" "MCP config"          ".mcp.json not found (optional)"
fi

# 9. Skills directory
if [ -d ".claude/skills" ]; then
  count="$(find .claude/skills -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')"
  ref_count="$(find .claude/skills -path "*/references/*.md" 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$count" -gt 0 ]; then
    if [ "$ref_count" -gt 0 ]; then
      add_row "$PASS" "Skills"              "${count} skill(s) installed, ${ref_count} reference file(s)"
    else
      add_row "$PASS" "Skills"              "${count} skill(s) installed"
    fi
  else
    add_row "$WARN" "Skills"              "No skills found in .claude/skills/"
  fi
else
  add_row "$WARN" "Skills"              "No skills found in .claude/skills/"
fi

# 10. Skills YAML frontmatter validation
if [ -d ".claude/skills" ]; then
  yaml_errors=0
  yaml_details=""
  while IFS= read -r skill_file; do
    [ -z "$skill_file" ] && continue
    skill_name="$(basename "$(dirname "$skill_file")")"
    # Check for name field
    if ! grep -q '^name:' "$skill_file" 2>/dev/null; then
      yaml_errors=$((yaml_errors + 1))
      yaml_details="${yaml_details}${skill_name}(no name) "
    fi
    # Check for description field
    if ! grep -q '^description:' "$skill_file" 2>/dev/null; then
      yaml_errors=$((yaml_errors + 1))
      yaml_details="${yaml_details}${skill_name}(no description) "
    # Check for unquoted colons in description value
    elif grep -q '^description: [^"].*:' "$skill_file" 2>/dev/null; then
      yaml_errors=$((yaml_errors + 1))
      yaml_details="${yaml_details}${skill_name}(unquoted colon) "
    fi
  done < <(find .claude/skills -name "SKILL.md" 2>/dev/null)
  if [ "$yaml_errors" -eq 0 ]; then
    add_row "$PASS" "Skills YAML"          "All skill frontmatter valid"
  else
    add_row "$FAIL" "Skills YAML"          "${yaml_errors} issue(s): ${yaml_details}"
  fi
fi

# 10b. Skills reference file integrity
if [ -d ".claude/skills" ]; then
  ref_errors=0
  ref_details=""
  while IFS= read -r skill_file; do
    [ -z "$skill_file" ] && continue
    skill_dir="$(dirname "$skill_file")"
    skill_name="$(basename "$skill_dir")"
    # Find @references/ links in SKILL.md
    while IFS= read -r ref_path; do
      [ -z "$ref_path" ] && continue
      full_path="${skill_dir}/references/${ref_path}"
      if [ ! -f "$full_path" ]; then
        ref_errors=$((ref_errors + 1))
        ref_details="${ref_details}${skill_name}/${ref_path} "
      fi
    done < <(grep -oE '@references/[A-Za-z0-9_./-]+' "$skill_file" 2>/dev/null | sed 's|^@references/||' || true)
  done < <(find .claude/skills -name "SKILL.md" 2>/dev/null)
  if [ "$ref_errors" -eq 0 ]; then
    add_row "$PASS" "Skill refs"           "All skill reference files present"
  else
    add_row "$FAIL" "Skill refs"           "${ref_errors} missing: ${ref_details}"
  fi
fi

# 11. Claude scripts directory
if [ -d ".claude/scripts" ]; then
  count="$(find .claude/scripts -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')"
  add_row "$PASS" "Claude scripts"      "${count} script(s) in .claude/scripts/"
else
  add_row "$WARN" "Claude scripts"      ".claude/scripts/ not present"
fi

# 12. git config user.email set
if command -v git >/dev/null 2>&1; then
  git_email="$(git config user.email 2>/dev/null || true)"
  if [ -n "$git_email" ]; then
    add_row "$PASS" "git user.email"    "$git_email"
  else
    add_row "$FAIL" "git user.email"    "Not set — run: git config user.email you@example.com"
  fi
else
  add_row "$FAIL" "git"                 "git not found in PATH"
fi

# 13. .ai-setup.json metadata present
if [ -f ".ai-setup.json" ]; then
  if command -v jq >/dev/null 2>&1; then
    ver="$(jq -r '.version // "?"' .ai-setup.json 2>/dev/null || echo "?")"
  elif command -v python3 >/dev/null 2>&1; then
    ver="$(python3 -c "import json; d=json.load(open('.ai-setup.json')); print(d.get('version','?'))" 2>/dev/null || echo "?")"
  else
    ver="present"
  fi
  add_row "$PASS" "Setup metadata"      "ai-setup v${ver}"
else
  add_row "$WARN" "Setup metadata"      ".ai-setup.json missing — run npx @onedot/ai-setup"
fi

# 14. CLI tools version freshness
cli_outdated=0
cli_outdated_names=""
cli_tools_checked=0
# Registry: name:package (npm only)
CLI_TOOLS_TO_CHECK="rtk:@onedot/rtk defuddle:defuddle agent-browser:agent-browser"
for entry in $CLI_TOOLS_TO_CHECK; do
  tool_name="${entry%%:*}"
  tool_pkg="${entry#*:}"
  if command -v "$tool_name" >/dev/null 2>&1; then
    cli_tools_checked=$((cli_tools_checked + 1))
    outdated_output="$(npm outdated -g "$tool_pkg" 2>/dev/null || true)"
    if [ -n "$outdated_output" ]; then
      cli_outdated=$((cli_outdated + 1))
      cli_outdated_names="${cli_outdated_names}${tool_name} "
    fi
  fi
done
if [ "$cli_tools_checked" -eq 0 ]; then
  add_row "$WARN" "CLI tools" "No CLI tools installed to check"
elif [ "$cli_outdated" -eq 0 ]; then
  add_row "$PASS" "CLI tools" "${cli_tools_checked} tool(s) up to date"
else
  add_row "$WARN" "CLI tools" "${cli_outdated} outdated: ${cli_outdated_names}— run ai-setup to update"
fi

# 15. specs/ directory
if [ -d "specs" ]; then
  count="$(find specs -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "TEMPLATE.md" 2>/dev/null | wc -l | tr -d ' ')"
  add_row "$PASS" "Specs"               "${count} open spec(s) in specs/"
else
  add_row "$WARN" "Specs"               "No specs/ directory"
fi

# 16. Corpus size
if command -v git >/dev/null 2>&1 && git rev-parse --git-dir >/dev/null 2>&1; then
  corpus_count="$(git ls-files 2>/dev/null | wc -l | tr -d ' ')"
  if [ "$corpus_count" -gt 500 ]; then
    add_row "$WARN" "Corpus size" "${corpus_count} tracked files — /analyze and /context-refresh will be expensive"
  elif [ "$corpus_count" -lt 5 ]; then
    add_row "$WARN" "Corpus size" "${corpus_count} tracked files — too small for context generation to add value"
  else
    add_row "$PASS" "Corpus size" "${corpus_count} tracked files"
  fi
fi

# 17. .claudeignore managed block freshness
# Warns when the installed managed block is older than base OR stack template.
# Looks up templates/claudeignore via npm install paths (the target project
# does not ship the templates itself).
_find_claudeignore_templates() {
  # 1. Same-repo (dev / source setup): walk up from doctor.sh
  local script_dir
  script_dir="$(cd "$(dirname "$0")" && pwd)"
  local candidate="${script_dir}/../../templates/claudeignore"
  [ -d "$candidate" ] && { echo "$candidate"; return 0; }

  # 2. Global npm install: resolve the @onedot/ai-setup package root
  if command -v npm >/dev/null 2>&1; then
    local npm_root
    npm_root=$(npm root -g 2>/dev/null || true)
    [ -n "$npm_root" ] && [ -d "${npm_root}/@onedot/ai-setup/templates/claudeignore" ] \
      && { echo "${npm_root}/@onedot/ai-setup/templates/claudeignore"; return 0; }
  fi

  # 3. npx cache fallbacks — search under typical npm cache paths
  local cache_root
  for cache_root in \
    "${NPM_CONFIG_CACHE:-$HOME/.npm}/_npx" \
    "$HOME/.npm/_npx"; do
    [ -d "$cache_root" ] || continue
    local hit
    hit=$(find "$cache_root" -maxdepth 5 -type d -name claudeignore \
          -path '*templates/claudeignore' 2>/dev/null | head -1)
    [ -n "$hit" ] && { echo "$hit"; return 0; }
  done

  return 1
}

check_claudeignore_freshness() {
  [ -f ".claudeignore" ] || return 0
  local profile
  profile=$(grep -m1 '^# --- ai-setup managed (profile:' .claudeignore 2>/dev/null | sed "s/.*profile: //;s/) ---.*//") || true
  [ -z "$profile" ] && return 0

  local tpl_dir
  tpl_dir=$(_find_claudeignore_templates) || {
    add_row "$WARN" ".claudeignore" "Cannot locate ai-setup templates — install missing or stale"
    return 0
  }
  local profile_tpl="${tpl_dir}/${profile}.claudeignore"
  local base_tpl="${tpl_dir}/base.claudeignore"
  [ -f "$profile_tpl" ] || return 0

  local _stat_cmd
  if [ "$(uname -s)" = "Darwin" ]; then _stat_cmd="stat -f %m"; else _stat_cmd="stat -c %Y"; fi

  local tpl_mtime base_mtime ci_mtime newest_tpl
  tpl_mtime=$($_stat_cmd "$profile_tpl" 2>/dev/null || echo 0)
  base_mtime=0
  [ -f "$base_tpl" ] && base_mtime=$($_stat_cmd "$base_tpl" 2>/dev/null || echo 0)
  ci_mtime=$($_stat_cmd ".claudeignore" 2>/dev/null || echo 0)

  # Compare installed file against MAX(profile, base) — base changes must also trigger stale warning
  newest_tpl=$tpl_mtime
  [ "$base_mtime" -gt "$newest_tpl" ] && newest_tpl=$base_mtime

  if [ "$newest_tpl" -gt "$ci_mtime" ]; then
    local reason="profile"
    [ "$base_mtime" -gt "$tpl_mtime" ] && reason="base"
    add_row "$WARN" ".claudeignore" "Profile ${profile} ${reason} template is newer — re-run ai-setup to sync"
  else
    add_row "$PASS" ".claudeignore" "Profile ${profile} managed block is current"
  fi
}
check_claudeignore_freshness


# 18. graph-before-read hook vs graph.json
gbr_hook_registered=false
if [ -f "$SETTINGS_FILE" ]; then
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import json,sys; d=json.load(open(sys.argv[1])); hooks=d.get('hooks',{}); pre=hooks.get('PreToolUse',[]); print('yes' if any('graph-before-read' in str(e) for e in pre) else 'no')" "$SETTINGS_FILE" 2>/dev/null | grep -q yes; then
      gbr_hook_registered=true
    fi
  elif command -v jq >/dev/null 2>&1; then
    if jq -e '[.hooks.PreToolUse[]? | select(.. | strings | test("graph-before-read"))] | length > 0' "$SETTINGS_FILE" >/dev/null 2>&1; then
      gbr_hook_registered=true
    fi
  fi
fi
if [ "$gbr_hook_registered" = "true" ]; then
  if [ ! -f ".agents/context/graph.json" ]; then
    add_row "$WARN" "graph-before-read" "Hook active but .agents/context/graph.json missing — hint will not fire"
  else
    add_row "$PASS" "graph-before-read" "Hook registered and graph.json present"
  fi
fi

# 10c. Skill stack drift detection
# Warn when an installed skill declares stacks: that don't match the project profile.
# Only active when detect-stack.sh is reachable from a known install location.
if [ -d ".claude/skills" ]; then
  _doctor_profile=""
  _detect_script=""

  # Search for detect-stack.sh relative to script locations or npm cache
  for _candidate in \
    "$(dirname "$(command -v ai-setup.sh 2>/dev/null || true)" 2>/dev/null)/../lib/detect-stack.sh" \
    "$HOME/.npm/_npx"/*/node_modules/@onedot/ai-setup/lib/detect-stack.sh; do
    [ -f "$_candidate" ] && _detect_script="$_candidate" && break
  done

  if [ -n "$_detect_script" ]; then
    _doctor_profile=$(bash "$_detect_script" "$PWD" 2>/dev/null \
      | grep "^stack_profile=" | cut -d= -f2 || true)
  fi

  if [ -n "$_doctor_profile" ] && [ "$_doctor_profile" != "default" ]; then
    drift_count=0
    drift_details=""
    while IFS= read -r skill_file; do
      [ -z "$skill_file" ] && continue
      skill_name="$(basename "$(dirname "$skill_file")")"

      stacks_line=$(awk '
        /^---$/ { if (front == 0) { front = 1; next } else { exit } }
        front == 1 && /^stacks:/ { print; exit }
      ' "$skill_file" 2>/dev/null || true)

      [ -z "$stacks_line" ] && continue

      _match=0
      if printf '%s\n' "$stacks_line" | grep -qE "(^|[^a-zA-Z0-9_-])${_doctor_profile}([^a-zA-Z0-9_-]|$)"; then
        _match=1
      fi
      if printf '%s\n' "$stacks_line" | grep -qE "(^|[^a-zA-Z0-9_-])all([^a-zA-Z0-9_-]|$)"; then
        _match=1
      fi

      if [ "$_match" -eq 0 ]; then
        drift_count=$((drift_count + 1))
        stacks_val=$(printf '%s\n' "$stacks_line" | sed 's/^stacks:[[:space:]]*//' )
        drift_details="${drift_details}${skill_name}${stacks_val} "
      fi
    done < <(find .claude/skills -name "SKILL.md" 2>/dev/null)

    if [ "$drift_count" -eq 0 ]; then
      add_row "$PASS" "Skill stack drift"   "No mismatched skills (profile: ${_doctor_profile})"
    else
      add_row "$WARN" "Skill stack drift"   "${drift_count} skill(s) for wrong stack: ${drift_details}"
    fi
  fi
fi

# 19. Graphify skill vs binary
if [ -f ".claude/skills/graphify.md" ] || [ -f ".claude/skills/graphify/SKILL.md" ]; then
  if command -v graphify >/dev/null 2>&1; then
    add_row "$PASS" "Graphify" "Skill installed and binary found"
  else
    add_row "$WARN" "Graphify" "Skill installed but graphify not in PATH — run: pipx install graphifyy"
  fi
fi

# 20. Context file size caps
_dsc_script="$(cd "$(dirname "$0")" && pwd)/../../lib/context-size-check.sh"
if [ -f "$_dsc_script" ] && [ -d ".agents/context" ]; then
  if [ "${CONTEXT_CAPS_RELAX:-0}" = "1" ]; then
    add_row "$PASS" "Context size caps" "RELAXED (CONTEXT_CAPS_RELAX=1)"
  else
    _dsc_out="$(bash "$_dsc_script" ".agents/context" 2>/dev/null || true)"
    _dsc_viols="$(printf '%s\n' "$_dsc_out" | grep '^VIOLATION:' || true)"
    if [ -n "$_dsc_viols" ]; then
      _dsc_count="$(printf '%s\n' "$_dsc_viols" | grep -c '.' || echo 0)"
      _dsc_detail="$(printf '%s\n' "$_dsc_viols" | sed 's/^VIOLATION: //' | tr '\n' '; ' | sed 's/; $//')"
      add_row "$WARN" "Context size caps" "${_dsc_count} violation(s): ${_dsc_detail}"
    else
      _dsc_total="$(printf '%s\n' "$_dsc_out" | grep '^TOTAL:' | sed 's/TOTAL: \([0-9]*\) lines.*/\1/' | head -1 || true)"
      add_row "$PASS" "Context size caps" "All files within caps (${_dsc_total:-?} total lines)"
    fi
  fi
fi
unset _dsc_script _dsc_out _dsc_viols _dsc_count _dsc_detail _dsc_total

# 21. Hook token audit
if [ -f "lib/hook-token-audit.sh" ]; then
  audit_out="$(bash lib/hook-token-audit.sh 2>/dev/null || true)"
  audit_violations="$(printf '%s\n' "$audit_out" | grep -c 'VIOLATION' 2>/dev/null || echo 0)"
  if [ "${audit_violations:-0}" -gt 0 ]; then
    add_row "$WARN" "Hook token budget" "${audit_violations} hook(s) exceed token cap — run: bash lib/hook-token-audit.sh"
  else
    total_tokens="$(printf '%s\n' "$audit_out" | grep -oE '^[[:space:]]*[A-Z].*[[:space:]]+[0-9]+[[:space:]]+(tokens|OK)' | awk '{sum+=$(NF-1)} END {print sum+0}' 2>/dev/null || echo '?')"
    add_row "$PASS" "Hook token budget" "All hooks within budget (~${total_tokens} tokens total)"
  fi
else
  add_row "$WARN" "Hook token budget" "lib/hook-token-audit.sh not found — skipping"
fi

# Output table
echo "# Doctor Report"
echo ""
printf "%-8s %-22s %s\n" "Status" "Check" "Detail"
echo "-------- ---------------------- ----------------------------------------"
while IFS='|' read -r status label detail; do
  [ -z "$status" ] && continue
  printf "%-8s %-22s %s\n" "$status" "$label" "$detail"
done <<< "$rows"

echo ""
echo "---"
echo "Results: ${ok} passed, ${warn} warnings, ${fail} failed"
[ "$fail" -gt 0 ] && exit 1 || exit 0
