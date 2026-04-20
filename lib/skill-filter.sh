#!/bin/bash
# skill-filter.sh — Filter skills by stack profile via YAML frontmatter
# Usage (library): source this file, then call skill_matches_profile
# Usage (standalone): bash lib/skill-filter.sh <skill_file> <profile>
# Returns: 0 if skill should be installed, 1 if it should be skipped

# skill_matches_profile <skill_file> <profile>
# Returns 0 if the skill's stacks: frontmatter contains <profile> or "all",
# or if the stacks: field is missing entirely (safe default).
# Returns 1 if stacks: is present and <profile> is not listed.
skill_matches_profile() {
  local skill_file="$1"
  local profile="$2"

  # If file doesn't exist, treat as match (caller handles missing files)
  [ -f "$skill_file" ] || return 0

  # Extract stacks: value from YAML frontmatter (between first --- pair)
  # awk reads only inside the front-matter block and prints the stacks line value
  local stacks_line
  stacks_line=$(awk '
    /^---$/ { if (front == 0) { front = 1; next } else { exit } }
    front == 1 && /^stacks:/ { print; exit }
  ' "$skill_file")

  # No stacks: field — safe default, matches everything
  [ -z "$stacks_line" ] && return 0

  # Check if profile or "all" appears in the stacks value.
  # Use non-identifier characters as delimiters (handles [val, val] YAML inline arrays).
  if printf '%s\n' "$stacks_line" | grep -qE "(^|[^a-zA-Z0-9_-])${profile}([^a-zA-Z0-9_-]|$)"; then
    return 0
  fi
  if printf '%s\n' "$stacks_line" | grep -qE "(^|[^a-zA-Z0-9_-])all([^a-zA-Z0-9_-]|$)"; then
    return 0
  fi

  return 1
}

# log_skill_skip <skill_name> <skill_file> <profile>
# Prints skip reason to stderr in the canonical format.
log_skill_skip() {
  local skill_name="$1"
  local skill_file="$2"
  local profile="$3"

  local stacks_line
  stacks_line=$(awk '
    /^---$/ { if (front == 0) { front = 1; next } else { exit } }
    front == 1 && /^stacks:/ { print; exit }
  ' "$skill_file" 2>/dev/null || true)

  # Extract the bracket value from "stacks: [...]"
  local stacks_val
  stacks_val=$(printf '%s\n' "$stacks_line" | sed 's/^stacks:[[:space:]]*//')

  printf 'Skipping %s: stacks=%s, profile=%s\n' \
    "$skill_name" "$stacks_val" "$profile" >&2
}

# Standalone test mode
if [ "${BASH_SOURCE[0]}" = "$0" ]; then
  if [ $# -lt 2 ]; then
    echo "Usage: $0 <skill_file> <profile>" >&2
    exit 2
  fi
  skill_matches_profile "$1" "$2"
  exit $?
fi
