# Template Quality Audit

## Installations-Footprint (was Nutzer nach Installation laden)

| Komponente | Größe | ~Tokens/Nachricht |
|------------|-------|-------------------|
| CLAUDE.md Template | 123 Zeilen | ~1476 |
| Rules (immer geladen, 9 von 10) | 237 Zeilen | ~2844 |
| Rules (scoped: testing.md) | 37 Zeilen | 0 |
| Skills Menü (26 Skills) | — | ~2600 |
**Gesamt: ~6920 Tokens/Nachricht für Nutzer**

## Kritische Probleme

| Problem | Impact | Fix |
|---------|--------|-----|
| 26 Skills immer im Menü — 10+ Shopify-/Shopware-Skills für nicht-Shopify-Nutzer irrelevant | ~1000 Tokens Waste | Selektive Installation via Stack-Detection |
| typescript.md ohne paths: Frontmatter | ~480 Tokens bei JEDER Nachricht, auch in reinen JS-Projekten | `paths: ["**/*.ts", "**/*.tsx"]` hinzufügen |
| code-review-reception.md (28 Zeilen) — im Projektsetup bereits gelöscht, Template noch vorhanden | ~336 Tokens | Template-Datei prüfen und bereinigen |
| templates/CLAUDE.md hat "Skills Discovery" Section (117-122) die Nutzer anleitet Skills zu suchen | ~60 Zeilen Overhead | Skills-Menü ist ohnehin automatisch — Section unnötig |

## Verbose Skill Descriptions (>200 Zeichen)

| Skill | Länge | Vorschlag |
|-------|-------|-----------|
| context-load | 581 Zeichen | "Load full project context on demand — STACK, ARCHITECTURE, CONVENTIONS. Triggers: /context-load, load context for X." |
| explore | 600 Zeichen | "Read-only thinking partner before committing to a spec. Triggers: /explore, help me think through, brainstorm, tradeoffs." |
| release | 616 Zeichen | "Full release workflow: version bump, CHANGELOG, docs sync, Slack. Triggers: release, ship, publish, /release, v2.0.0." |
| spec-board | 520 Zeichen | "Overview of all specs as Kanban board. Triggers: /spec-board, show specs, spec overview, what's in progress." |
| spec-create | 497 Zeichen | "Create a new spec. Triggers: /spec ..., create a spec for X, plan X as a spec, write acceptance criteria." |
| spec-review | 457 Zeichen | "Review completed spec against acceptance criteria (AFTER implementation). Triggers: /spec-review NNN, did we complete spec NNN." |
| spec-validate | 469 Zeichen | "Validate draft spec quality BEFORE implementation begins. Triggers: /spec-validate NNN, is spec NNN ready to implement." |
| spec-work | 444 Zeichen | "Execute a single spec step by step. Triggers: /spec-work NNN, work on spec NNN, implement spec NNN." |
| spec-work-all | 513 Zeichen | "Execute all draft specs in parallel via Git worktrees. Triggers: /spec-work-all, run all specs, batch implement." |
| shopify-new-block | 207 Zeichen | "Scaffold a new Shopify section block with Liquid template, schema, and translation key stubs." |

## Nicht-gescopte Rules

| Datei | Lines | paths: vorhanden? | Problem |
|-------|-------|-------------------|---------|
| agents.md | 35 | Nein | Lädt immer, auch ohne Agent-Delegation |
| general.md | 38 | Nein | Lädt immer — OK (generisch) |
| git.md | 23 | Nein | Könnte auf git-sensitive Operationen beschränkt werden |
| quality-general.md | 18 | Nein | Lädt immer — OK (generisch) |
| quality-maintainability.md | 20 | Nein | Lädt immer — OK (generisch) |
| quality-performance.md | 19 | Nein | Lädt immer — OK (generisch) |
| quality-security.md | 17 | Nein | Lädt immer — OK (generisch) |
| **typescript.md** | **40** | **Nein** | **Kritisch: Lädt in JEDEM Projekt, auch reinen JS/Liquid-Projekten** |
| testing.md | 37 | Ja ✓ | Korrekt gescopet auf *.test.*, *.spec.* |
| code-review-reception.md | 28 | Nein | Im Projekt-Setup bereits gelöscht — Template veraltet? |

## Domain-spezifische Skills (nicht für alle Nutzer relevant)

**Shopify-spezifisch (9 Skills):** shopify-app-dev, shopify-checkout, shopify-cli-tools, shopify-functions, shopify-graphql-api, shopify-hydrogen, shopify-liquid, shopify-new-block, shopify-new-section, shopify-theme-dev
**Shopware-spezifisch (1 Skill):** shopware6-best-practices
**Framework-spezifisch (4 Skills):** drizzle, pinia, tailwind, tanstack
**Test-spezifisch (1 Skill):** vitest

→ 15 von 26 Skills sind domain-spezifisch. Ohne Stack-Detection bekommen ALLE Nutzer alle 26 Skills (~2600 Tokens). Mit selektiver Installation: Core-Nutzer (~11 Skills) zahlen nur ~1100 Tokens.

## Geschätzte Nutzer-Einsparung wenn behoben: ~2100-2500 Tokens/Nachricht

- Skill-Descriptions kürzen (alle >200 Zeichen): -~500 Tokens
- typescript.md mit paths: versehen: -480 Tokens
- Domain-Skills selektiv installieren (z.B. kein Shopify-Stack): -~1000 Tokens
- code-review-reception.md aus Templates entfernen: -336 Tokens
