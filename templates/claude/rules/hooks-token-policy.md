# Hook Token Policy

## Caps

| Hook Type | Cap | Rationale |
|-----------|-----|-----------|
| `SessionStart`, `PreCompact` | **2000 tokens** | One-shot — fires once per session |
| `UserPromptSubmit`, `PreToolUse`, `PostToolUse`, `Stop`, `TaskCompleted` | **300 tokens** | Per-turn — cost multiplies with session length |

## Rules

- Silent on the happy path — output only when actionable. No "all OK" confirmations.
- Errors and warnings go to **stderr** (`>&2`) to avoid polluting Claude's input context.
- Hooks that must exceed the cap require a `# TOKEN-POLICY-EXCEPTION: <reason>` comment.
- Run `bash lib/hook-token-audit.sh` to verify before committing hook changes.

## Audit

```bash
bash lib/hook-token-audit.sh          # check templates/ + .claude/hooks/
bash lib/hook-token-audit.sh .claude/hooks   # project hooks only
```
