# Token Optimizer — Evaluierungs-Run Iteration 2

```
╔══════════════════════════════════════════════════════╗
║          TOKEN OPTIMIZER — npx-ai-setup              ║
╚══════════════════════════════════════════════════════╝

FILE-RISIKO (.claudeignore-Lücken) ← höchster ROI
→ .claude/config-changes.log: ~47.300 Tokens Risiko | Fix: 1 Zeile in .claudeignore | Aufwand: 1 Min
→ .claude/tool-failures.log:   ~4.350 Tokens Risiko | Fix: .claude/*.log in .claudeignore | Aufwand: 1 Min
→ CHANGELOG.md:                ~7.980 Tokens Risiko | Fix: 1 Zeile in .claudeignore | Aufwand: 1 Min
→ specs/ (177 Dateien, 852KB): potenziell >50k wenn mitgezogen | Fix: specs/ in .claudeignore | Aufwand: 1 Min

GROSSE SKILL-DATEIEN (laden zuviel beim Aufruf)
→ gh-cli/references/full.md:  ~10.103 Tokens | nur bei explizitem Aufruf — akzeptabel
→ agent-browser/SKILL.md:     ~6.666 Tokens  | Body zu lang — splitten empfohlen
→ token-optimizer/SKILL.md:   ~2.905 Tokens  | OK für Detailskill

DEIN SETUP (Overhead diese Session)
Overhead: ~6.500–7.900 Tokens/Nachricht
Probleme: 2 kritisch
  → 13/14 Skill Descriptions >200 Zeichen (+800–1.400 Tokens/Nachricht verschwendet)
  → 7/8 Rules ohne paths: Frontmatter (lädt auch irrelevante Rules immer)

DEINE TEMPLATES (was Nutzer bekommen)
Installations-Footprint: ~8.000–10.000 Tokens/Nachricht für Nutzer
Kritische Probleme: 3
  → 11/21 Skill Descriptions >200 Zeichen (+800–1.500 Tokens/Nachricht × alle Nutzer)
  → 5 leere Skill-Stubs (drizzle, pinia, tailwind, tanstack, vitest)
  → typescript.md ohne paths: (lädt in Non-TypeScript-Projekten)

QUICK WINS nach ROI (Einsparung ÷ Aufwand)
1. → .claude/*.log in .claudeignore:        ~52.000 Tokens einmalig entschärft | 2 Min
2. → CHANGELOG.md in .claudeignore:          ~7.980 Tokens einmalig             | 1 Min
3. → Skill Descriptions kürzen (Templates): ~1.200 Tokens/Nachricht × Nutzer   | 30 Min
4. → Skill Descriptions kürzen (Setup):       ~800 Tokens/Nachricht             | 20 Min
5. → typescript.md mit paths: versehen:       ~600 Tokens/Nachricht in Non-TS  | 5 Min
6. → 5 leere Stubs bereinigen:               Menü-Cleanliness                   | 10 Min
7. → agent-browser/SKILL.md splitten:       ~4.000 Tokens beim Aufruf          | 45 Min

GESAMTPOTENZIAL
  File-Risiko: -~60.000 Tokens einmalig entschärft
  Setup:       -~800 Tokens/Nachricht (-10–12%)
  Templates:   -~1.800 Tokens/Nachricht für Nutzer (-18–22%)

Was soll ich angehen?
  1. File-Risiko beheben (.claudeignore + Log-Dateien) ← empfohlen zuerst
  2. Setup optimieren (Skill Descriptions kürzen, Rules scopen)
  3. Templates verschlanken (Descriptions + Stubs + typescript.md scope)
  4. Alles in einem Durchgang
  5. Nur Bericht, kein Auto-Fix
```
