#!/usr/bin/env bash
# delegate-codex.sh — Run a prompt via Codex CLI and return the output
# Usage: bash .claude/scripts/delegate-codex.sh "your prompt here" [timeout_seconds]
# Requires: codex CLI installed, OPENAI_API_KEY set
set -euo pipefail

PROMPT="${1:-}"
TIMEOUT="${2:-120}"

if [ -z "$PROMPT" ]; then
  echo "Error: No prompt provided." >&2
  echo "Usage: bash .claude/scripts/delegate-codex.sh \"your prompt\" [timeout]" >&2
  exit 1
fi

if ! command -v codex >/dev/null 2>&1; then
  echo "Error: codex CLI is not installed." >&2
  echo "Install: npm install -g @openai/codex" >&2
  exit 1
fi

if [ -z "${OPENAI_API_KEY:-}" ]; then
  echo "Error: OPENAI_API_KEY is not set." >&2
  exit 1
fi

# Inject project context from AGENTS.md if available
CONTEXT=""
if [ -f "AGENTS.md" ]; then
  CONTEXT="Project context (from AGENTS.md):
$(cat AGENTS.md)

---
Task:
"
fi

FULL_PROMPT="${CONTEXT}${PROMPT}"

# Run codex in quiet mode with timeout
if timeout "$TIMEOUT" codex -q "$FULL_PROMPT" 2>/dev/null; then
  exit 0
else
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -eq 124 ]; then
    echo "Error: Codex CLI timed out after ${TIMEOUT}s." >&2
  else
    echo "Error: Codex CLI exited with code $EXIT_CODE." >&2
  fi
  exit "$EXIT_CODE"
fi
