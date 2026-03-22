#!/usr/bin/env bash
# delegate-gemini.sh — Run a prompt via Gemini CLI and return the output
# Usage: bash .claude/scripts/delegate-gemini.sh "your prompt here" [timeout_seconds]
# Requires: gemini CLI installed, GEMINI_API_KEY set
set -euo pipefail

PROMPT="${1:-}"
TIMEOUT="${2:-120}"

if [ -z "$PROMPT" ]; then
  echo "Error: No prompt provided." >&2
  echo "Usage: bash .claude/scripts/delegate-gemini.sh \"your prompt\" [timeout]" >&2
  exit 1
fi

if ! command -v gemini >/dev/null 2>&1; then
  echo "Error: gemini CLI is not installed." >&2
  echo "Install: npm install -g @google/gemini-cli" >&2
  exit 1
fi

if [ -z "${GEMINI_API_KEY:-}" ]; then
  echo "Error: GEMINI_API_KEY is not set." >&2
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

# Run gemini in pipe mode with timeout
if timeout "$TIMEOUT" gemini -p "$FULL_PROMPT" 2>/dev/null; then
  exit 0
else
  EXIT_CODE=$?
  if [ "$EXIT_CODE" -eq 124 ]; then
    echo "Error: Gemini CLI timed out after ${TIMEOUT}s." >&2
  else
    echo "Error: Gemini CLI exited with code $EXIT_CODE." >&2
  fi
  exit "$EXIT_CODE"
fi
