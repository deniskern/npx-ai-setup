# Token Optimizer — npx-ai-setup
## Eval: Iteration 2, Eval-0-With-Skill

```
╔══════════════════════════════════════════════════════╗
║          TOKEN OPTIMIZER — npx-ai-setup              ║
╚══════════════════════════════════════════════════════╝

FILE-RISIKO (.claudeignore-Lücken) ← höchster ROI
→ .claude/config-changes.log: ~47.000 Tokens Risiko | Fix: 1 Zeile in .claudeignore | Aufwand: 1 Min
→ templates/: ~177.000 Tokens Risiko (einmalig) | Fix: 1 Zeile in .claudeignore | Aufwand: 1 Min
→ CHANGELOG.md: ~7.980 Tokens Risiko | Fix: In .claudeignore oder archivieren | Aufwand: 2 Min
→ .claude/tool-failures.log: ~4.297 Tokens Risiko | Fix: 1 Zeile in .claudeignore | Aufwand: 1 Min
→ specs/: ~213.000 Tokens Risiko (einmalig) | Fix: 1 Zeile in .claudeignore | Aufwand: 1 Min

GROSSE SKILL-DATEIEN (laden zuviel beim Aufruf)
→ .claude/skills/gh-cli/references/full.md: ~10.103 Tokens | Fix: Aufteilen nach Thema
→ .claude/skills/agent-browser/SKILL.md: ~6.666 Tokens | Fix: Details in references/ auslagern
→ .claude/skills/release/SKILL.md: ~2.345 Tokens | Grenzfall, OK wenn Release-Workflow aktiv

DEIN SETUP (Overhead, diese Session)
Overhead: ~6.515 Tokens/Nachricht
Probleme: 2 — größter: 7 Rules ohne paths: (~2.790 Tokens/Nachricht unnötig)

DEINE TEMPLATES (was Nutzer bekommen)
Installations-Footprint: ~6.482 Tokens/Nachricht
Kritische Probleme: 4

  Detail: Nutzer-Footprint aufgeschlüsselt
  ├── CLAUDE.md: 123 Zeilen → ~1.476 Tokens/Nachricht
  ├── Rules (7 ohne paths:): 238 Zeilen → ~2.790 Tokens/Nachricht
  │   Davon typescript.md: 40 Zeilen — SOLLTE paths: ["**/*.ts","**/*.tsx"] bekommen
  ├── Skills-Menü (21 echte Skills): 6.681 Zeichen → ~1.670 Tokens/Nachricht
  │   11 descriptions sind >200 Zeichen — kostet ~800 extra Tokens/Nachricht
  └── 5 leere Stubs (drizzle, pinia, tailwind, tanstack, vitest): Menü zeigt kaputte Skills

QUICK WINS nach ROI (Einsparung ÷ Aufwand)
1. → .claudeignore: .claude/*.log + specs/ ergänzen: ~236.000 Tokens einmalig | 3 Min
2. → templates/ in .claudeignore: ~177k Tokens Risiko entschärft | 1 Min
3. → 11 verbose descriptions auf ≤200 Zeichen kürzen: ~800 Tokens/Nachricht für ALLE Nutzer | 15 Min
4. → typescript.md mit paths: versehen: ~480 Tokens/Nachricht in Non-TS-Projekten | 5 Min
5. → 5 leere Skill-Stubs entfernen: Menü-Integrität | 5 Min

GESAMTPOTENZIAL
  File-Risiko: -~236.000+ Tokens einmalig entschärft
  Setup:       -~2.790 Tokens/Nachricht durch Rules-Scoping
  Templates:   -~1.280 Tokens/Nachricht für Nutzer (-20%)

Was soll ich angehen?
  1. File-Risiko beheben (.claudeignore + große Dateien) ← empfohlen zuerst
  2. Setup optimieren (CLAUDE.md, Rules, Skills)
  3. Templates verschlanken (Nutzer-Impact)
  4. Alles in einem Durchgang
  5. Nur Bericht, kein Auto-Fix
```

---

## Rohdaten

### File-Risiko (Agent A)

**.claudeignore-Lücken:**
- `.claude/config-changes.log` — 184 KB / ~47.000 Tokens — NICHT ignoriert
- `.claude/tool-failures.log` — 17 KB / ~4.297 Tokens — NICHT ignoriert
- `templates/` — 708 KB — NICHT ignoriert
- `CHANGELOG.md` — 31 KB / ~7.980 Tokens — NICHT ignoriert
- `specs/` — 852 KB — NICHT ignoriert

**Große Skill-Dateien (>10KB):**
- `.claude/skills/gh-cli/references/full.md` — 40 KB / ~10.103 Tokens
- `.claude/skills/agent-browser/SKILL.md` — 27 KB / ~6.666 Tokens
- `.claude/skills/token-optimizer/SKILL.md` — 12 KB / ~2.905 Tokens (OK, nötig)

**Setup Overhead:**
- CLAUDE.md: 105 Zeilen / ~1.575 Tokens
- Rules: 7 ohne paths: / ~2.790 Tokens/Nachricht
- Skills: 16 / ~400 Tokens
- .agents/context/: ~1.750 Tokens

### Template-Qualität (Agent B)

**Installations-Footprint: ~6.482 Tokens/Nachricht**

**Leere Stubs:** drizzle, pinia, tailwind, tanstack, vitest

**Verbose Descriptions (>200 Zeichen):** release (619), explore (603), context-load (584), spec-work-all (514), spec-board (523), spec-create (498), spec-work (445), spec-validate (472), spec-review (460), orchestrate (244), shopify-new-block (208)
