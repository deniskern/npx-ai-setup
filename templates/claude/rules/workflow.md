# Workflow Routing

## Skill Hints

After completing work, suggest the logical next skill. Keep hints to one line.

| After this... | Suggest |
|---------------|---------|
| Code changes (edit/write) | `/test` — Tests laufen lassen |
| `/test` passes | `/review` — Changes reviewen |
| `/review` passes | `/commit` — Stagen + committen |
| `/commit` done | `/pr` auf Feature-Branches, oder `/release` auf `main` / `master` |
| Bug investigation | `/debug` falls noch nicht geladen |
| Multi-file changes (3+ files, incl. config/rules) | `/spec` — erst planen, dann bauen |
| Session start + `.continue-here.md` exists | `/resume` — State wiederherstellen |
| Session >30 tool calls | `/reflect` — Learnings sichern, dann `/pause` |
| Build failure | `/build-fix` — iterativ fixen |
| Pre-release | `/release` — Version bump, CHANGELOG, Tag |

## When to Auto-Invoke Skills

Claude MAY invoke these skills programmatically (via Skill tool) when the context clearly calls for it:
- `/spec-work NNN` — after context compaction when the active spec is known
- `/resume` — at session start when `.continue-here.md` exists
- `/spec-board` — when user asks for spec overview

**User-only skills** (`disable-model-invocation: true`) — NEVER invoke via Skill tool, only suggest:
- `/commit`, `/pause`, `/release`, `/reflect`, `/update`

Claude SHOULD NOT auto-invoke without user intent:
- `/pr` — always confirm first
- `/spec` — only when user explicitly wants a spec

## Hint Format

After completing a step, append one line:

```
> Naechster Schritt: `/command` — kurze Beschreibung
```

Do not stack multiple hints. Pick the single most relevant next action.
