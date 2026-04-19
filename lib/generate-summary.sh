#!/bin/bash
# generate-summary.sh — merge bundle snippets into tiered-loading SUMMARY.md
# Usage: generate-summary.sh <bundle-dir> <target-dir>
# Example: generate-summary.sh templates/context-bundles/nuxt-storyblok .agents/context
# Output: <target-dir>/SUMMARY.md with bundle header and abstract sections

set -e

BUNDLE_DIR="${1:-}"
TARGET_DIR="${2:-.agents/context}"

# Skip silently if no bundle dir provided
if [ -z "$BUNDLE_DIR" ]; then
  exit 0
fi

if [ ! -d "$BUNDLE_DIR" ]; then
  echo "generate-summary: bundle dir not found: $BUNDLE_DIR" >&2
  exit 1
fi

# Extract profile name from bundle header comment in STACK.md
_extract_profile() {
  local stack_file="$1"
  local profile
  profile=$(grep -m1 'bundle:' "$stack_file" 2>/dev/null | sed 's/.*bundle: //;s/ v[0-9].*//')
  echo "${profile:-unknown}"
}

# Extract abstract field from frontmatter (line starting with 'abstract:')
_extract_abstract() {
  local file="$1"
  local abstract
  abstract=$(grep -m1 '^abstract:' "$file" 2>/dev/null | sed 's/^abstract: *"//;s/"$//')
  echo "${abstract:-No abstract available.}"
}

# Read first non-frontmatter content line from a file
_first_section_line() {
  local file="$1"
  # Skip comment line and frontmatter (--- blocks), return first ## heading
  grep -m1 '^## ' "$file" 2>/dev/null || echo ""
}

main() {
  local bundle_dir="$BUNDLE_DIR"
  local target_dir="$TARGET_DIR"
  local stack_file="${bundle_dir}/STACK.md"
  local arch_file="${bundle_dir}/ARCHITECTURE.md"
  local conv_file="${bundle_dir}/CONVENTIONS.md"

  if [ ! -f "$stack_file" ]; then
    echo "generate-summary: STACK.md not found in $bundle_dir" >&2
    exit 1
  fi

  local profile
  profile=$(_extract_profile "$stack_file")

  local stack_abstract arch_abstract conv_abstract
  stack_abstract=$(_extract_abstract "$stack_file")
  arch_abstract=$(_extract_abstract "$arch_file" 2>/dev/null || echo "See ARCHITECTURE.md")
  conv_abstract=$(_extract_abstract "$conv_file" 2>/dev/null || echo "See CONVENTIONS.md")

  mkdir -p "$target_dir"

  cat > "${target_dir}/SUMMARY.md" <<EOF
<!-- bundle: ${profile} v1 -->
---
abstract: "${stack_abstract}"
sections:
  - "Stack: ${stack_abstract}"
  - "Architecture: ${arch_abstract}"
  - "Conventions: ${conv_abstract}"
  - "Audit: No active HIGH issues. Review MEDIUM issues before release."
---

# Project Summary

## Stack
${stack_abstract}
  - For full details: \`@STACK.md\`

## Architecture
${arch_abstract}
  - For full details: \`@ARCHITECTURE.md\`

## Conventions
${conv_abstract}
  - For full details: \`@CONVENTIONS.md\`

## Audit
No active HIGH issues. Review MEDIUM issues before release.
EOF
}

main
