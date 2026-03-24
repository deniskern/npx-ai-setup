╔══════════════════════════════════════════════════════╗
║          TOKEN OPTIMIZER — npx-ai-setup              ║
╚══════════════════════════════════════════════════════╝

DEIN SETUP (diese Session)
Overhead: ~4948 Tokens/Nachricht
Probleme: 4, größter: Skills-Menü (14 Skills, viele mit >400-Zeichen-Descriptions)

DEINE TEMPLATES (was Nutzer bekommen)
Installations-Footprint: ~6920 Tokens/Nachricht
Kritische Probleme: 4

---

SETUP-DETAILS

| Komponente            | ~Tokens | Status      |
|-----------------------|---------|-------------|
| CLAUDE.md (105 Zeilen)| ~1260   | OK          |
| Rules (7 immer geladen, 149 Zeilen) | ~1788 | Groß   |
| Skills Menü (14 Skills) | ~1400 | Groß       |
| .agents/context/ (L0 via Hook) | ~400 | OK (gut optimiert) |
| Hooks/Settings        | ~100    | OK          |
**Gesamt: ~4948 Tokens/Nachricht**

Positiv: context-loader Hook liest nur YAML-Frontmatter-Abstracts (~400 Tokens)
statt volller 472-Zeilen-Dateien (~5664 Tokens). Das ist bereits gut gelöst.

---

TEMPLATE-DETAILS (was Nutzer nach Installation laden)

| Komponente              | ~Tokens | Status     |
|-------------------------|---------|------------|
| CLAUDE.md Template (123 Zeilen) | ~1476 | OK    |
| Rules (9 von 10 immer geladen) | ~2844 | Groß  |
| Skills Menü (26 Skills) | ~2600   | Kritisch   |
**Gesamt: ~6920 Tokens/Nachricht für Nutzer**

---

QUICK WINS

→ [Skill-Descriptions kürzen]: spart ~500 Tokens  (Setup + Templates)
   10 von 14 Projekt-Skills und 10 von 26 Template-Skills haben >400 Zeichen.
   Ziel: ≤200 Zeichen (~25 Tokens statt ~50-75 pro Skill).
   Beispiel explore: 600 Zeichen → "Read-only thinking partner before committing
   to a spec. Triggers: /explore, help me think through, brainstorm, tradeoffs."

→ [typescript.md mit paths: versehen]: spart ~480 Tokens  (Templates, alle Nutzer)
   Lädt aktuell bei JEDER Nachricht in JEDEM Nutzerprojekt — auch in reinen
   Liquid/JS/PHP-Projekten ohne TypeScript.
   Fix: paths: ["**/*.ts", "**/*.tsx", "tsconfig.json"] hinzufügen.

→ [Domain-Skills selektiv installieren]: spart ~1000 Tokens  (Templates, nicht-Shopify-Nutzer)
   15 von 26 Skills sind domain-spezifisch (10x Shopify, 1x Shopware, 4x Framework).
   Ohne Stack-Detection laden ALLE Nutzer alle 26 Skills (~2600 Tokens).
   Mit selektiver Installation: Core-Nutzer zahlen nur ~1100 Tokens für Skills.

→ [code-review-reception.md aus Templates entfernen]: spart ~336 Tokens  (Templates)
   Im Projekt-Setup bereits gelöscht (.claude/rules/), aber templates/claude/rules/
   enthält die Datei noch (28 Zeilen). Templates und Projekt laufen auseinander.

→ [Leere CLAUDE.md Sections]: spart ~120 Tokens  (Setup)
   "## Commands" und "## Critical Rules" sind Placeholder-Sections ohne Inhalt
   (nur HTML-Kommentare). Diese können entfernt oder zusammengeführt werden.

---

GESAMTPOTENZIAL
  Setup:     -~620 Tokens/Nachricht (-12.5%)
             (Skills Descriptions + leere Sections)
  Templates: -~2316 Tokens/Nachricht für Nutzer (-33%)
             (Descriptions + typescript.md scope + domain-Skills + code-review-rule)

---

AUDIT-DATEIEN
  → outputs/audit/setup.md    — vollständiger Setup-Overhead-Report
  → outputs/audit/templates.md — vollständiger Template-Quality-Report

---

Was soll ich angehen?
  1. Setup optimieren (Skills Descriptions + leere Sections)
  2. Templates verschlanken (typescript.md scope + code-review-rule entfernen + Descriptions)
  3. Alles in einem Durchgang
  4. Nur Bericht, kein Auto-Fix
