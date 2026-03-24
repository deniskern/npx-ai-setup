# Template-Größen-Analyse: npx-ai-setup

## Zusammenfassung

**Gesamtgröße templates/:** ~465 KB (464.791 Bytes, 124 Dateien)

Das klingt viel — ist es aber nur teilweise. Die entscheidende Frage ist: Was landet wirklich beim Nutzer?

---

## Was tatsächlich installiert wird

Das Setup unterscheidet drei Kategorien:

### 1. Immer installiert (Kernstruktur)
Diese Templates werden bei jedem `npx @onedot/ai-setup` kopiert:

| Kategorie        | Größe    | Dateien | Kommentar                             |
| ---------------- | -------- | ------- | ------------------------------------- |
| `CLAUDE.md`      | 6,2 KB   | 1       | Pflicht                               |
| `AGENTS.md`      | 2,9 KB   | 1       | Pflicht                               |
| `claude/rules/`  | ~8,0 KB  | 9       | Qualitäts- und Git-Regeln             |
| `claude/hooks/`  | ~23 KB   | 15      | Automation-Hooks                      |
| `claude/docs/`   | ~5,1 KB  | 2       | Docs                                  |
| `claude/settings.json` | 6,5 KB | 1  | Settings                              |
| `commands/`      | ~108 KB  | 28      | Slash-Commands — größter Brocken      |
| `scripts/`       | ~62 KB   | 16      | Prep-Skripte für Commands             |
| `agents/`        | ~39 KB   | 12      | Subagent-Templates                    |
| `specs/README.md` | 3,0 KB  | 2       | Spec-Workflow                         |
| `codex/`, `gemini/`, `github/` | ~3,2 KB | 4 | Minimal               |

**Kern-Install gesamt: ~266 KB**

### 2. Global Skills (aus Registry, nicht lokal)
run_skill_installation() installiert per `npx skills@latest add` nur 3 Skills aus dem Internet:
- agent-browser (Vercel Labs)
- find-skills (Vercel Labs)
- gh-cli (GitHub Awesome Copilot)

Diese kommen NICHT aus templates/skills/ — sondern von der Skills-Registry.

### 3. Shopify-Skills: NUR lokale Fallback-Templates
Die 10 Shopify-Skills (99 KB) werden NICHT automatisch installiert. install_local_skill_template() greift nur, wenn die Registry-Installation fehlschlägt und ein lokaler Template-Fallback existiert. Nutzer ohne Shopify-Kontext bekommen diese nie zu sehen.

---

## Größten Einzeldateien

| Datei                                  | Größe   | Immer installiert? |
| -------------------------------------- | ------- | ------------------ |
| skills/shopify-graphql-api/SKILL.md    | 14,1 KB | Nein (Fallback)    |
| skills/shopify-functions/SKILL.md      | 13,7 KB | Nein (Fallback)    |
| skills/shopify-liquid/SKILL.md         | 11,9 KB | Nein (Fallback)    |
| commands/spec-work.md                  | 11,3 KB | Ja                 |
| skills/shopify-hydrogen/SKILL.md       | 11,2 KB | Nein (Fallback)    |
| skills/shopify-app-dev/SKILL.md        | 11,1 KB | Nein (Fallback)    |
| claude/WORKFLOW-GUIDE.md               | 9,5 KB  | Ja                 |
| commands/spec.md                       | 9,3 KB  | Ja                 |

---

## Bewertung: Overhead-Problem?

### Wo kein Problem besteht
- Shopify-Skills (99 KB): Werden nie automatisch installiert. Kein Overhead für Nicht-Shopify-Nutzer.
- Spec-Skills: Werden nur aus der Registry gezogen, wenn Nutzer sie explizit haben wollen.

### Wo echtes Overhead-Potenzial besteht

commands/ mit 108 KB ist der größte immer-installierte Block. 28 Slash-Commands werden pauschal kopiert. Einige davon sind sehr spezifisch:

- spec-work.md (11,3 KB), spec-work-all.md (4,9 KB), spec-board.md (1,7 KB), spec-validate.md (6,0 KB), spec-review.md (5,6 KB) — 29,5 KB nur für Spec-Workflow — für Nutzer ohne Spec-Driven Development wertlos.
- research.md (7,7 KB), analyze.md (7,7 KB), discover.md (4,7 KB) — Heavy-Research-Commands, selten gebraucht.

scripts/ mit 62 KB sind Companion-Skripte zu Commands — ebenfalls pauschal installiert.

### Größte Commands nach Größe

| Command             | Größe   | Nutzer-Relevanz          |
| ------------------- | ------- | ------------------------ |
| spec-work.md        | 11,3 KB | Nur bei Spec-Workflow    |
| spec.md             | 9,3 KB  | Nur bei Spec-Workflow    |
| analyze.md          | 7,7 KB  | Gelegentlich             |
| research.md         | 7,7 KB  | Selten                   |
| review.md           | 5,8 KB  | Häufig                   |
| spec-validate.md    | 6,0 KB  | Nur bei Spec-Workflow    |
| spec-review.md      | 5,6 KB  | Nur bei Spec-Workflow    |

---

## Empfehlung

Kein Notfall, aber verbesserungswürdig. Die Struktur ist grundsätzlich richtig — Shopify-Skills sind korrekt als optionale Fallbacks implementiert.

**Konkrete Maßnahmen:**

1. Spec-Commands optional machen — spec*.md (5 Dateien, ~29 KB) und ihre scripts/spec-*.sh Companions nur installieren wenn Nutzer Spec-Workflow im Setup aktiviert. Spart ~35-40 KB für einfache Nutzer.

2. Research-Commands aufteilen — research.md, analyze.md, discover.md (~20 KB) sind Heavy-Commands. Könnten als opt-in Gruppe markiert werden.

3. WORKFLOW-GUIDE.md hinterfragen — 9,5 KB Dokumentation wird immer kopiert. Könnte durch einen Link zur Online-Doku ersetzt werden.

Erwartete Ersparnis bei Punkt 1+3: ~45 KB (von 266 KB Kern-Install), also ~17%.

Für reine Overhead-Sorge: Das sind Textdateien — 266 KB ist im Jahr 2026 kein reales Performance-Problem. Die eigentliche Frage ist ob ungenutzte Commands Nutzer verwirren oder Kontext verschwenden wenn Claude die Commands scannt.

---

Analyse-Datum: 2026-03-24
