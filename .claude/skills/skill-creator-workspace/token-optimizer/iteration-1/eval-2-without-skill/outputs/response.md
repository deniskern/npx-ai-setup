# Token-Optimierungs-Analyse: npx-ai-setup

**Datum:** 2026-03-24
**Analysiert:** Gesamtes Projekt unter `/Users/deniskern/Sites/npx-ai-setup/`

---

## Zusammenfassung

Das Projekt ist bereits gut aufgestellt (RTK, tiered context loading, .claudeignore). Die verbleibenden Quick Wins sind jedoch erheblich — insbesondere ein 188 KB großes Log-File und ein 26 KB SKILL.md werden bei jeder Session mitgeladen.

---

## Priorisierte Empfehlungen

### P1 — Sofort, kein Risiko

#### 1. config-changes.log truncaten (188 KB → ~1 KB)
**Einsparung: ~46.000 Tokens einmalig (aus Git-Status-Rauschen)**

```
/Users/deniskern/Sites/npx-ai-setup/.claude/config-changes.log
```

1564 Einträge über 2 Tage. Die Datei wird nie aktiv von Claude gelesen, erscheint aber als Modified im Git-Status — zieht Aufmerksamkeit auf sich. Zudem ist sie NICHT in `.claudeignore` gelistet.

**Fix:** `.claudeignore` ergänzen:
```
.claude/config-changes.log
.claude/tool-failures.log
.claude/task-completed.log
.claude/agent-metrics.log
```

Alle vier Log-Dateien zusammen: ~204 KB. Keines davon ist für Claude's Reasoning notwendig.

---

#### 2. agent-browser SKILL.md verkleinern (26 KB)
**Einsparung: ~6.000 Tokens pro Aktivierung**

```
/Users/deniskern/Sites/npx-ai-setup/.claude/skills/agent-browser/SKILL.md
```

Mit 26 KB ist das der mit Abstand größte Skill — 2.5x größer als der nächste. Bei jeder Aktivierung werden 6.500+ Tokens geladen. Vollständige Befehlslisten, die auch per `agent-browser --help` abrufbar sind, sind hier das Hauptproblem.

**Fix:** Reference-Abschnitte durch `agent-browser --help` Verweis ersetzen, Kernbeispiele auf ~5 KB reduzieren.

---

### P2 — Mittelfristig, moderate Änderung

#### 3. context-reinforcement.sh: IRON LAWS jede Session doppelt
**Einsparung: ~150 Tokens/Session**

Der `SessionStart`-Hook gibt die 5 IRON LAWS als JSON-Blob aus — jedes Mal. Sie stehen bereits in CLAUDE.md. Das ist Double-Loading.

**Fix:** IRON LAWS aus `context-reinforcement.sh` entfernen oder auf 2 Zeilen komprimieren. CLAUDE.md ist die einzige Quelle.

---

#### 4. context-monitor.sh: läuft nach JEDEM Bash-Call
**Einsparung: 50-200 Tokens pro Session**

Matcher ist `Bash|Edit|Write|NotebookEdit` — der Hook startet nach jedem `ls`, `git status`, etc. Er prüft einen `/tmp/`-Bridge-File und gibt bei CRITICAL/WARNING Kontext-Warnungen aus. Die meisten Starts enden lautlos, aber jeder Hook-Start kostet CPU + minimal Context.

**Fix:** Matcher auf `Edit|Write` reduzieren — die einzigen Operationen, die Context aktiv verbrauchen und sofortige Warnung rechtfertigen.

---

#### 5. memory-recall.sh gibt irrelevante Hinweise aus
**Einsparung: ~30 Tokens/Prompt**

Bei jedem User-Prompt: der Hook erkennt dass kein `claude-mem` MCP in `.mcp.json` registriert ist — gibt aber trotzdem einen "Memory search available"-Hinweis aus. Das ist toter Output.

**Fix:** Den Hint-Branch entfernen wenn kein claude-mem MCP konfiguriert ist. `.mcp.json` ist leer (`{"mcpServers": {}}`).

---

### P3 — Strukturell, längerer Aufwand

#### 6. release/SKILL.md (9.4 KB) und token-optimizer/SKILL.md (10 KB)
**Einsparung: 2.000-4.000 Tokens pro Aktivierung**

Beide sind grenzwertig groß. Kein sofortiger Handlungsbedarf, aber bei nächster Überarbeitung auf ~4 KB reduzieren.

---

## Dateigrößen-Übersicht

| Datei | Größe | Status |
|-------|-------|--------|
| `.claude/config-changes.log` | 188 KB | Nicht in .claudeignore — Fix sofort |
| `.claude/tool-failures.log` | 12 KB | Nicht in .claudeignore — Fix sofort |
| `.claude/skills/agent-browser/SKILL.md` | 26 KB | Zu groß — kürzen |
| `.claude/skills/token-optimizer/SKILL.md` | 10 KB | Grenzwertig |
| `.claude/skills/release/SKILL.md` | 9.4 KB | Grenzwertig |
| `.claude/WORKFLOW-GUIDE.md` | 9.5 KB | OK — nur bei explizitem Aufruf |
| `.claude/commands/*.md` (total) | 108 KB | OK — on-demand via Skill-System |
| `.agents/context/` (total) | 25 KB | OK — tiered loading aktiv |

---

## Quick-Win-Checkliste

```
[ ] .claudeignore: 4 Log-Dateien in .claude/ excluden (204 KB sofort weg)
[ ] agent-browser/SKILL.md: auf ~5 KB kürzen
[ ] context-reinforcement.sh: IRON LAWS aus Hook entfernen
[ ] context-monitor.sh: Bash aus matcher entfernen
[ ] memory-recall.sh: Hint-Branch bei leerem MCP entfernen
```

**Gesamtpotenzial (konservativ):** ~50.000 Tokens einmalig (Log-Files aus Index) + 200–400 Tokens pro Session durch Hook-Optimierung + 6.000 Tokens pro agent-browser Nutzung.
