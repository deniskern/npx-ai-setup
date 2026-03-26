#!/bin/bash
# Migration: v1.3.5 → v1.4.0
# Captures all template additions, updates, and removals since v1.3.5 (released as v1.2.7+).
# Idempotent: safe to run multiple times.
# Requires: migrate.sh helpers loaded (SCRIPT_DIR, _add_file, _update_file, _remove_file)

echo "  [1.4.0] Applying migration..."

# ------------------------------------------------------------------
# New agents
# ------------------------------------------------------------------
_add_file "templates/agents/frontend-developer.md" ".claude/agents/frontend-developer.md"
_add_file "templates/agents/project-auditor.md"    ".claude/agents/project-auditor.md"
_add_file "templates/agents/security-reviewer.md"  ".claude/agents/security-reviewer.md"

# ------------------------------------------------------------------
# New / updated commands
# ------------------------------------------------------------------
_add_file "templates/commands/build-fix.md"     ".claude/commands/build-fix.md"
_add_file "templates/commands/challenge.md"     ".claude/commands/challenge.md"
_add_file "templates/commands/debug.md"         ".claude/commands/debug.md"
_add_file "templates/commands/discover.md"      ".claude/commands/discover.md"
_add_file "templates/commands/doctor.md"        ".claude/commands/doctor.md"
_add_file "templates/commands/evaluate.md"      ".claude/commands/evaluate.md"
_add_file "templates/commands/pause.md"         ".claude/commands/pause.md"
_add_file "templates/commands/resume.md"        ".claude/commands/resume.md"
_add_file "templates/commands/scan.md"          ".claude/commands/scan.md"
_add_file "templates/commands/spec-validate.md" ".claude/commands/spec-validate.md"
_add_file "templates/commands/update.md"        ".claude/commands/update.md"

# ------------------------------------------------------------------
# New rules
# ------------------------------------------------------------------
_add_file "templates/claude/rules/agents.md"               ".claude/rules/agents.md"
_add_file "templates/claude/rules/quality-general.md"      ".claude/rules/quality-general.md"
_add_file "templates/claude/rules/quality-maintainability.md" ".claude/rules/quality-maintainability.md"
_add_file "templates/claude/rules/quality-performance.md"  ".claude/rules/quality-performance.md"
_add_file "templates/claude/rules/quality-security.md"     ".claude/rules/quality-security.md"

# ------------------------------------------------------------------
# New docs / guides
# ------------------------------------------------------------------
_add_file "templates/WORKFLOW-GUIDE.md"                  "WORKFLOW-GUIDE.md"
_add_file "templates/claude/docs/agent-dispatch.md"     ".claude/docs/agent-dispatch.md"
_add_file "templates/decisions.md"                      "decisions.md"
_add_file "templates/.claudeignore"                     ".claudeignore"

# ------------------------------------------------------------------
# New hooks
# ------------------------------------------------------------------
_add_file "templates/claude/hooks/context-reinforcement.sh" ".claude/hooks/context-reinforcement.sh"

# ------------------------------------------------------------------
# Updated core files (update only if user has not modified)
# ------------------------------------------------------------------
_update_file "templates/CLAUDE.md"          "CLAUDE.md"
_update_file "templates/AGENTS.md"          "AGENTS.md"
_update_file "templates/claude/settings.json" ".claude/settings.json"

# ------------------------------------------------------------------
# Removed files (obsolete since v1.3.5)
# ------------------------------------------------------------------
_remove_file ".claude/commands/bug.md"
_remove_file ".claude/commands/context-full.md"
_remove_file ".claude/commands/grill.md"
_remove_file ".claude/hooks/statusline.sh"

echo "  [1.4.0] Done."
