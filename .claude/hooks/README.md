# Hook Configuration Guide

Hook scripts use these exit codes: `0` = pass, `1` = fail with feedback, `2` = blocked.

## Active Hooks

Wired in `.claude/settings.json`:

| Event | Hook | Purpose |
|-------|------|---------|
| `PreToolUse` | `protect-files.sh` | Block edits to `.env*`, secrets, lockfiles |
| `PreToolUse` | `circuit-breaker.sh` | Warn/block repeated edits to same file |
| `PreToolUse` | `shellcheck-guard.sh` | Lint shell scripts before edit |
| `PreToolUse` | `graph-context.sh` | Inject dependency-graph context for JS/TS edits |
| `PreToolUse` | `tool-redirect.sh` | Rewrite `git`/`grep`/etc. via `rtk`, block WebFetch when `defuddle` is available |
| `PostToolUse` | `post-edit-lint.sh` | Silent formatter run after edits |
| `UserPromptSubmit` | `context-freshness.sh` | Emit `[CONTEXT STALE]` after 5+ commits since last context regen |
| `UserPromptSubmit` | `update-check.sh` | Notify when ai-setup updates are available |
| `TaskCompleted` | `task-completed-gate.sh` | Block task completion when tests/build fail |
| `Stop` | `spec-stop-guard.sh` | Block first Stop while spec still `in-progress`, allow second within 60s |

## Behavior Notes

- `circuit-breaker.sh` warning output is intentionally strict even on `exit 0` so the model stops editing the same file before the hard block triggers.
- `post-edit-lint.sh` suppresses normal formatter/linter output to avoid fix-loop prompts from non-fatal lint noise.
- `tool-redirect.sh` rewrites bare shell commands via `rtk` for token savings; piped `git` commands and `git` rev-range args stay untouched.
- `context-freshness.sh` threshold is 5 commits — regenerate context via `npx @onedot/ai-setup` → Regenerate.
- `spec-stop-guard.sh` blocks the first Stop while a spec is still in progress, then allows a second Stop within 60 seconds.

## Debugging

```bash
# Test a hook manually
echo '{"tool_input":{"file_path":"test.js"}}' | ./.claude/hooks/protect-files.sh
echo $?  # 0 = allowed, 2 = blocked

# View/clear circuit breaker log
cat /tmp/claude-cb-*.log
rm /tmp/claude-cb-*.log
```

## Hook Types

Hooks unterstützen `type: "command"` (Shell-Skript) und ab v2.1.118 `type: "mcp_tool"` (direkt ein MCP-Tool aufrufen, kein Shell-Wrapper nötig).

```json
{
  "type": "mcp_tool",
  "server": "crewbuddy",
  "tool": "crewbuddy_create_task",
  "arguments": { "name": "..." }
}
```

Nützlich z.B. für Stop-Hook → Crewbuddy-Task oder Slack-Notification ohne Shell-Skript.

## Disabling Hooks

Remove the hook block from `.claude/settings.json`, or add `exit 0` at the top of the script.
