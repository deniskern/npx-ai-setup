# Token Optimizer — Eval-2 Output

Aufgabe: "Zeig mir eine Token-Optimierungs-Analyse für dieses Projekt — ich will wissen wo ich am meisten rausholen kann ohne viel Zeit zu investieren."

---

```
╔══════════════════════════════════════════════════════╗
║          TOKEN OPTIMIZER — npx-ai-setup              ║
╚══════════════════════════════════════════════════════╝

DEIN SETUP (diese Session)
Overhead: ~4.275 Tokens/Nachricht (ohne Skills Menü)
Probleme: 4, größter: Skill Descriptions + Rules ohne paths:

DEINE TEMPLATES (was Nutzer bekommen)
Installations-Footprint: ~5.325 Tokens/Nachricht
Kritische Probleme: 3
```

---

## SETUP-AUDIT

### Baseline Tokens/Nachricht (eigenes Projekt)

| Komponente | Zeilen | ~Tokens | Status |
|------------|--------|---------|--------|
| CLAUDE.md (Projektebene) | 105 | ~1.575 | OK |
| Rules (8 Dateien, 7 ohne paths:) | 186 | ~930 | Problem |
| Skills Menü (14 Skills) | — | ~1.400 | Groß |
| .agents/context/ L0 (8 Dateien, 472 Zeilen) | 472 | ~1.770 | Groß |

**Gesamt: ~5.675 Tokens/Nachricht**

### Setup-Probleme nach Priorität

| Problem | Tokens-Waste | Aufwand | Fix |
|---------|-------------|---------|-----|
| 7 Rules ohne paths: laden IMMER | ~790 | Klein | paths: Frontmatter |
| 4 verbose Skill-Descriptions (context-load 581, explore 600, release 616, spec-work-all 513 Zeichen) | ~200 | Klein | Kürzen auf ≤200 Zeichen |
| .agents/context/ L0: 472 Zeilen auto-load | ~700 | Mittel | Nur ARCHITECTURE+STACK auto-laden |

**Geschätzte Setup-Einsparung: ~900 Tokens/Nachricht (-16%)**

---

## TEMPLATE-AUDIT

### Installations-Footprint (was Nutzer nach Installation laden)

| Komponente | Größe | ~Tokens/Nachricht |
|------------|-------|-------------------|
| templates/CLAUDE.md | 123 Zeilen | ~1.845 |
| Rules (10 Dateien, 9 ohne paths:, 275 Zeilen) | 275 Zeilen | ~1.380 |
| Skills Menü (21 SKILL.md, 28 Ordner) | 21 Skills | ~2.100 |

**Gesamt: ~5.325 Tokens/Nachricht für Nutzer**

> Hinweis: 28 Skill-Ordner vorhanden, aber nur 21 SKILL.md-Dateien — drizzle, pinia, tailwind, tanstack, vitest sind leere Stubs ohne SKILL.md.

### Kritische Template-Probleme

| Problem | Impact | Fix |
|---------|--------|-----|
| 9 von 10 Rules ohne paths: (alle außer testing.md) | ~1.150 Tokens verschwendet | paths: hinzufügen |
| 9 Skill-Descriptions weit über 200 Zeichen (context-load 581, explore 600, release 616, spec-board 520, spec-create 497, spec-work 444, spec-work-all 513, spec-review 457, spec-validate 469) | ~600 Tokens/Nachricht | Kürzen |
| 5 leere Skill-Stubs ohne SKILL.md (drizzle, pinia, tailwind, tanstack, vitest) | Tech Debt + Verwirrung | Entfernen oder SKILL.md anlegen |
| 11 Shopify/Shopware Skills immer installiert, auch in Vue/React-Projekten | ~1.100 Tokens für Nicht-Shopify-Nutzer | Stack-Detection im Installer |

### Verbose Skill Descriptions (>200 Zeichen) — Vorschläge

| Skill | Ist | Vorschlag |
|-------|-----|-----------|
| explore | 600 | "Read-only thinking partner before spec. Triggers: /explore, 'think through', 'tradeoffs', 'brainstorm'." |
| context-load | 581 | "Load project context on demand — STACK.md, ARCHITECTURE.md, CONVENTIONS.md. Triggers: /context-load, 'load architecture'." |
| release | 616 | "Coordinate full release: version bump, CHANGELOG, docs, Slack. Triggers: 'release', 'ship', 'publish', 'v2.0.0'." |
| spec-board | 520 | "Overview of all specs as Kanban board. Triggers: /spec-board, 'show specs', 'spec overview'." |
| spec-create | 497 | "Create a new spec before implementing. Triggers: /spec, 'create a spec for X', 'plan X as a spec'." |
| spec-work | 444 | "Execute a single spec step by step. Triggers: /spec-work NNN, 'work on spec NNN'." |
| spec-work-all | 513 | "Execute all draft specs in parallel worktrees. Triggers: /spec-work-all, 'run all specs', 'batch implement'." |
| spec-review | 457 | "Review spec AFTER implementation. Triggers: /spec-review NNN, 'did we complete spec NNN'." |
| spec-validate | 469 | "Validate spec BEFORE implementation. Triggers: /spec-validate NNN, 'is spec NNN ready'." |

### Nicht-gescopte Template-Rules

| Datei | Lines | paths: | Sinnvoller Scope |
|-------|-------|--------|-----------------|
| typescript.md | 40 | Nein | `**/*.ts`, `**/*.tsx` |
| testing.md | 37 | Ja | OK |
| agents.md | 35 | Nein | Überall sinnvoll — lassen |
| general.md | 38 | Nein | Überall sinnvoll — lassen |
| git.md | 23 | Nein | Überall sinnvoll — lassen |
| quality-*.md | 18–20 | Nein | Überall sinnvoll — lassen |

**Geschätzte Nutzer-Einsparung wenn behoben: ~800 Tokens/Nachricht**

---

## QUICK WINS (ROI: Einsparung vs. Aufwand)

```
→ [A] Skill Descriptions kürzen (9 Skills, templates/skills/*/SKILL.md):
     spart ~600 Tokens/Nachricht für JEDEN Nutzer
     Aufwand: 15 Minuten
     Impact: HOCH (trifft alle installierten Projekte)

→ [B] typescript.md mit paths: versehen (templates + setup):
     spart ~200 Tokens wenn kein TS bearbeitet wird
     Aufwand: 2 Minuten
     Impact: Mittel

→ [C] 5 leere Skill-Stubs entfernen (drizzle, pinia, tailwind, tanstack, vitest):
     Sauberkeit + korrekte Zählangaben im README
     Aufwand: 5 Minuten
     Impact: Mittel (Tech Debt)

→ [D] Setup-Rules mit paths: versehen (7 Dateien):
     spart ~400 Tokens/Nachricht im eigenen Projekt
     Aufwand: 20 Minuten
     Impact: Mittel
```

## GESAMTPOTENZIAL

```
  Setup:     -900 Tokens/Nachricht (-16%)
  Templates: -800 Tokens/Nachricht für Nutzer (-15%)

  Quick-Win A+B allein: ~800 Tokens/Nachricht für Nutzer
  Zeitaufwand für A+B: < 20 Minuten
```

---

Was soll ich angehen?
  1. Setup optimieren (eigene Session — rules + descriptions)
  2. Templates verschlanken (Nutzer-Impact — skills + rules)
  3. Alles in einem Durchgang
  4. Nur Bericht, kein Auto-Fix
