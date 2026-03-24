# Token-Audit: npx-ai-setup

**Datum:** 2026-03-24
**Methodik:** Byte-Analyse aller Projektdateien, ~4 Bytes pro Token

---

## Zusammenfassung

Das Projekt enthält schätzungsweise **~255.000 tokens** an Dateimaterial. Davon landen bei normaler Arbeit pro Session aktiv im Kontext:

| Schicht | Automatisch geladen? | ~Tokens |
|--------|---------------------|---------|
| SessionStart hooks (context-reinforcement, context-loader, memory-recall) | Ja | ~400 |
| `.agents/context/` abstracts (STACK, ARCH, CONV) | Ja (via context-loader) | ~300–600 |
| Skills beim Aufruf (SKILL.md + references) | On-demand | variiert |
| Global CLAUDE.md + RTK.md + learnings.md | Ja (immer) | ~1.250 |
| MEMORY.md (project) | Ja | ~375 |
| CHANGELOG.md | Nur wenn explizit gelesen | ~8.000 |

---

## Top-Verursacher nach Dateigröße

| Rang | Datei / Verzeichnis | Bytes | ~Tokens | Status |
|-----|---------------------|-------|---------|--------|
| 1 | `templates/` (gesamt, 124 Dateien) | 462.878 | **~115.700** | Nie direkt im Kontext |
| 2 | `.claude/config-changes.log` | 183.900 | **~46.000** | Nicht in `.claudeignore` |
| 3 | `.claude/skills/` (alle SKILL.md + refs) | 155.976 | **~39.000** | Nur on-demand |
| 4 | `specs/` (gesamt) | 60.618 | **~15.200** | Nur wenn gelesen |
| 5 | `.claude/agents/` (12 Agent-Dateien) | 38.993 | **~9.750** | Nur bei Agent-Spawn |
| 6 | `CHANGELOG.md` | 31.921 | **~8.000** | Gefährlich: leicht versehentlich geladen |
| 7 | `.agents/context/` (8 Dateien gesamt) | 25.753 | **~6.440** | Teilweise auto-geladen |
| 8 | `.claude/tool-failures.log` | 12.862 | **~3.200** | Nicht in `.claudeignore` |
| 9 | `README.md` | 12.178 | **~3.050** | Root-Ebene, leicht mitgezogen |

---

## Konkrete Probleme & Empfehlungen

### P1: `.claude/config-changes.log` — ~46.000 Tokens, unkontrolliert

**Problem:** Die Datei ist 184 KB groß (1.564 Zeilen) und wächst unbegrenzt. Sie ist nicht in `.claudeignore` eingetragen. Wenn Claude per Globbing oder bei der Suche nach `*.log` drüberstolpert, fließen ~46k Tokens ins Kontext.

**Fix:**
Ergänzung in `.claudeignore`:
  .claude/config-changes.log
  .claude/tool-failures.log
  .claude/agent-metrics.log
  .claude/task-completed.log

Zusätzlich: Log-Rotation einbauen (z.B. max. 200 Zeilen behalten via `tail -200`).

---

### P2: `CHANGELOG.md` — ~8.000 Tokens, kein Schutz

**Problem:** `CHANGELOG.md` liegt im Root, wird bei `@CHANGELOG.md` oder flächigem File-Read mitgeladen. 32 KB für ein Changelog ist ungewöhnlich hoch — wahrscheinlich enthält es vollständige Commit-Bodies.

**Fix:**
- `.claudeignore` Eintrag: `CHANGELOG.md`
- Alternativ: CHANGELOG in komprimiertes Format kürzen (nur Versions-Header + 1-Zeiler).

---

### P3: `skills/gh-cli/references/full.md` — ~10.000 Tokens

**Problem:** Eine einzelne Reference-Datei mit 40 KB. Wird bei `gh-cli`-Skill-Aufrufen vollständig geladen — auch wenn nur ein einfaches `gh pr list` gebraucht wird.

**Fix:**
- In kleinere Sections aufteilen (z.B. `pr.md`, `issue.md`, `release.md`)
- SKILL.md verweist dann nur auf den relevanten Teil
- Geschätzter Einspar-Effekt: 60–80% der Tokens bei Partial-Nutzung

---

### P4: `agent-browser/SKILL.md` + references — zusammen ~34.000 Tokens

**Problem:** Die agent-browser-Skill-Suite ist extrem groß: SKILL.md (26 KB) + 5 Reference-Dateien (27 KB) = ~53 KB gesamt. Bei jedem Browser-Task potentiell ~13.000 Tokens.

**Fix:**
- SKILL.md auf das absolute Minimum reduzieren (Trigger, Usage, 5–10 Kernbefehle)
- Reference-Dateien lazy: nur bei spezifischem Sub-Bedarf laden (Authentifizierung, Video etc.)
- Ziel: SKILL.md unter 5 KB

---

### P5: `.agents/context/` — Sessions laden zu viel

**Problem:** Der `context-loader` Hook lädt automatisch STACK.md, ARCHITECTURE.md, CONVENTIONS.md — das sind die Abstracts (~300–600 Tokens). Das ist OK. Aber wenn `/context-load all` aufgerufen wird, fließen alle 8 Dateien (25 KB / ~6.440 Tokens) auf einmal in den Kontext.

**Fix:** Aktuell schon durch Abstract-System gut gelöst. Keine Sofortmaßnahme nötig — aber DESIGN-DECISIONS.md (5 KB) und CONCEPT.md (4 KB) sollten ebenfalls Abstracts im Frontmatter bekommen.

---

### P6: `specs/` enthält abgeschlossene Research-Specs — ~15.000 Tokens

**Problem:** Research-Specs wie `570-research-just-ship.md` (13 KB) und `170-research-gastown.md` (11 KB) sind abgeschlossene Analysen ohne laufenden Task-Bezug. Sie bleiben aber in `specs/` und können bei Glob-Patterns mitgezogen werden.

**Fix:**
- Abgeschlossene Specs nach `specs/archive/` verschieben
- `specs/archive/` in `.claudeignore` eintragen

---

### P7: `templates/` — ~115.700 Tokens, nie direkt nötig

**Problem:** Das größte Verzeichnis des Projekts. Templates werden von `npx @onedot/ai-setup` genutzt, nie von Claude direkt gelesen. Kein Schutz vorhanden.

**Fix:**
Ergänzung in `.claudeignore`: `templates/`

Risiko: 0 (Templates sind Output-Artefakte, kein Kontext für Coding-Tasks).

---

## Prioritätsliste (Aufwand vs. Einsparung)

| Prio | Maßnahme | Aufwand | Einsparung |
|------|---------|---------|------------|
| 1 | Log-Dateien in `.claudeignore` | 2 Min | ~49.000 Tokens |
| 2 | `templates/` in `.claudeignore` | 1 Min | ~115.000 Tokens |
| 3 | `CHANGELOG.md` in `.claudeignore` | 1 Min | ~8.000 Tokens |
| 4 | `specs/archive/` anlegen + ignorieren | 10 Min | ~10.000 Tokens |
| 5 | `gh-cli/references/full.md` splitten | 30 Min | ~6.000 Tokens/Aufruf |
| 6 | `agent-browser/SKILL.md` kürzen | 1 Std | ~8.000 Tokens/Aufruf |

**Sofortiger Gewinn mit Maßnahmen 1–4:** `.claudeignore` 4 Zeilen ergänzen + `templates/` -> ~182.000 Tokens weniger im Risikobereich.

---

## Was bereits gut funktioniert

- **Abstract-System** in `.agents/context/` — SessionStart lädt nur Kurzfassungen, nicht die vollen Dateien. Solides Pattern.
- **CLAUDE.md ist kompakt** (5 KB) — keine Redundanzen.
- **RTK** ist konfiguriert und aktiv — spart CLI-Output-Tokens automatisch.
- **`enableAllProjectMcpServers: true`** ist konfiguriert — MCP Gateway reduziert Tool-Definitionen von ~30k auf ~400 Tokens.
- **`MAX_MCP_OUTPUT_TOKENS: 10000`** begrenzt MCP-Outputs.
- **`CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: 80`** — frühzeitiges Compact vor Context-Overflow.

---

## Fazit

Der Kontext füllt sich primär durch **drei Risiko-Quellen**, die mit minimalen `.claudeignore`-Einträgen sofort entschärft werden können:

1. Wachsende Log-Dateien (config-changes.log: 46k Tokens)
2. Templates-Verzeichnis (115k Tokens)
3. CHANGELOG.md (8k Tokens)

Die Skills-Architektur ist on-demand und grundsätzlich richtig aufgebaut — aber einzelne Skill-Dateien (agent-browser, gh-cli) sind zu groß für ihren Einsatzzweck.
