---
paths:
  - "**/*.ts"
  - "**/*.js"
  - "**/*.vue"
  - "**/*.sh"
  - "specs/**"
  - ".claude/skills/**"
---

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
| Planning a multi-file change (3+ files, new dep, or arch change) | `/spec` — erst planen, dann bauen |
| Spec erstellt (Status: draft) | `/spec-validate NNN` — Qualität prüfen vor Umsetzung |
| Spec erstellt oder abgeschlossen | `/clear` — Session leeren, Kontext-Bleed vermeiden |
| Session >30 tool calls | `/reflect` — Learnings sichern, dann `/clear` |
| Build failure | `/build-fix` — iterativ fixen |
| Pre-release | `/release` — Version bump, CHANGELOG, Tag |
| Viele neue Dateien committed (>5) | `/analyze` — graph.json + Context-Dateien neu generieren |

## When to Auto-Invoke Skills

Claude MAY invoke these skills programmatically (via Skill tool) when the context clearly calls for it:
- `/spec-work NNN` — after context compaction when the active spec is known
- `/spec-board` — when user asks for spec overview

**User-only skills** (`disable-model-invocation: true`) — NEVER invoke via Skill tool, only suggest:
- `/commit`, `/release`, `/reflect`, `/update`

Claude SHOULD NOT auto-invoke without user intent:
- `/pr` — always confirm first
- `/spec` — only when user explicitly wants a spec

## Hint Format

After completing a step, append one line:

```
> Naechster Schritt: `/command` — kurze Beschreibung
```

Do not stack multiple hints. Pick the single most relevant next action.
