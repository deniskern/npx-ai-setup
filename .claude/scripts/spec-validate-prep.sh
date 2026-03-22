#!/usr/bin/env bash
# spec-validate-prep.sh — Pre-parse spec structure for /spec-validate
# Usage: bash .claude/scripts/spec-validate-prep.sh <spec-file-or-number>
# Requires: bash 3.2+
set -euo pipefail

# ---------------------------------------------------------------------------
# Resolve spec file
# ---------------------------------------------------------------------------
SPEC_ARG="${1:-}"

if [ -z "$SPEC_ARG" ]; then
  printf "Usage: spec-validate-prep.sh <spec-file-or-number>\n" >&2
  exit 1
fi

SPEC_FILE=""

# If argument looks like a number, find the matching spec
if printf '%s' "$SPEC_ARG" | grep -qE '^[0-9]+$'; then
  # Zero-pad to 3 digits and glob
  PADDED="$(printf '%03d' "$SPEC_ARG")"
  for _f in specs/${PADDED}-*.md; do
    [ -f "$_f" ] && SPEC_FILE="$_f" && break
  done
  if [ -z "$SPEC_FILE" ]; then
    printf "No spec found matching specs/%s-*.md\n" "$PADDED" >&2
    exit 1
  fi
elif [ -f "$SPEC_ARG" ]; then
  SPEC_FILE="$SPEC_ARG"
else
  printf "File not found: %s\n" "$SPEC_ARG" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
section() { printf "\n## %s\n\n" "$1"; }
hr()      { printf '%s\n' "---"; }

count_section_lines() {
  local file="$1" heading="$2"
  # Count lines from the heading until the next ## heading or EOF
  awk "/^## ${heading}/{found=1; next} found && /^## /{exit} found{count++} END{print count+0}" "$file"
}

section_present() {
  local file="$1" heading="$2"
  grep -qE "^## ${heading}" "$file" 2>/dev/null && printf "present" || printf "missing"
}

# ---------------------------------------------------------------------------
# Header
# ---------------------------------------------------------------------------
SPEC_ID="$(basename "$SPEC_FILE" .md | grep -oE '^[0-9]+'  || echo "???")"
SPEC_TITLE="$(grep -m1 '^# ' "$SPEC_FILE" 2>/dev/null | sed 's/^# //' || echo "Unknown")"
TOTAL_LINES="$(wc -l < "$SPEC_FILE" | tr -d ' ')"
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S')"

printf "# Spec Validate Prep — %s\n" "$SPEC_FILE"
printf "ID: %s  |  Generated: %s\n" "$SPEC_ID" "$TIMESTAMP"
hr

# ---------------------------------------------------------------------------
# Status detection
# ---------------------------------------------------------------------------
section "Status"
STATUS_LINE="$(grep -m1 'Status:' "$SPEC_FILE" 2>/dev/null || echo "")"
if [ -n "$STATUS_LINE" ]; then
  printf "%s\n" "$STATUS_LINE"
  if printf '%s' "$STATUS_LINE" | grep -qi 'in-progress\|in-review\|completed'; then
    printf "\n> WARNING: Spec is not in draft status — validation may be advisory only.\n"
  fi
else
  printf "No Status field found.\n"
fi

# ---------------------------------------------------------------------------
# Required section checklist
# ---------------------------------------------------------------------------
section "Required Sections"

REQUIRED_SECTIONS=("Goal" "Context" "Steps" "Acceptance Criteria" "Files to Modify" "Out of Scope")

printf "%-30s %s\n" "Section" "Status"
printf "%-30s %s\n" "-------" "------"

for display in "${REQUIRED_SECTIONS[@]}"; do
  status="$(grep -qE "^## ${display}" "$SPEC_FILE" 2>/dev/null && echo "[PRESENT]" || echo "[MISSING]")"
  printf "%-30s %s\n" "$display" "$status"
done

# ---------------------------------------------------------------------------
# Line counts per section
# ---------------------------------------------------------------------------
section "Line Counts per Section"

printf "%-30s %s\n" "Section" "Lines"
printf "%-30s %s\n" "-------" "-----"

for display in "${REQUIRED_SECTIONS[@]}"; do
  lines="$(count_section_lines "$SPEC_FILE" "$display")"
  printf "%-30s %s\n" "$display" "$lines"
done

printf "\nTotal spec lines: %s\n" "$TOTAL_LINES"

# ---------------------------------------------------------------------------
# Step count
# ---------------------------------------------------------------------------
section "Step Analysis"

STEP_COUNT="$(grep -cE '^\s*-\s+\[[ x]\]\s+Step\s+[0-9]' "$SPEC_FILE" 2>/dev/null || echo 0)"
STEP_DONE="$(grep -cE '^\s*-\s+\[x\]\s+Step\s+[0-9]' "$SPEC_FILE" 2>/dev/null || echo 0)"
STEP_TODO="$((STEP_COUNT - STEP_DONE))"

printf "Total steps:     %s\n" "$STEP_COUNT"
printf "Completed steps: %s\n" "$STEP_DONE"
printf "Remaining steps: %s\n" "$STEP_TODO"

if [ "$STEP_COUNT" -eq 0 ]; then
  printf "\n> WARNING: No steps found. Steps section may be empty or not following checkbox format.\n"
elif [ "$STEP_COUNT" -gt 10 ]; then
  printf "\n> WARNING: %s steps — consider splitting this spec (>10 steps is a complexity smell).\n" "$STEP_COUNT"
fi

# ---------------------------------------------------------------------------
# Acceptance criteria count
# ---------------------------------------------------------------------------
section "Acceptance Criteria Analysis"

# Match checkbox lines inside the Acceptance Criteria section
AC_COUNT="$(awk '/^## Acceptance Criteria/{found=1; next} found && /^## /{exit} found && /^\s*-\s+\[/{count++} END{print count+0}' "$SPEC_FILE")"
AC_DONE="$(awk '/^## Acceptance Criteria/{found=1; next} found && /^## /{exit} found && /^\s*-\s+\[x\]/{count++} END{print count+0}' "$SPEC_FILE")"

printf "Total criteria:     %s\n" "$AC_COUNT"
printf "Completed criteria: %s\n" "$AC_DONE"

if [ "$AC_COUNT" -eq 0 ]; then
  printf "\n> WARNING: No acceptance criteria found — spec cannot be verified as done.\n"
fi

# ---------------------------------------------------------------------------
# Files to Modify count
# ---------------------------------------------------------------------------
section "Files to Modify"

FILES_COUNT="$(awk '/^## Files to Modify/{found=1; next} found && /^## /{exit} found && /^\s*[-*]/{count++} END{print count+0}' "$SPEC_FILE")"
printf "Listed file entries: %s\n" "$FILES_COUNT"

if [ "$FILES_COUNT" -eq 0 ]; then
  printf "\n> WARNING: No files listed — spec missing file scope.\n"
fi

# Extract and print the listed files
awk '/^## Files to Modify/{found=1; next} found && /^## /{exit} found && /^\s*[-*]/{print}' "$SPEC_FILE" | while IFS= read -r line; do
  printf "%s\n" "$line"
done

# ---------------------------------------------------------------------------
# Structural score (simple heuristic, 0–100)
# ---------------------------------------------------------------------------
section "Structural Score"

SCORE=0
MAX=100

# Each required section present: +12 points (6 sections * 12 = 72)
for display in "${REQUIRED_SECTIONS[@]}"; do
  if grep -qE "^## ${display}" "$SPEC_FILE" 2>/dev/null; then
    SCORE=$((SCORE + 12))
  fi
done

# Steps exist: +10
[ "$STEP_COUNT" -gt 0 ] && SCORE=$((SCORE + 10))

# Acceptance criteria exist: +10
[ "$AC_COUNT" -gt 0 ] && SCORE=$((SCORE + 10))

# Files listed: +8
[ "$FILES_COUNT" -gt 0 ] && SCORE=$((SCORE + 8))

# Cap at 100
[ "$SCORE" -gt 100 ] && SCORE=100

printf "Structural score: %s / %s\n\n" "$SCORE" "$MAX"

if [ "$SCORE" -ge 80 ]; then
  printf "Result: PASS — structure looks complete.\n"
elif [ "$SCORE" -ge 60 ]; then
  printf "Result: WARN — structure is mostly there but some sections are missing.\n"
else
  printf "Result: FAIL — spec is missing critical structural elements.\n"
fi

# ---------------------------------------------------------------------------
# Summary for Claude
# ---------------------------------------------------------------------------
section "Summary for Claude"

printf "Spec file: \`%s\`\n" "$SPEC_FILE"
printf "Title: %s\n" "$SPEC_TITLE"
printf "Steps: %s total, %s done, %s remaining\n" "$STEP_COUNT" "$STEP_DONE" "$STEP_TODO"
printf "Criteria: %s total, %s done\n" "$AC_COUNT" "$AC_DONE"
printf "Files listed: %s\n" "$FILES_COUNT"
printf "Structural score: %s/100\n" "$SCORE"
printf "\nUse the section analysis above to score content quality.\n"
printf "Do NOT re-read the spec file — all structural data is captured above.\n"
