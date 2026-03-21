#!/usr/bin/env bash
# validate-no-hardcoded-paths.sh
# Scans all git-tracked files for hardcoded absolute paths.
# Exits 1 if violations are found, 0 otherwise.

set -euo pipefail

# ---------------------------------------------------------------------------
# Allowlist: file patterns to skip (fnmatch-style, matched against full path)
# Add entries for documentation examples, test fixtures, or other legitimate
# occurrences that are expected to reference absolute paths.
# ---------------------------------------------------------------------------
ALLOWLIST=(
  "specs/completed/*.md"
  "specs/*.md"
  "CHANGELOG.md"
)

# Patterns to detect (extended regex)
PATTERNS='/Users/|/home/[^/]|C:\\\\Users\\\\'

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

is_allowlisted() {
  local file="$1"
  local pattern
  for pattern in "${ALLOWLIST[@]}"; do
    # Use bash glob matching
    # shellcheck disable=SC2254
    case "$file" in
      $pattern) return 0 ;;
    esac
  done
  return 1
}

is_binary() {
  # grep -I exits 1 for binary files; use it to probe
  grep -qI "" "$1" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

VIOLATIONS=()

while IFS= read -r file; do
  # Skip non-existent files (deleted but tracked)
  [[ -f "$file" ]] || continue

  # Skip binary files
  is_binary "$file" || continue

  # Skip allowlisted files
  is_allowlisted "$file" && continue

  # Scan for patterns; collect matches with line numbers
  while IFS= read -r match; do
    VIOLATIONS+=("$match")
  done < <(grep -En "$PATTERNS" "$file" 2>/dev/null | sed "s|^|${file}:|" || true)

done < <(git ls-files)

# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

if [[ ${#VIOLATIONS[@]} -eq 0 ]]; then
  echo "validate-no-hardcoded-paths: OK — no hardcoded paths found."
  exit 0
fi

echo "validate-no-hardcoded-paths: FAIL — hardcoded absolute paths detected:"
echo ""
for v in "${VIOLATIONS[@]}"; do
  echo "  $v"
done
echo ""
echo "Fix: replace hardcoded paths with relative paths, env vars, or"
echo "     add the file to the ALLOWLIST in this script if the occurrence"
echo "     is intentional (e.g., documentation example)."
exit 1
