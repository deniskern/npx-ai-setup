#!/usr/bin/env bash
# hook-token-audit.sh — Audit hook output token estimates
# Usage: bash lib/hook-token-audit.sh [hooks-dir]
# Scans templates/claude/hooks/ and .claude/hooks/ (or specified dir),
# estimates max output tokens per hook via chars/4 of printable output lines.
# Tokens = chars of echo/printf/heredoc content / 4 (POSIX approximation).
#
# Caps:
#   UserPromptSubmit / PreToolUse  : 300 tokens  (per-turn, cumulative)
#   SessionStart / PreCompact      : 2000 tokens  (one-shot)
#   PostToolUse / TaskCompleted / Stop : 300 tokens (per-turn)
#
# Exit 0 if all OK, exit 1 if any VIOLATION.

set -euo pipefail

CAP_PER_TURN=300
CAP_ONE_SHOT=2000

# ── Hook-type lookup from settings.json ──────────────────────────────────────
_lookup_hook_type() {
  local hook_file="$1"
  local hook_base
  hook_base="$(basename "$hook_file")"

  local settings=""
  for candidate in ".claude/settings.json" "templates/claude/settings.json"; do
    [ -f "$candidate" ] && settings="$candidate" && break
  done

  [ -z "$settings" ] && echo "Unknown" && return

  if command -v jq >/dev/null 2>&1; then
    local result
    result=$(jq -r --arg hook "$hook_base" '
      .hooks // {} | to_entries[] |
      .key as $type |
      .value[] | (.hooks // [])[] |
      select(.command != null and (.command | test($hook))) |
      $type
    ' "$settings" 2>/dev/null | head -1)
    echo "${result:-Unknown}"
  elif command -v python3 >/dev/null 2>&1; then
    python3 - "$settings" "$hook_base" <<'PYEOF'
import json, sys
settings_path, hook_name = sys.argv[1], sys.argv[2]
try:
    data = json.load(open(settings_path))
    for hook_type, entries in data.get("hooks", {}).items():
        for entry in entries:
            for h in entry.get("hooks", []):
                if hook_name in h.get("command", ""):
                    print(hook_type)
                    sys.exit(0)
    print("Unknown")
except Exception:
    print("Unknown")
PYEOF
  else
    echo "Unknown"
  fi
}

# ── Token estimation ──────────────────────────────────────────────────────────
# Scans hook file for lines that produce stdout output (echo, printf going to
# stdout, jq output, multiline var assignments piped to stdout).
# Converts to token estimate via chars/4.
_estimate_output_tokens() {
  local hook_file="$1"
  local output_chars=0
  local in_heredoc=0
  local heredoc_marker=""
  local in_multiline_var=0

  while IFS= read -r line; do
    # Track heredoc blocks (stdout only)
    if [ "$in_heredoc" -eq 1 ]; then
      if [ "$line" = "$heredoc_marker" ]; then
        in_heredoc=0
        heredoc_marker=""
      else
        output_chars=$((output_chars + ${#line} + 1))
      fi
      continue
    fi

    # Track multiline single-quoted variable assignments (e.g. var='...')
    # These are often piped to stdout later via printf/echo
    if [ "$in_multiline_var" -eq 1 ]; then
      # Ends when line contains closing single-quote followed by optional chars
      case "$line" in
        *"'"*) in_multiline_var=0 ;;
      esac
      output_chars=$((output_chars + ${#line} + 1))
      continue
    fi

    # Skip comments and blank lines
    case "$line" in
      \#*|"") continue ;;
    esac

    # Detect heredoc start going to stdout (not >&2)
    case "$line" in
      *">&2"*) : ;;
      *)
        if echo "$line" | grep -qE '<<[[:space:]]*'"'"'?[A-Z_]+'"'"'?'; then
          marker=$(echo "$line" | grep -oE "<<[[:space:]]*'?[A-Z_]+'" | sed "s/<<[[:space:]]*//;s/'//g")
          if [ -n "$marker" ]; then
            in_heredoc=1
            heredoc_marker="$marker"
          fi
        fi
        ;;
    esac

    # Detect multiline variable assignment: varname='...\n  (no closing quote)
    case "$line" in
      *">"*) : ;;  # skip redirects
      *"="*"'"*)
        # var='content without closing quote on this line
        # Strip leading varname=' prefix to get content
        after_eq="${line#*=}"          # everything after first =
        stripped="${after_eq#\'}"      # strip leading single quote
        case "$stripped" in
          *"'"*) : ;;  # closed on same line
          *)
            in_multiline_var=1
            output_chars=$((output_chars + ${#stripped} + 1))
            ;;
        esac
        ;;
    esac

    # Count echo/printf lines going to stdout (not >&2)
    case "$line" in
      *">&2"*) continue ;;
    esac

    case "$line" in
      *"echo "*)
        content="${line#*echo }"
        output_chars=$((output_chars + ${#content} + 1))
        ;;
      *"printf "*)
        content="${line#*printf }"
        output_chars=$((output_chars + ${#content} + 1))
        ;;
    esac

    # Count jq -n / jq -Rs output (JSON objects going to stdout)
    case "$line" in
      *"jq -n"*|*"jq -Rs"*)
        output_chars=$((output_chars + 80))
        ;;
    esac
  done < "$hook_file"

  # Token floor: 10 (minimum overhead per hook invocation)
  [ "$output_chars" -lt 40 ] && output_chars=40

  echo $(( (output_chars + 3) / 4 ))
}

# ── Cap lookup ────────────────────────────────────────────────────────────────
_get_cap() {
  case "$1" in
    SessionStart|PreCompact) echo "$CAP_ONE_SHOT" ;;
    *) echo "$CAP_PER_TURN" ;;
  esac
}

# ── Collect hook dirs ─────────────────────────────────────────────────────────
HOOK_DIRS=()
if [ $# -gt 0 ]; then
  HOOK_DIRS+=("$1")
else
  [ -d "templates/claude/hooks" ] && HOOK_DIRS+=("templates/claude/hooks")
  [ -d ".claude/hooks" ]          && HOOK_DIRS+=(".claude/hooks")
fi

if [ "${#HOOK_DIRS[@]}" -eq 0 ]; then
  echo "No hook directories found (templates/claude/hooks or .claude/hooks)" >&2
  exit 0
fi

# ── Run audit ─────────────────────────────────────────────────────────────────
violations=0
header_printed=0

_print_header() {
  if [ "$header_printed" -eq 0 ]; then
    printf "%-20s  %-28s  %-7s  %s\n" "HOOK_TYPE" "HOOK_NAME" "TOKENS" "VERDICT"
    printf "%-20s  %-28s  %-7s  %s\n" "--------------------" "----------------------------" "-------" "-------"
    header_printed=1
  fi
}

for hook_dir in "${HOOK_DIRS[@]}"; do
  for hook_file in "$hook_dir"/*.sh; do
    [ -f "$hook_file" ] || continue

    hook_name="$(basename "$hook_file")"
    hook_type="$(_lookup_hook_type "$hook_file")"
    tokens="$(_estimate_output_tokens "$hook_file")"
    cap="$(_get_cap "$hook_type")"

    if [ "$tokens" -gt "$cap" ]; then
      verdict="VIOLATION (cap: ${cap})"
      violations=$((violations + 1))
    else
      verdict="OK"
    fi

    _print_header
    printf "%-20s  %-28s  %-7s  %s\n" "$hook_type" "$hook_name" "$tokens" "$verdict"
  done
done

echo ""
if [ "$violations" -gt 0 ]; then
  echo "RESULT: ${violations} VIOLATION(s) found — trim hook output to meet caps"
  echo "  UserPromptSubmit/PreToolUse/other cap : ${CAP_PER_TURN} tokens"
  echo "  SessionStart/PreCompact cap           : ${CAP_ONE_SHOT} tokens"
  exit 1
else
  echo "RESULT: All hooks within token budget"
  exit 0
fi
