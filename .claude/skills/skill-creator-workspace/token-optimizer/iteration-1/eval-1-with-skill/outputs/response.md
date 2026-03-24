# Token Optimizer — Audit Response

## Kontext

Evaluierungs-Run des token-optimizer Skills, Iteration 1, Eval 1.
Aufgabe: "Schau mal ob die Templates die wir ausliefern zu groß sind."

---

## Audit-Output (Phase 2: Findings)

```
╔══════════════════════════════════════════════════════╗
║          TOKEN OPTIMIZER — npx-ai-setup              ║
╚══════════════════════════════════════════════════════╝

DEIN SETUP (diese Session)
Overhead: ~5,610 Tokens/Nachricht
Probleme: 2, größter: Skills-Menü (14 lokale Skills, ~1,400 Tokens)
Hinweis: .agents/context/ injiziert ~400 Tokens via SessionStart

DEINE TEMPLATES (was Nutzer bekommen)
Installations-Footprint: ~9,755 Tokens/Nachricht
Kritische Probleme: 5

Details:
  → CLAUDE.md Template:  123 Zeilen  ~1,845 Tokens
  → Rules (9 unscoped):  238 Zeilen  ~3,570 Tokens (immer geladen)
  → Skills-Menü (26):    26 Skills   ~4,340 Tokens

QUICK WINS
→ 11 Skill Descriptions kürzen (>200 Zeichen → ≤200):   spart ~1,100 Tokens (alle Nutzer)
→ Shopify-Skills optional installieren (11 Skills):       spart ~2,200 Tokens (Non-Shopify)
→ typescript.md mit paths: scope versehen:                spart ~600 Tokens (Non-TS Projekte)
→ code-review-reception.md scopen:                        spart ~420 Tokens

KRITISCHER FUND
5 Skills ohne SKILL.md vorhanden (drizzle, pinia, tailwind, tanstack, vitest)
→ Leere Skill-Verzeichnisse — entweder bereinigen oder SKILL.md ergänzen

GESAMTPOTENZIAL
  Setup:     -~600 Tokens/Nachricht (-~11%)
  Templates: -~4,320 Tokens/Nachricht für Nutzer (-~44%)

Größter Hebel: Shopify-Skills optional machen + Descriptions kürzen.
Trifft ALLE Nutzer — auch die, die kein Shopify nutzen.

Was soll ich angehen?
  1. Setup optimieren
  2. Templates verschlanken
  3. Alles in einem Durchgang
  4. Nur Bericht, kein Auto-Fix
```

---

## Skill-Evaluation Notes (für skill-creator)

### Was gut funktioniert hat
- Phase 0 (Baseline) graceful degradiert: measure.py fehlend, weitergemacht
- Beide Audit-Perspektiven (Setup + Templates) liefern unterschiedliche, wertvolle Findings
- Token-Schätzungsformel (15 Tokens/Zeile Prosa, 4 chars/Token für Descriptions) realistisch
- Skill Description Längen-Check deckt echtes Problem auf: 11 von 21 Skills verbose

### Was schwierig war
- Description-Extraktion via grep/awk schlägt auf macOS fehl (BSD awk Syntax)
- python3 -c war zuverlässiger für Frontmatter-Parsing
- 5 Skills ohne SKILL.md (drizzle etc.) nicht im SKILL.md-Prompt antizipiert

### Prompt-Verbesserungsvorschläge für SKILL.md
1. Python-Fallback für Description-Extraktion ergänzen (BSD awk Inkompatibilität)
2. Leere Skill-Verzeichnisse ohne SKILL.md als eigene Check-Kategorie ergänzen
3. "Skills werden global installiert" explizit hervorheben — hat großen Impact-Multiplikator
