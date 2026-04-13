#!/bin/bash
# Migration: v2.0.3 → v2.1.0
# Agent optimization: rename perf-reviewer, remove liquid-linter from templates,
# add global agents support.
# Idempotent: safe to run multiple times.
# Requires: migrate.sh helpers loaded (SCRIPT_DIR, _add_file, _update_file, _remove_file)

echo "  [2.1.0] Applying migration..."

# ------------------------------------------------------------------
# Remove legacy agents (replaced by Claude Code built-in agents)
# ------------------------------------------------------------------
_remove_file ".claude/agents/perf-reviewer.md"
_remove_file ".claude/agents/performance-reviewer.md"
_remove_file ".claude/agents/verify-app.md"
_remove_file ".claude/agents/frontend-developer.md"
_remove_file ".claude/agents/backend-developer.md"
_remove_file ".claude/agents/liquid-linter.md"

# ------------------------------------------------------------------
# Update remaining agents with new model routing / name references
# ------------------------------------------------------------------
_update_file "templates/agents/code-reviewer.md"        ".claude/agents/code-reviewer.md"
_update_file "templates/agents/security-reviewer.md"    ".claude/agents/security-reviewer.md"

# ------------------------------------------------------------------
# Update dispatch documentation
# ------------------------------------------------------------------
_update_file "templates/claude/docs/agent-dispatch.md" ".claude/docs/agent-dispatch.md"

echo "  [2.1.0] Done."
