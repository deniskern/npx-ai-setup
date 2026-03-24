# Token-Optimierungs-Analyse: npx-ai-setup

**Datum:** 2026-03-24
**Methode:** Statische Analyse aller auto-geladenen und on-demand Dateien

---

## 1. Token-Footprint nach Kategorie

| Kategorie | Bytes | ~Tokens | Frequenz |
|-----------|-------|---------|----------|
| **Rules** (`.claude/rules/*.md`) | 8.068 | ~2.017 | Jede Session |
| **CLAUDE.md** (Projekt) | 5.241 | ~1.310 | Jede Session |
| **Globale User-Dateien** (CLAUDE.md, RTK.md, learnings.md, personal-info.md) | 5.771 | ~1.443 | Jede Session |
| **Iron Laws** (context-reinforcement.sh output) | ~600 | ~150 | Jede Session |
| **Context-Loader** (L0 abstracts, 3 Dateien mit Frontmatter) | ~400 | ~100 | Jede Session |
| **memory-recall.sh** (Hint bei jedem UserPromptSubmit) | ~200 | ~50 | Jeder Prompt |
| **agent-browser SKILL.md** | 26.664 | ~6.666 | On-demand |
| **token-optimizer SKILL.md** | 11.621 | ~2.905 | On-demand |
| **release SKILL.md** | 9.380 | ~2.345 | On-demand |
| **gh-cli references/full.md** | 40.412 | ~10.103 | On-demand |
| **CHANGELOG.md** | 31.921 | ~7.980 | Bei Bedarf gelesen |
| **config-changes.log** | 184.800 | ~46.200 | Nicht auto-geladen |
| **tool-failures.log** | 17.187 | ~4.297 | Nicht auto-geladen |

**Feste Baseline pro Session:** ~5.020 Tokens (Rules + CLAUDE.md + Global + Iron Laws + Context-L0)

---

## 2. Kritische Befunde

### Problem 1: agent-browser SKILL.md — 26 KB / ~6.600 Tokens
- Datei: `.claude/skills/agent-browser/SKILL.md` (686 Zeilen)
- Das SKILL.md enthält den gesamten Referenz-Inhalt direkt — obwohl die übrigen Referenzen schon in separaten Dateien unter `references/` ausgelagert sind (commands.md, authentication.md usw.)
- Das SKILL.md lädt also das komplette Wissen bei jeder Browser-Session in den Kontext
- **Potenzial:** ~4.000–5.000 Tokens reduzierbar durch Extraktion in `references/` und Verweis-Pattern wie bei gh-cli

### Problem 2: gh-cli references/full.md — 40 KB / ~10.100 Tokens
- Datei: `.claude/skills/gh-cli/references/full.md`
- Eine einzelne Referenzdatei mit 40 KB ist zu grob — sie wird komplett geladen, auch wenn nur 5% relevant sind
- **Potenzial:** Aufteilen nach Thema (pr, issue, release, auth) — jeweils ~3–5 KB — nur relevante Sektion laden

### Problem 3: CHANGELOG.md — 31 KB / ~8.000 Tokens
- Datei: `CHANGELOG.md` (Projekt-Root)
- Claude liest diese Datei regelmäßig beim Release-Workflow oder wenn nach Versionshistorie gefragt wird
- Mit 31 KB und wachsender Tendenz wird jede Leseop teuer
- **Potenzial:** Archiv nach `CHANGELOG-archive.md` auslagern (alles vor dem aktuellen Major), aktive Datei auf ~3 KB kürzen

### Problem 4: memory-recall.sh — falscher Auslöser
- Datei: `.claude/hooks/memory-recall.sh`
- Der Hook feuert bei **jedem UserPromptSubmit** und injiziert immer einen Hinweis (`claude-mem MCP is active`) — auch bei simplen Prompts
- Die Ausgabe ist ein statischer String ohne echten Inhalt — kostet ~50 Tokens pro Prompt ohne Nutzen
- **Potenzial:** Early-exit bei aktivem claude-mem, kein Output ausgeben — der MCP ist sowieso aktiv

### Problem 5: config-changes.log — 185 KB angewachsen
- Datei: `.claude/config-changes.log`
- 1.572 Zeilen, alle identisch (settings.json change event wird bei jeder Session mehrfach geschrieben)
- Liegt ohne `.claudeignore`-Eintrag im Repo — bei `@`-Referenz oder Glob komplett eingelesen
- **Potenzial:** Rotieren (max. 100 Einträge behalten), `.claude/*.log` zur `.claudeignore` hinzufügen

### Problem 6: WORKFLOW-GUIDE.md — 9,2 KB, nicht im Kontext-Pfad
- Datei: `.claude/WORKFLOW-GUIDE.md`
- Wird nicht auto-geladen, aber bei explizitem Lesen sind es ~2.300 Tokens
- Kandidat für Kürzung auf das CLAUDE.md-Prinzip (max. 5–8 Zeilen pro Section)

---

## 3. Priorisierte Empfehlungen

### Hoch (sofort, >1.000 Tokens Ersparnis pro relevanter Session)

1. **agent-browser SKILL.md schlankhalten**
   Den Hauptinhalt auf Kern-Workflow (~50 Zeilen) reduzieren, Details in bestehende `references/`-Dateien auslagern.
   Ersparnis: ~5.000 Tokens pro Browser-Session.

2. **gh-cli references/full.md aufsplitten**
   In thematische Sektionen aufteilen (`pr.md`, `issue.md`, `release.md`). SKILL.md verweist nur noch auf relevante Datei.
   Ersparnis: ~8.000 Tokens pro gh-cli-Session (70% Reduktion).

3. **CHANGELOG.md rotieren**
   Alles vor v1.0 (oder älter als 6 Monate) in `CHANGELOG-archive.md` verschieben.
   Ersparnis: ~6.000–7.000 Tokens bei Leseops.

### Mittel (lohnend, <1.000 Tokens aber konstant)

4. **memory-recall.sh Hinweis entfernen**
   Early-exit bei aktivem claude-mem ohne Output.
   Ersparnis: ~50 Tokens x Prompts pro Session — kumulativ relevant.

5. **config-changes.log in .claudeignore aufnehmen und rotieren**
   `.claude/*.log` zur `.claudeignore` hinzufügen. Log-Rotation auf max. 200 Einträge.
   Präventiv, kein akutes Token-Problem.

### Niedrig (Nice-to-have)

6. **WORKFLOW-GUIDE.md kürzen**
   Auf ~3 KB komprimieren (CLAUDE.md-Prinzip: max. 5–8 Zeilen pro Section).
   Ersparnis: ~1.500 Tokens wenn explizit gelesen.

---

## 4. Was bereits gut funktioniert

- **Context-Loader** nutzt Frontmatter-Abstracts korrekt — alle 3 Dateien haben `---`-Frontmatter, Ziel ~400 Tokens wird eingehalten.
- **context-reinforcement.sh** ist minimal und hardcoded (~150 Tokens, kein I/O).
- **Rules** sind schlank (8 KB total / ~2.000 Tokens für 8 Dateien).
- **CLAUDE.md** Projekt-Datei hält sich an das 5–8-Zeilen-Prinzip.
- **enableAllProjectMcpServers** unkritisch — `.mcp.json` ist 23 Bytes (kein aktiver Server).
- **CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: "80"** ist ein guter Wert.

---

## 5. Zusammenfassung

**Gesamte erzielbare Ersparnis (bei aktiver Nutzung):**

| Maßnahme | Kontext | Tokens gespart |
|----------|---------|----------------|
| agent-browser SKILL.md kürzen | Pro Browser-Session | ~5.000 |
| gh-cli references/full.md splitten | Pro gh-cli-Session | ~8.000 |
| CHANGELOG.md rotieren | Pro Release-Leseop | ~7.000 |
| memory-recall.sh Hinweis entfernen | Pro Session (~20 Prompts) | ~1.000 |

**Kernaussage:** Die Session-Baseline (~5.000 Tokens) ist bereits gut optimiert. Der Kontext füllt sich schnell wegen der Skill-Dateigröße beim ersten Einsatz von agent-browser oder gh-cli. Dort liegt der größte Hebel.
