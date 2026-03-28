#!/bin/bash
# context-loader.sh — SessionStart hook
# Loads L0 abstracts from .agents/context/ files instead of full content.
# Parses YAML frontmatter (abstract + sections) for token-efficient context injection.
# Falls back to head -20 if no frontmatter found.
# Target: <400 tokens total (vs ~2000 for full files).

CONTEXT_DIR="${CLAUDE_PROJECT_DIR:-.}/.agents/context"

output=""

for filepath in $(find "$CONTEXT_DIR" -maxdepth 1 -name "*.md" 2>/dev/null | sort); do
  f=$(basename "$filepath")
  [ -f "$filepath" ] || continue

  # Check for YAML frontmatter
  first_line=$(head -1 "$filepath")
  if [ "$first_line" = "---" ]; then
    # Extract abstract and sections from frontmatter
    abstract=""
    sections=""
    in_frontmatter=1
    in_sections=0
    line_num=0

    while IFS= read -r line; do
      line_num=$((line_num + 1))
      [ "$line_num" -eq 1 ] && continue  # skip opening ---

      # End of frontmatter
      if [ "$line" = "---" ]; then
        break
      fi

      # Parse abstract
      case "$line" in
        abstract:*)
          abstract="${line#abstract: }"
          abstract="${abstract#\"}"
          abstract="${abstract%\"}"
          ;;
        sections:)
          in_sections=1
          ;;
        "  - "*)
          if [ "$in_sections" -eq 1 ]; then
            entry="${line#  - }"
            entry="${entry#\"}"
            entry="${entry%\"}"
            sections="${sections:+$sections\n}  - $entry"
          fi
          ;;
        *)
          in_sections=0
          ;;
      esac
    done < "$filepath"

    if [ -n "$abstract" ]; then
      output="${output:+$output\n\n}=== $f ==\n$abstract"
      if [ -n "$sections" ]; then
        output="$output\n$sections"
      fi
    fi
    # No abstract = skip silently (AUDIT.md, PATTERNS.md etc. are L2 — not L0)
  fi
  # No frontmatter = skip silently
done

if [ -n "$output" ] && command -v jq >/dev/null 2>&1; then
  printf '%b' "$output" | jq -Rs '{"additionalContext": .}'
fi
