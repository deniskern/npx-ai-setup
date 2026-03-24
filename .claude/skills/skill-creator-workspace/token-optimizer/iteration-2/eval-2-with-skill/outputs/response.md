# Token Optimizer — npx-ai-setup
## Eval: Iteration 2, Eval-2-With-Skill (ROI-fokussiert)

```
╔══════════════════════════════════════════════════════╗
║     TOKEN OPTIMIZER — Quick-Win-Analyse              ║
╚══════════════════════════════════════════════════════╝

FILE-RISIKO (.claudeignore-Lücken) ← größter Hebel
→ .claude/config-changes.log: ~47.000 Tokens Risiko | 1 Min | ROI: ★★★★★
→ templates/: ~177.000 Tokens Risiko | 1 Min | ROI: ★★★★★
→ specs/: ~213.000 Tokens Risiko | 1 Min | ROI: ★★★★★

SETUP (Overhead diese Session): ~6.515 Tokens/Nachricht
→ 7 Rules ohne paths: scopen: ~2.790 Tokens/Nachricht sparen | 15 Min | ROI: ★★★★

TEMPLATES (Nutzer-Impact):
→ 11 verbose Skill-Descriptions kürzen: ~800 Tokens/Nachricht für ALLE Nutzer | 15 Min | ROI: ★★★★
→ typescript.md mit paths: versehen: ~480 Tokens in Non-TS-Projekten | 5 Min | ROI: ★★★★
→ 5 leere Stubs entfernen: Menü-Integrität | 5 Min | ROI: ★★★

TOP-3 QUICK WINS (max. 30 Min gesamt)

  #1 — .claudeignore ergänzen (3 Min, ~437.000 Tokens Risiko entschärft)
  Füge zu .claudeignore hinzu:
    .claude/*.log
    templates/
    specs/
    CHANGELOG.md

  #2 — Rules mit paths: scopen (15 Min, ~2.790 Tokens/Nachricht)
  typescript.md → paths: ["**/*.ts","**/*.tsx"]
  Weitere 6 rules auf paths: prüfen und scopen

  #3 — Skill-Descriptions kürzen (15 Min, ~800 Tokens/Nachricht für Nutzer)
  11 descriptions >200 Zeichen kürzen: release, explore, context-load,
  spec-work-all, spec-board, spec-create, spec-work, spec-validate,
  spec-review, orchestrate, shopify-new-block

GESAMTEINSPARUNG (bei Umsetzung aller 3 Quick Wins)
  Einmalig: ~437.000 Tokens Risiko entschärft
  Pro Session: -~3.590 Tokens/Nachricht (-35%)
  Für Nutzer: -~1.280 Tokens/Nachricht nach Installation

Was soll ich angehen?
  1. Quick Win #1 (.claudeignore) ← jetzt, 3 Min
  2. Quick Win #2 + #3 (Rules + Descriptions) ← 30 Min
  3. Alle drei auf einmal
  4. Nur Bericht, kein Auto-Fix
```

---

## Rohdaten

**Baseline:** ~6.515 Tokens/Nachricht (diese Session)

**.claudeignore-Lücken:**
- `.claude/config-changes.log` — 47k Tokens
- `templates/` — 177k Tokens (einmalig)
- `specs/` — 213k Tokens (einmalig)
- `CHANGELOG.md` — 8k Tokens

**Große Skill-Dateien:**
- `gh-cli/references/full.md` — 40 KB / ~10.103 Tokens
- `agent-browser/SKILL.md` — 27 KB / ~6.666 Tokens

**Template-Footprint für Nutzer:**
- Installations-Footprint: ~6.482 Tokens/Nachricht
- 11 verbose Descriptions (>200 Zeichen)
- 5 leere Stubs
- 7 Rules ohne paths:
