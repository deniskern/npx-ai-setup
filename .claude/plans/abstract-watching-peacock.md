# Plan: Advisor Strategy als Routing-Regel

## Context

Anthropic hat die Advisor Strategy als Beta-API-Feature geshippt (April 2026): Sonnet/Haiku als Executor + Opus als Advisor, server-seitig innerhalb eines API-Requests. Das bringt Near-Opus-Qualität zu Sonnet-Preisen (laut Benchmark: 11,9% Kosteneinsparung, +2,7pp auf SWE-bench).

Die bestehenden `.claude/rules/agents.md` kennt nur drei Modelle (haiku/sonnet/opus) als separate Subagents. Das Advisor-Pattern fehlt als Option — aktuell würde man für "Sonnet reicht nicht, aber Opus ist zu teuer" immer blind zu Opus eskalieren.

**Ziel**: `agents.md` (aktiv + Template) um eine Advisor-Routing-Option erweitern, sodass die Entscheidungstabelle vollständig ist.

## Änderungen

### 1. `.claude/rules/agents.md`

Neue Sektion nach dem Model-Routing-Table einfügen:

```markdown
## Advisor Strategy (Beta)

Wenn Sonnet allein nicht ausreicht, aber der volle Opus-Preis nicht gerechtfertigt ist:

| Scenario | Ansatz |
|----------|--------|
| Sonnet reicht | Sonnet solo |
| Komplexe Architektur / Spec | Opus solo |
| Langer agentic Task mit strategischen Entscheidungen | Sonnet + Opus-Advisor (Beta) |

**Advisor-Pattern**: Executor (Sonnet/Haiku) ruft Opus mid-task via API auf.
Beta-Header: `advisor-tool-2026-03-01`
Docs: https://platform.claude.com/docs/en/agents-and-tools/tool-use/advisor-tool

Nur relevant für eigene API-Apps (nicht Claude Code CLI selbst).
Claude Code nutzt opusplan als Äquivalent im Plan/Execute-Workflow.
```

### 2. `templates/claude/rules/agents.md`

Identische Änderung — Template muss mit aktiver Config synchron bleiben.

## Kritische Dateien

- `.claude/rules/agents.md` (Zeile ~1-50, Model-Routing-Tabelle)
- `templates/claude/rules/agents.md` (gespiegeltes Template)

## Scope

- Keine neuen Dateien
- Keine Code-Änderungen
- Kein Skill, kein Hook
- Reine Dokumentation in 2 bestehenden Dateien

## Verifikation

1. `grep -n "Advisor" .claude/rules/agents.md` — Sektion vorhanden
2. `diff .claude/rules/agents.md templates/claude/rules/agents.md` — beide synchron
3. Rauchtest: smoke-tests laufen lassen (`bash .claude/scripts/test-prep.sh`) — keine Regressionen
