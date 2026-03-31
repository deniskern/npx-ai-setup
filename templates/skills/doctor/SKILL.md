---
name: doctor
description: "Run AI setup health check (12 checks: hooks, settings, context files, CLAUDE.md size, MCP, skills, scripts, git config, metadata, specs)."
---

Run AI setup health check (12 checks: hooks, settings, context files, CLAUDE.md size, MCP, skills, scripts, git config, metadata, specs).

!.claude/scripts/doctor.sh

## Next Step

If checks fail, run `/update` to install the latest version, or fix the reported issues manually and re-run `/doctor`.
