# Hook Configuration Guide

## Active Hooks

| Hook | Event | Purpose | Customization |
|------|-------|---------|---------------|
| `protect-files.sh` | PreToolUse | Blocks edits to `.env`, `package-lock.json`, `.git/` | Edit `PROTECTED` array |
| `circuit-breaker.sh` | PreToolUse | Warns at 5 edits, blocks at 8 edits to same file in 10 min | Edit `WARN`/`BLOCK`/`WINDOW` vars |
| `post-edit-lint.sh` | PostToolUse | Optional file-scoped project `format` script (bun/npm), then fallback ESLint on `.js`/`.ts`/`.jsx`/`.tsx` and Prettier on `.css`/`.html`/`.json`/`.md`/`.vue`/`.svelte` | Add extensions or change tools |
| `post-tool-failure-log.sh` | PostToolUseFailure | Appends failed tool calls to `.claude/tool-failures.log` | Change log format/truncation |
| `config-change-audit.sh` | ConfigChange | Audits config changes and blocks unsafe settings (`disableAllHooks`, `Bash(*)`) | Extend blocked settings checks |
| `task-completed-gate.sh` | TaskCompleted | Blocks closing tasks with TODO/TBD/WIP markers or unresolved merge conflict markers | Adjust validation patterns |
| `update-check.sh` | SessionStart + UserPromptSubmit | Checks for newer `ai-setup` versions (cached, non-blocking) and resets circuit-breaker log | Adjust cache TTL/source strategy |
| `cross-repo-context.sh` | SessionStart | Loads sibling repo context via `.agents/context/repo-group.json` (preferred, any framework) or fallback `sw-<module>-<project>` discovery | Adjust map format, naming fallback, summary sources |
| `context-freshness.sh` | UserPromptSubmit | Warns when `.agents/context/` is stale | Runs silently unless project files changed |

**Exit codes:** `0` = pass, `1` = fail with feedback, `2` = blocked

## Debugging

```bash
# Test a hook manually
echo '{"tool_input":{"file_path":"test.js"}}' | ./.claude/hooks/protect-files.sh
echo $?  # 0 = allowed, 2 = blocked

# View/clear circuit breaker log
cat /tmp/claude-cb-*.log
rm /tmp/claude-cb-*.log
```

## Disabling Hooks

Remove the hook block from `.claude/settings.json`, or add `exit 0` at the top of the script.
