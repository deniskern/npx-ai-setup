#!/usr/bin/env bash
# docs-audit.sh — Verify README.md and WORKFLOW-GUIDE.md match filesystem counts
# Usage: bash .claude/scripts/docs-audit.sh [--fix]
# Exit 0 = all docs match, Exit 1 = discrepancies found
# With --fix: outputs structured report for Claude to apply fixes
set -euo pipefail

# ── Load prep-lib if available ────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
[ -f "$SCRIPT_DIR/prep-lib.sh" ] && source "$SCRIPT_DIR/prep-lib.sh"

FIX_MODE=0
[ "${1:-}" = "--fix" ] && FIX_MODE=1

ISSUES=0

# ── Helper: count and compare ─────────────────────────────────────────────────
check_count() {
  local label="$1" actual="$2" file="$3" pattern="$4"
  local stated
  stated=$(grep -oE "$pattern" "$file" 2>/dev/null | head -1 | grep -oE '[0-9]+' || true)
  if [ -z "$stated" ]; then
    echo "  SKIP: $label — no count found in $file"
    return
  fi
  if [ "$stated" -eq "$actual" ]; then
    echo "  OK:   $label = $actual ($file)"
  else
    echo "  DIFF: $label — filesystem=$actual, $file states $stated"
    ISSUES=$((ISSUES + 1))
  fi
}

# ── Helper: check table completeness ──────────────────────────────────────────
check_table() {
  local label="$1" file="$2"
  shift 2
  local items=("$@")
  local missing=()
  for item in "${items[@]}"; do
    if ! grep -q "$item" "$file" 2>/dev/null; then
      missing+=("$item")
    fi
  done
  if [ "${#missing[@]}" -eq 0 ]; then
    echo "  OK:   $label table complete in $file (${#items[@]} entries)"
  else
    echo "  DIFF: $label table in $file missing ${#missing[@]} entries: ${missing[*]}"
    ISSUES=$((ISSUES + 1))
  fi
}

echo "# Docs Audit"
echo ""

# ── Count filesystem artifacts ────────────────────────────────────────────────
SKILL_DIRS=()
while IFS= read -r d; do
  SKILL_DIRS+=("$(basename "$d")")
done < <(find templates/skills -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort)
SKILL_COUNT=${#SKILL_DIRS[@]}

HOOK_FILES=()
while IFS= read -r f; do
  HOOK_FILES+=("$(basename "$f" .sh)")
done < <(find templates/claude/hooks -maxdepth 1 -name '*.sh' -type f 2>/dev/null | sort)
HOOK_COUNT=${#HOOK_FILES[@]}

AGENT_FILES=()
while IFS= read -r f; do
  name="$(basename "$f" .md)"
  [ "$name" = "README" ] && continue
  AGENT_FILES+=("$name")
done < <(find templates/agents -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort)
AGENT_COUNT=${#AGENT_FILES[@]}

RULE_FILES=()
while IFS= read -r f; do
  RULE_FILES+=("$(basename "$f" .md)")
done < <(find templates/claude/rules -maxdepth 1 -name '*.md' -type f 2>/dev/null | sort)
RULE_COUNT=${#RULE_FILES[@]}

echo "## Filesystem counts"
echo "  Skills:  $SKILL_COUNT (dirs in templates/skills/)"
echo "  Hooks:   $HOOK_COUNT (.sh in templates/claude/hooks/)"
echo "  Agents:  $AGENT_COUNT (.md in templates/agents/, excl. README)"
echo "  Rules:   $RULE_COUNT (.md in templates/claude/rules/)"
echo ""

# ── Check README.md ───────────────────────────────────────────────────────────
echo "## README.md"
if [ -f "README.md" ]; then
  # Prose counts
  check_count "Skills (prose)" "$SKILL_COUNT" "README.md" "[0-9]+ bundled skill templates"
  check_count "Skills (heading)" "$SKILL_COUNT" "README.md" "Skills \([0-9]+ slash commands\)"
  check_count "Hooks" "$HOOK_COUNT" "README.md" "[0-9]+ hooks"
  check_count "Agents" "$AGENT_COUNT" "README.md" "[0-9]+ subagent templates"

  # Table completeness: skills
  check_table "Skills" "README.md" "${SKILL_DIRS[@]}"

  # Table completeness: agents
  check_table "Agents" "README.md" "${AGENT_FILES[@]}"

  # Hook list completeness (hooks are listed inline, not as table rows)
  HOOKS_MISSING=()
  for hook in "${HOOK_FILES[@]}"; do
    if ! grep -q "$hook" "README.md" 2>/dev/null; then
      HOOKS_MISSING+=("$hook")
    fi
  done
  if [ "${#HOOKS_MISSING[@]}" -eq 0 ]; then
    echo "  OK:   Hook list complete in README.md (${HOOK_COUNT} hooks)"
  else
    echo "  DIFF: Hook list in README.md missing: ${HOOKS_MISSING[*]}"
    ISSUES=$((ISSUES + 1))
  fi
else
  echo "  SKIP: README.md not found"
fi
echo ""

# ── Check WORKFLOW-GUIDE.md ───────────────────────────────────────────────────
echo "## WORKFLOW-GUIDE.md"
if [ -f "WORKFLOW-GUIDE.md" ]; then
  check_count "Hooks" "$HOOK_COUNT" "WORKFLOW-GUIDE.md" "[0-9]+ Hooks"
else
  echo "  SKIP: WORKFLOW-GUIDE.md not found"
fi

# Also check templates/WORKFLOW-GUIDE.md
if [ -f "templates/WORKFLOW-GUIDE.md" ]; then
  check_count "Hooks (template)" "$HOOK_COUNT" "templates/WORKFLOW-GUIDE.md" "[0-9]+ Hooks"
fi
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "---"
if [ "$ISSUES" -eq 0 ]; then
  echo "All docs match filesystem. 0 discrepancies."
  exit 0
else
  echo "$ISSUES discrepancy(ies) found."
  if [ "$FIX_MODE" -eq 1 ]; then
    echo ""
    echo "## Fix instructions"
    echo "Update the stated counts and tables in README.md and WORKFLOW-GUIDE.md"
    echo "to match the filesystem counts above. Add missing entries, fix numbers."
  fi
  exit 1
fi
