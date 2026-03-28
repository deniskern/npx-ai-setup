# Spec: Fix Hardcoded Opus Default — Sonnet als Session-Default

> **Spec ID**: 593 | **Created**: 2026-03-29 | **Status**: completed | **Complexity**: simple | **Branch**: —

## Goal

`claude-sonnet-4-6` als Default-Modell in allen settings.json setzen, sodass Sessions ohne explizites `--model`-Flag nicht automatisch Opus verbrauchen.

## Context

Session-Analyse zeigt: `~/.claude/settings.json` und `sp-alpensattel-next/.claude/settings.json` haben beide `"model": "claude-opus-4-6"` hardcoded. Das überschreibt alle CLAUDE.md Model-Routing-Regeln — jede Session (auch einfache Git-Status-Fragen, Commits, Playwright-Checks) läuft auf Opus. Opus kostet 5× mehr als Sonnet. Findings-log Einträge: [T] Haiku 0%, [T] Opus für Non-Code-Sessions.

## Steps

- [ ] `~/.claude/settings.json`: `"model"` auf `"claude-sonnet-4-6"` ändern
- [ ] `/Users/deniskern/Sites/sp-alpensattel-next/.claude/settings.json`: `"model"` auf `"claude-sonnet-4-6"` ändern
- [ ] Prüfen ob weitere Projekte in `~/Sites/` settings.json mit Opus haben: `grep -r '"model": "claude-opus' ~/Sites/*/​.claude/settings.json`
- [ ] Für gefundene Projekte ebenfalls auf Sonnet ändern

## Acceptance Criteria

- [ ] `~/.claude/settings.json` hat `"model": "claude-sonnet-4-6"`
- [ ] `sp-alpensattel-next/.claude/settings.json` hat `"model": "claude-sonnet-4-6"`
- [ ] Keine weiteren Projekte mit hardcoded Opus als Default (außer explizit begründet)
- [ ] Template settings.json in npx-ai-setup hat Sonnet als Default

## Files to Modify

- `~/.claude/settings.json` - model default
- `/Users/deniskern/Sites/sp-alpensattel-next/.claude/settings.json` - model default
- `/Users/deniskern/Sites/npx-ai-setup/templates/claude/settings.json` - template default

## Out of Scope

- Subagent model routing (bereits in agents.md geregelt)
- Skill-Invoking-Verhalten in sp-alpensattel (separates Problem)
- Obsidian-Projekte (kein settings.json vorhanden)
