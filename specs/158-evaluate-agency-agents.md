# Spec 158: Agency-Agents Pattern-Adaption

> Status: In Progress
> Source: https://github.com/msitarzewski/agency-agents
> Erstellt: 2026-03-22

## Goal

Wertvolle Patterns aus der agency-agents Bibliothek (170+ Agents, MIT) in unsere 12 Agents uebernehmen. Fokus auf Qualitaetsverbesserung bestehender Agents — keine neuen Agents.

## Context

Evaluierung ergab 11 potenzielle Adaptionen. Prio 1 (4 Items) wurde sofort umgesetzt. Diese Spec trackt den Gesamtfortschritt und die verbleibenden Prio-2-Items.

## Steps

### Step 1: Reality-Checker Pattern in verify-app ✅
- [x] "Default to NEEDS WORK" Mindset hinzugefuegt
- [x] "Evidence over claims" Regel
- [x] "Maximum 3 retry cycles" Limit
- Files: `templates/agents/verify-app.md`, `.claude/agents/verify-app.md`

### Step 2: Single-Pass Review in code-reviewer ✅
- [x] "One review, complete feedback" Regel hinzugefuegt
- Files: `templates/agents/code-reviewer.md`, `.claude/agents/code-reviewer.md`

### Step 3: ADR + Principles + Selection Guide in code-architect ✅
- [x] "No architecture astronautics" Prinzip
- [x] "Reversibility over optimality" Prinzip
- [x] ADR-Template (Status/Context/Decision/Consequences)
- [x] Architektur-Selektions-Matrix (Monolith/Microservices/Event-driven/CQRS)
- Files: `templates/agents/code-architect.md`, `.claude/agents/code-architect.md`

### Step 4: Agent YAML Frontmatter Standard
- [ ] Emoji + Vibe Felder zu allen 12 Agents hinzufuegen
- [ ] Schema in README dokumentieren
- [ ] Beide Verzeichnisse synchron halten
- Ausgelagert in: `specs/159-agent-yaml-frontmatter-standard.md`

### Step 5: Agent-Lint-Script
- [ ] `scripts/lint-agents.sh` erstellen
- [ ] Frontmatter-Validierung, Pflicht-Sektionen, Mindestlaenge
- Ausgelagert in: `specs/159-agent-yaml-frontmatter-standard.md`

## Verworfene Items (mit Begruendung)

| Item | Grund |
|------|-------|
| NEXUS Pipeline (Phase 0-6) | Ueberdimensioniert, unser Spec-System ist fokussierter |
| Non-Engineering Agents (80+) | Ausserhalb Core-Scope, wir sind Developer-Tool |
| Multi-Tool Support | Claude-Code-Fokus ist Staerke, nicht Schwaeche |
| MCP-Builder Agent | Nischen-Usecase, keine neuen Agents gewuenscht |
| Workflow-Beispiel-Templates | Token-Overhead, unser Command-System reicht |

## Acceptance Criteria
- [x] verify-app hat skeptischen Default-Bias
- [x] code-reviewer macht Single-Pass Reviews
- [x] code-architect liefert ADRs und hat Selektions-Matrix
- [ ] Frontmatter-Standard (Spec 159)
- [ ] Lint-Script (Spec 159)

## Files Modified
- `templates/agents/verify-app.md` ✅
- `templates/agents/code-reviewer.md` ✅
- `templates/agents/code-architect.md` ✅
- `.claude/agents/verify-app.md` ✅
- `.claude/agents/code-reviewer.md` ✅
- `.claude/agents/code-architect.md` ✅
