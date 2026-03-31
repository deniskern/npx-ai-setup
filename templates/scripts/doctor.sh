#!/usr/bin/env bash
# doctor.sh — Health check for Claude Code AI setup (12 checks)
# Usage: bash .claude/scripts/doctor.sh
# Requires: bash 3.2+, git
set -euo pipefail

PASS="[OK]"
FAIL="[FAIL]"
WARN="[WARN]"

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
if [ -f ".claude/settings.json" ]; then
  if command -v python3 >/dev/null 2>&1; then
    if python3 -c "import json,sys; json.load(open('.claude/settings.json'))" 2>/dev/null; then
      add_row "$PASS" "settings.json"    "Valid JSON"
    else
      add_row "$FAIL" "settings.json"    "Invalid JSON — run: python3 -m json.tool .claude/settings.json"
    fi
  elif command -v jq >/dev/null 2>&1; then
    if jq empty .claude/settings.json 2>/dev/null; then
      add_row "$PASS" "settings.json"    "Valid JSON"
    else
      add_row "$FAIL" "settings.json"    "Invalid JSON"
    fi
  else
    add_row "$WARN" "settings.json"    "Cannot validate — python3 and jq both missing"
  fi
else
  add_row "$FAIL" "settings.json"      ".claude/settings.json not found"
fi

# 4. CLAUDE.md present
if [ -f "CLAUDE.md" ]; then
  lines="$(wc -l < CLAUDE.md | tr -d ' ')"
  add_row "$PASS" "CLAUDE.md"           "Present (${lines} lines)"
else
  add_row "$FAIL" "CLAUDE.md"           "CLAUDE.md not found"
fi

# 5. CLAUDE.md size guard (>200 lines is a smell)
if [ -f "CLAUDE.md" ]; then
  lines="$(wc -l < CLAUDE.md | tr -d ' ')"
  if [ "$lines" -gt 200 ]; then
    add_row "$WARN" "CLAUDE.md size"    "${lines} lines — consider trimming (token cost)"
  else
    add_row "$PASS" "CLAUDE.md size"    "${lines} lines (OK)"
  fi
fi

# 6. Context files
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

# 7. .mcp.json present
if [ -f ".mcp.json" ]; then
  add_row "$PASS" "MCP config"          ".mcp.json found"
else
  add_row "$WARN" "MCP config"          ".mcp.json not found (optional)"
fi

# 8. Skills directory
if [ -d ".claude/skills" ]; then
  skills_list="$(find .claude/skills -name "*.md" 2>/dev/null)"
  count="$(printf '%s\n' "$skills_list" | grep -c '.' 2>/dev/null || echo 0)"
  if [ "$count" -gt 0 ]; then
    add_row "$PASS" "Skills"              "${count} skill(s) installed"
  else
    add_row "$WARN" "Skills"              "No skills found in .claude/skills/"
  fi
else
  add_row "$WARN" "Skills"              "No skills found in .claude/skills/"
fi

# 9. Claude scripts directory
if [ -d ".claude/scripts" ]; then
  count="$(find .claude/scripts -name "*.sh" 2>/dev/null | wc -l | tr -d ' ')"
  add_row "$PASS" "Claude scripts"      "${count} script(s) in .claude/scripts/"
else
  add_row "$WARN" "Claude scripts"      ".claude/scripts/ not present"
fi

# 10. git config user.email set
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

# 11. .ai-setup.json metadata present
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

# 12. specs/ directory
if [ -d "specs" ]; then
  count="$(find specs -maxdepth 1 -name "*.md" ! -name "README.md" ! -name "TEMPLATE.md" 2>/dev/null | wc -l | tr -d ' ')"
  add_row "$PASS" "Specs"               "${count} open spec(s) in specs/"
else
  add_row "$WARN" "Specs"               "No specs/ directory"
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
