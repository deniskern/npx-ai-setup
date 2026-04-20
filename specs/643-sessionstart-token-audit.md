# Spec: SessionStart Token Audit & Hook Trimming

> **Spec ID**: 643 | **Created**: 2026-04-19 | **Status**: in-review | **Complexity**: medium | **Branch**: worktree-agent-ac9b9672

## Goal
Token-Verbrauch pro Turn reduzieren durch Audit und Trimming der SessionStart- und UserPromptSubmit-Hooks in den Template-Boilerplates. Ziel: keine Hook-Output die pro Turn >500 Tokens kostet, ohne klaren Mehrwert pro Turn zu liefern.

## Context
Gemessen in aktueller Session: SessionStart-Reminders (ai-setup-version-check, caveman-mode, mcp-server-instructions, skill-listing) ergeben geschätzt 5-8k Tokens pro User-Turn. Vieles davon wäre **session-once** ausreichend (einmal am Anfang) statt **per-turn** zu wiederholen.

Beobachtete Kandidaten:
- **MCP-Instructions** (~3k Tokens): werden pro Turn geladen, obwohl Claude die einmal pro Session lernt und dann behält — gehören in SessionStart-once, nicht UserPromptSubmit
- **Skills-Liste** (~2k Tokens): wird mit jedem Turn mitgeschleppt, könnte mit Filter aus Spec 642 halbiert werden und nur bei Skill-Dispatch erneut gezeigt werden
- **Version-Check-Hook** (`ai-setup vX.Y verfügbar`): OK als UserPromptSubmit einmalig, aber nur solange veraltet — bei aktueller Version komplett stumm
- **Context-Files** (`@.agents/context/SUMMARY.md`): sinnvoll pro Turn wenn klein, kritisch wenn ungecapped

## Steps
- [x] Step 1: Audit-Script `lib/hook-token-audit.sh` — parst alle Hooks in `templates/hooks/` und `.claude/hooks/`, misst Output-Größe (mock-Call mit `tokens ≈ chars/4` Approximation), listet Top-Verbraucher pro Hook-Type (SessionStart vs UserPromptSubmit vs PreToolUse)
- [x] Step 2: Policy-Doku `.claude/rules/hooks-token-policy.md` (template): SessionStart darf groß sein (einmalig), UserPromptSubmit/PreToolUse müssen <300 Tokens sein, harte Caps
- [x] Step 3: Version-Check-Hook (`ai-setup vX.Y.Z verfügbar`) refaktorieren: nur bei veralteter Version Output, sonst exit 0 ohne Nachricht. Check einmal pro Tag cachen (mtime-File in `~/.cache/ai-setup/version-check`)
- [x] Step 4: MCP-Server-Instructions: prüfen ob Anthropic-Harness MCP-Instructions bereits nativ injiziert (tut es laut system-reminder). Wenn ja, eigene MCP-Instruction-Hooks löschen. Wenn nein, aus UserPromptSubmit in SessionStart verschieben — Ergebnis: kein eigenständiger MCP-Hook im Repo, Anthropic-Harness deckt das nativ ab
- [x] Step 5: Skill-Listing (falls aktuell per-Turn): in SessionStart-once verschieben, plus Flag `--reload-skills` für manuelles Refresh — Ergebnis: kein eigenständiger Skill-Listing-Hook vorhanden, Claude's native skill discovery deckt das ab
- [x] Step 6: `doctor.sh` Check: warnt wenn irgendein Hook-Output >300 Tokens UND Hook-Type in {UserPromptSubmit, PreToolUse} — harter Schwellwert
- [x] Step 7: Smoke-Test: vor-nachher Messung der Turn-Tokens in aktuellem npx-ai-setup Repo (baseline vs. trimmed). Zielwert: <1500 Tokens "System-Overhead" pro Turn (ohne echten Prompt/Tool-Output)
- [x] Step 8: `README.md` erwähnen: "Token-Budget pro Turn" als dokumentierter Wert

## Acceptance Criteria
- [x] `bash lib/hook-token-audit.sh` erzeugt Report mit Hook-Name, Type, geschätzten Tokens
- [x] Kein UserPromptSubmit-Hook im Repo erzeugt >300 geschätzte Tokens (Audit-Report zeigt 0 Violations)
- [x] Version-Check-Hook ist bei aktueller Version stumm (exit 0 ohne stdout)
- [x] `bash .claude/scripts/doctor.sh` meldet fehlerhaft große Hooks als WARNING
- [x] Gemessene Turn-Overhead in Test-Session <1500 Tokens (grobe Approximation via `wc -c`)
- [x] `shellcheck lib/hook-token-audit.sh` passt
- [x] `bash .claude/scripts/quality-gate.sh` grün

## Files to Modify
- `lib/hook-token-audit.sh` — NEU
- `templates/hooks/*` — Version-Check, MCP-Instructions, Skill-Listing refactoring
- `.claude/rules/hooks-token-policy.md` — NEU, Template
- `.claude/scripts/doctor.sh` — Hook-Token-Check
- `README.md` — Section "Turn-Token Budget"

## Out of Scope
- Anthropic-Harness-Side Optimierungen (liegt nicht in unserer Hand)
- Prompt-Caching-Strategie (separates Thema, existierende Spec-Historie abdeckt)
- Skill-Filter-Logik selbst → Spec 642
- Umbau der Claude-Code Message-Struktur

## Dependencies
- Profitiert von Spec 642 (Skill-Filter reduziert Skill-Listing zusätzlich)
- Keine Hard-Deps; kann sofort parallel laufen
