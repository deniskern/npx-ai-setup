#!/bin/bash
# PreToolUse — redirects:
#   1. WebFetch  → defuddle (token savings)
#   2. Bash: bare `git` → rtk git (token savings)
#   3. Bash: GitHub ops → gh (gh pr, gh issue, etc.)

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# ── 1. WebFetch → defuddle ───────────────────────────────────────────────────
if [ "$TOOL_NAME" = "WebFetch" ]; then
  command -v defuddle >/dev/null 2>&1 || exit 0
  URL=$(echo "$INPUT" | jq -r '.tool_input.url // empty')
  cat >&2 <<EOF
WebFetch blocked — defuddle first (project rule: .claude/rules/general.md).
Saves ~80% tokens vs. WebFetch.

Use:      defuddle parse "$URL" --md
Fallback: WebFetch https://markdown.new/$URL

Only use WebFetch directly if the page requires JavaScript rendering or defuddle returns empty output.
EOF
  exit 2
fi

# ── 2. Bash: git without rtk prefix ─────────────────────────────────────────
if [ "$TOOL_NAME" = "Bash" ]; then
  CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

  # Check for bare `git` (not prefixed with rtk)
  # Match git at start, after &&, after ;, or after whitespace — NOT after |
  if echo "$CMD" | grep -qE '(^|&&|;|\s)git\s' && ! echo "$CMD" | grep -qE '(^|&&|;|\s)rtk\s+git\s'; then
    # Extract git subcommand (first word after git, ignoring rev-range args like HASH..HEAD)
    SUBCMD=$(echo "$CMD" | grep -oE '(^|[;&\s])git\s+[a-z-]+' | head -1 | awk '{print $NF}')

    # GitHub-specific operations → suggest gh
    case "$SUBCMD" in
      push|pull|fetch|clone|remote)
        cat >&2 <<EOF
Bash blocked — use \`gh\` for GitHub operations (project rule: .claude/rules/git.md).

Instead of: git $SUBCMD ...
Use:        gh repo clone / gh pr create / gh repo sync / etc.

For local git ops, always prefix with rtk:
  rtk git status / rtk git diff / rtk git log
EOF
        exit 2
        ;;
      *)
        cat >&2 <<EOF
Bash blocked — prefix git with rtk for token savings (project rule: CLAUDE.md).

Instead of: git $SUBCMD ...
Use:        rtk git $SUBCMD ...

For GitHub operations (push, pull, fetch, clone), use gh instead.
EOF
        exit 2
        ;;
    esac
  fi
fi

exit 0
