#!/usr/bin/env bash
# skill-lint.sh — validates YAML frontmatter and required sections in skill template files
# Exit 0: all checks pass. Exit 1: at least one error found.
#
# Usage:
#   bash scripts/skill-lint.sh
#   SKILL_DIRS="templates/skills" bash scripts/skill-lint.sh

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

PASS="[PASS]"
FAIL="[FAIL]"
WARN="[WARN]"

_pass() { printf '%s %s\n' "$PASS" "$1"; }
_fail() { printf '%s %s\n' "$FAIL" "$1" >&2; ERRORS=$(( ERRORS + 1 )); }
_warn() { printf '%s %s\n' "$WARN" "$1"; WARNINGS=$(( WARNINGS + 1 )); }

DEFAULT_DIRS="templates/skills"
SKILL_DIRS="${SKILL_DIRS:-$DEFAULT_DIRS}"

lint_skill() {
    local file="$1"
    local ok=1

    # ── 1. Frontmatter present ────────────────────────────────────────────────
    local first_line
    first_line="$(head -1 "$file")"
    if [ "$first_line" != "---" ]; then
        _fail "$file: no YAML frontmatter (file must start with ---)"
        return
    fi

    # ── 2. Required field: name (kebab-case) ──────────────────────────────────
    local name_value
    name_value="$(grep -m1 "^name:" "$file" | sed 's/^name:[[:space:]]*//' | tr -d '"'"'")"
    if [ -z "$name_value" ]; then
        _fail "$file: missing required field 'name:'"
        ok=0
    elif ! echo "$name_value" | grep -qE '^[a-z][a-z0-9-]*$'; then
        _fail "$file: 'name: $name_value' is not kebab-case (lowercase letters, digits, hyphens only)"
        ok=0
    fi

    # ── 3. Required field: description (<=220 chars) ─────────────────────────
    local desc_value
    desc_value="$(grep -m1 "^description:" "$file" | sed 's/^description:[[:space:]]*//' | tr -d '"')"
    if [ -z "$desc_value" ]; then
        _fail "$file: missing required field 'description:'"
        ok=0
    elif [ "${#desc_value}" -gt 220 ]; then
        _fail "$file: 'description' is ${#desc_value} chars (max 220)"
        ok=0
    fi

    # ── 4. Required section OR inline shell dispatch ──────────────────────────
    # Skills that use !command dispatch may skip a ## Process/Rules section
    local has_section has_dispatch
    has_section=$(grep -cE "^## (Process|Rules|Behavior|Usage|Phase)" "$file" || true)
    has_dispatch=$(grep -cE "^!" "$file" || true)
    if [ "$has_section" -eq 0 ] && [ "$has_dispatch" -eq 0 ]; then
        _fail "$file: missing primary content section (## Process, ## Rules, ## Behavior, ## Usage, or ## Phase) or inline shell dispatch (!command)"
        ok=0
    fi

    # ── 5. Required section: ## Next Step ─────────────────────────────────────
    if ! grep -qE "^## Next Step" "$file"; then
        _warn "$file: missing recommended section '## Next Step'"
    fi

    if [ "$ok" -eq 1 ]; then
        _pass "$file"
    fi
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo "=== Skill Lint ==="
echo ""

FILE_COUNT=0
for dir in $SKILL_DIRS; do
    abs_dir="${REPO_ROOT}/${dir}"
    if [ ! -d "$abs_dir" ]; then
        _warn "Directory not found, skipping: $abs_dir"
        continue
    fi
    while IFS= read -r -d '' skill_dir; do
        local_file="${skill_dir}/SKILL.template.md"
        [ -f "$local_file" ] || continue
        FILE_COUNT=$(( FILE_COUNT + 1 ))
        lint_skill "$local_file"
    done < <(find "$abs_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
done

echo ""
echo "=== Summary ==="
echo "Skills checked : $FILE_COUNT"
echo "Errors         : $ERRORS"
echo "Warnings       : $WARNINGS"
echo ""

if [ "$ERRORS" -gt 0 ]; then
    echo "[FAIL] $ERRORS error(s) found — fix before proceeding."
    exit 1
else
    echo "[PASS] All skills pass required checks."
    exit 0
fi
