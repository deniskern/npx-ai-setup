# Token-Optimierungs-Analyse: npx-ai-setup

**Datum:** 2026-03-24
**Scope:** Projekt `/Users/deniskern/Sites/npx-ai-setup`

---

## Zusammenfassung

Das Projekt hat eine solide Token-Optimierungs-Grundlage (RTK, prep-scripts, L0-context-loader). Es gibt jedoch drei sofort hebbare Probleme, die zusammen mehrere tausend Tokens pro Session kosten.

---

## Priorisierte Empfehlungen

### P1 — config-changes.log rotieren (Aufwand: 5 Min, Impact: hoch)

**Problem:** `.claude/config-changes.log` ist **189 KB / ~47.000 Tokens**. Der Hook `config-change-audit.sh` schreibt bei jedem `ConfigChange`-Event hinein — ohne Rotation.

**Sofortmaßnahme:**
```bash
tail -100 .claude/config-changes.log > /tmp/cfg.log && mv /tmp/cfg.log .claude/config-changes.log
```

**Dauerhaft:** In `config-change-audit.sh` am Ende hinzufügen:
```bash
tail -200 "$LOG_FILE" > "$LOG_FILE.tmp" && mv "$LOG_FILE.tmp" "$LOG_FILE"
```

**Einsparung:** ~47.000 Tokens, wenn die Datei je explizit gelesen wird. Verhindert unbegrenztes Wachstum.

---

### P2 — agent-browser skill.md kürzen (Aufwand: 15 Min, Impact: mittel)

**Problem:** `/Users/deniskern/Sites/npx-ai-setup/.claude/skills/agent-browser/skill.md` ist **26 KB / ~6.666 Tokens**. Das ist ~10x größer als die nächstgrößte Skill-Datei. Die Datei wird bei jeder Nutzung des Skills vollständig in den Kontext geladen.

**Was drin ist:** Sehr detaillierte Befehlsreferenz mit vielen Codebeispielen, die per `agent-browser --help` abrufbar sind.

**Maßnahme:** Auf Core Workflow + kritische Befehle kürzen. Alles was `--help` erklärt, raus. Ziel: unter 200 Zeilen (~2.000 Tokens).

**Einsparung:** ~4.500 Tokens pro Session mit Browser-Automation.

---

### P3 — Context-Dateien ohne YAML-Frontmatter (Aufwand: 10 Min, Impact: mittel)

**Problem:** `context-loader.sh` liest nur STACK/ARCHITECTURE/CONVENTIONS per L0-Abstract. Dateien wie `DESIGN-DECISIONS.md` (67 Zeilen), `AUDIT.md` (79 Zeilen), `CONCEPT.md` (67 Zeilen) haben kein YAML-Frontmatter — fallback ist `head -20`, also Rohzeilen statt kompaktem Abstract.

**Maßnahme:** YAML-Frontmatter mit `abstract:` zu den 3 Dateien hinzufügen.

**Einsparung:** ~200-400 Tokens pro SessionStart.

---

### P4 — token-optimizer skill.md kürzen (Aufwand: 20 Min, Impact: niedrig-mittel)

**Problem:** `token-optimizer/skill.md` ist **11 KB / ~2.905 Tokens** bei 350 Zeilen. Enthält viel Referenzmaterial das erst bei Bedarf nötig ist.

**Maßnahme:** Zweistufig: kompakte skill.md (max 80 Zeilen) + separate references/guide.md für Details.

**Einsparung:** ~2.000 Tokens wenn der Skill triggered wird.

---

### P5 — tool-failures.log wächst (Aufwand: 5 Min, Impact: niedrig)

**Problem:** `.claude/tool-failures.log` ist bereits **15 KB**. Kein Rotation-Mechanismus.

**Maßnahme:** In `post-tool-failure-log.sh` Rotation hinzufügen (max 100 Einträge).

---

## Was bereits gut läuft

| Bereich | Status |
|---------|--------|
| RTK hook-basiert aktiv | Spart 60-90% bei git/grep/test-Output |
| L0 context-loader | Lädt nur Abstracts (~400 Tokens statt ~2.000) |
| YAML-Frontmatter auf STACK/ARCHITECTURE/CONVENTIONS | Korrekt umgesetzt |
| .claudeignore | Vollständig, build artifacts ausgeschlossen |
| Read(dist/**) deny in settings.json | Verhindert unbeabsichtigte build reads |
| MAX_MCP_OUTPUT_TOKENS: 10000 | Begrenzt MCP-Output |
| BASH_MAX_OUTPUT_LENGTH: 20000 | Begrenzt Bash-Output |
| prep-scripts für build/commit/test/lint | Komprimieren Output vor Claude-Analyse |
| memory-recall max 500 Tokens | Guard korrekt gesetzt |

---

## Aufwand-Impact-Matrix

| # | Maßnahme | Aufwand | Token-Einsparung | Priorität |
|---|----------|---------|------------------|-----------|
| P1 | config-changes.log rotieren | 5 Min | ~47.000 (Wachstum stoppen) | Sofort |
| P2 | agent-browser skill.md kürzen | 15 Min | ~4.500/Session | Hoch |
| P3 | YAML-Frontmatter für 3 context-Dateien | 10 Min | ~300/SessionStart | Mittel |
| P4 | token-optimizer skill.md kürzen | 20 Min | ~2.000/Nutzung | Mittel |
| P5 | tool-failures.log rotieren | 5 Min | Wachstum stoppen | Niedrig |

---

## Quick-Win-Reihenfolge

1. **P1** — 5 Minuten, stoppt unkontrolliertes Log-Wachstum
2. **P2** — 15 Minuten, größte Einsparung bei aktiver Nutzung
3. **P3** — 10 Minuten, kostet fast nichts und verbessert jeden SessionStart
