# Brainstorm: everything-claude-code Adaptionen fuer npx-ai-setup

> **Source**: https://github.com/affaan-m/everything-claude-code
> **Erstellt**: 2026-03-22
> **Zweck**: Evaluierung welche Patterns aus ECC (Everything Claude Code) adaptierbar sind
> **Status**: complete

## Bestandsaufnahme

```
EXTERNAL (ECC):  28 agents, 59 commands, 116 skills, 12 language rule sets, 1 hook config
OURS:            11 agents, 22 commands, 0 skills (via plugins), 4 rule files, hooks via settings.json
```

## Bestandsvergleich: Was haben wir schon?

### Agents

| ECC Agent | Unser Equivalent | Status |
|-----------|-----------------|--------|
| planner | Plan mode (built-in) + spec system | ✅ Covered (besser — Spec-System ist strukturierter) |
| architect | code-architect.md | ✅ Covered |
| code-reviewer | code-reviewer.md | ⚠️ Partial — ECC hat confidence filtering + AI-generated code checks |
| security-reviewer | (fehlt) | ❌ Missing |
| build-error-resolver | build-validator.md | ⚠️ Partial — ECC ist aktiver Fixer, unserer nur Reporter |
| e2e-runner | verify-app.md | ⚠️ Partial — ECC hat Agent Browser + Playwright + Flaky-Handling |
| tdd-guide | (fehlt) | ❌ Missing |
| refactor-cleaner | (fehlt) | ❌ Missing |
| harness-optimizer | (fehlt — /doctor ist nah dran) | ⚠️ Partial |
| doc-updater | (fehlt) | ❌ Missing |
| docs-lookup | (fehlt — Context7 MCP) | ✅ Covered (anders geloest) |
| chief-of-staff | (irrelevant fuer unser Projekt) | ➖ N/A |
| loop-operator | (fehlt) | ❌ Missing |
| typescript-reviewer | (fehlt — code-reviewer ist generisch) | ⚠️ Partial |
| python-reviewer | (fehlt) | ❌ Missing (fuer Python-Projekte) |
| go/rust/java/etc reviewers | (fehlt) | ❌ Missing (irrelevant fuer DACH Web-Agency) |
| frontend-developer (ours) | (kein ECC equivalent) | ✅ Nur bei uns |
| staff-reviewer (ours) | (kein ECC equivalent) | ✅ Nur bei uns |
| perf-reviewer (ours) | (kein ECC equivalent) | ✅ Nur bei uns |
| project-auditor (ours) | (kein ECC equivalent) | ✅ Nur bei uns |
| liquid-linter (ours) | (kein ECC equivalent) | ✅ Nur bei uns (Shopify-spezifisch) |

### Commands

| ECC Command | Unser Equivalent | Status |
|-------------|-----------------|--------|
| /plan | /spec (create) | ✅ Covered (Spec-System ist maechtigere Alternative) |
| /tdd | /test | ⚠️ Partial — ECC erzwingt Red-Green-Refactor Zyklus |
| /code-review | /review | ✅ Covered |
| /build-fix | (fehlt — build-validator ist passiv) | ❌ Missing |
| /e2e | (fehlt) | ❌ Missing |
| /verify | /spec-review + verify-app Agent | ⚠️ Partial |
| /learn | /reflect | ⚠️ Partial — ECC speichert als Skills, wir als Rules/Memory |
| /skill-create | (fehlt) | ❌ Missing |
| /quality-gate | /scan (nur Security) | ⚠️ Partial |
| /checkpoint | commit als Checkpoint | ⚠️ Partial — ECC hat formales Checkpoint-System |
| /evolve | (fehlt) | ❌ Missing |
| /model-route | agents.md Rule (Model Routing Table) | ✅ Covered (als Rule statt Command) |
| /prompt-optimize | (fehlt) | ❌ Missing |
| /context-budget | token-optimizer Skill (Plugin) | ✅ Covered |
| /save-session | (fehlt — claude-mem MCP uebernimmt teilweise) | ⚠️ Partial |
| /harness-audit | /doctor | ⚠️ Partial |
| /eval | /evaluate | ✅ Covered |

### Architektur-Patterns

| ECC Pattern | Unser Equivalent | Status |
|-------------|-----------------|--------|
| Hooks via hooks.json + JS Scripts | Hooks via settings.json + Shell | ✅ Covered (anderer Ansatz) |
| Skills als .md Dateien | Skills als Plugins installiert | ✅ Covered (anderer Ansatz) |
| Language-spezifische Rules (12 Sprachen) | 4 generische Rule-Dateien | ⚠️ Partial |
| Instinct-Learning System | claude-mem MCP + /reflect | ⚠️ Partial |
| Cross-Platform (Cursor, Codex, OpenCode) | Nur Claude Code | ➖ N/A (bewusste Entscheidung) |
| Plugin-Marketplace Distribution | npx Distribution | ✅ Covered (anderer Ansatz) |
| CI Validation Scripts | (fehlt) | ❌ Missing |
| AGENTS.md (Root-Level Agent Registry) | agents.md Rule (Dispatch Table) | ✅ Covered |

## Kandidaten fuer Adaption

### 1. Security Reviewer Agent ❌ Missing — HOCH

**Was es tut**: Dedizierter Agent fuer OWASP Top 10, Secrets Detection, Dependency Audit.
**Unsere Luecke**: Kein dedizierter Security-Agent. /scan prueft nur Dependencies, keine Code-Patterns.
**ECC-Ansatz**: YAML-Frontmatter Agent mit strukturiertem OWASP-Checklist, Pattern-Table (hardcoded secrets, SQL injection, XSS), Common False Positives Section.
**Aufwand**: Klein — ein Agent-File + Trigger in agents.md
**Empfehlung**: Adaptieren, aber auf unseren Stack fokussieren (Shopify Liquid XSS, Nuxt/Vue reactivity leaks, Shell Injection in bin/ai-setup.sh)

### 2. Build-Fix Command ❌ Missing — MITTEL

**Was es tut**: Aktiver Build-Error-Fixer (nicht nur Reporter). Ein Fehler pro Schritt, Rebuild dazwischen.
**Unsere Luecke**: build-validator meldet nur pass/fail, fixt nichts.
**ECC-Ansatz**: Inkrementeller Fix-Loop: Fehler lesen → minimal fixen → rebuild → naechster Fehler.
**Aufwand**: Klein — ein Command-File
**Empfehlung**: Als `/build-fix` Command erstellen, delegiert an build-validator Agent mit erweitertem Fix-Auftrag

### 3. Confidence-Based Code Review (Verbesserung) ⚠️ Partial — MITTEL

**Was es tut**: ECC filtert Code-Review-Findings auf >80% Confidence, hat explizite AI-Generated-Code-Checks.
**Unsere Luecke**: Unser code-reviewer hat keine Confidence-Schwelle, kein spezielles AI-Code-Handling.
**Spezifische Zeilen aus ECC**:
- "Only flags issues >80% certain to be real problems"
- "AI-generated code focus: behavioral regressions, security assumptions, unnecessary complexity"
- "Check for stub code, placeholder implementations, TODO-marked incomplete code"
**Aufwand**: Klein — Ergaenzungen im bestehenden code-reviewer.md
**Empfehlung**: Diese 3 Patterns in unseren code-reviewer integrieren

### 4. TDD-Erzwingung (Verbesserung fuer /test) ⚠️ Partial — NIEDRIG

**Was es tut**: ECC erzwingt Red-Green-Refactor Zyklus: erst Test schreiben → scheitern lassen → implementieren.
**Unsere Luecke**: /test laeuft Tests und fixt Failures, erzwingt aber keinen TDD-Workflow.
**Aufwand**: Mittel — erfordert Workflow-Redesign von /test oder neuen /tdd Command
**Empfehlung**: Nicht adaptieren als Default. Optional als separater /tdd Command, aber niedrige Prioritaet — unser Team nutzt kein striktes TDD.

### 5. Checkpoint System ⚠️ Partial — NIEDRIG

**Was es tut**: Formale Checkpoints mit create/verify/list. Vergleich gegen frueheren Zustand.
**Unsere Luecke**: Wir nutzen Commits als informelle Checkpoints.
**Aufwand**: Mittel
**Empfehlung**: Nicht adaptieren — Commits + Spec-Steps decken das ab.

### 6. /learn + /evolve (Instinct-to-Skill Pipeline) ⚠️ Partial — MITTEL

**Was es tut**: Extrahiert Patterns aus Sessions → speichert als "Instincts" → clustert zu Skills/Commands.
**Unsere Luecke**: /reflect extrahiert Learnings, aber keine automatische Skill-Generierung.
**Aufwand**: Hoch — komplettes Subsystem
**Empfehlung**: Nicht adaptieren. claude-mem MCP + /reflect + manuelles Spec-System ist besser kontrollierbar. Die automatische Generierung von Skills birgt Qualitaetsrisiken.

### 7. CI Validation Scripts ❌ Missing — MITTEL

**Was es tut**: Node.js-Scripts die Agents, Commands, Rules, Skills gegen Schemata validieren.
**Unsere Luecke**: Keine automatische Validierung unserer Template-Dateien.
**Aufwand**: Mittel — Scripts + Schema-Definitionen
**Empfehlung**: Sinnvoll, aber als eigene Spec. Wuerde Template-Qualitaet sichern bei wachsender Anzahl.

### 8. E2E Command ❌ Missing — NIEDRIG

**Was es tut**: Dedizierter /e2e Command fuer Playwright-Tests mit Agent Browser Integration.
**Unsere Luecke**: Kein dedizierter E2E-Command (verify-app Agent kann es, aber kein direkter Trigger).
**Aufwand**: Klein
**Empfehlung**: Niedrige Prioritaet — Agent Browser ist bereits in unserer globalen Config. Bei Bedarf als Command erstellbar.

## Einzelne Saetze/Patterns zum Adaptieren

Auch aus "Covered" Items gibt es wertvolle Einzelzeilen:

1. **Aus code-reviewer.md**: "Check for stub code, placeholder implementations, TODO-marked incomplete code" — fehlt in unserem Reviewer. Wuerde AI-generierte Stubs fangen.

2. **Aus build-error-resolver.md**: "Minimal lines changed (< 5% of affected file)" — gute Success-Metrik, fehlt bei uns.

3. **Aus security-reviewer.md**: "Common False Positives" Section — reduziert Noise massiv. Unsere Agents haben keine False-Positive-Guidance.

4. **Aus e2e-runner.md**: "Quarantine flaky tests with `test.fixme(true, 'Flaky - Issue #123')`" — konkretes Pattern fuer Flaky-Test-Handling.

5. **Aus AGENTS.md**: "hooks over prompts for reliability" — Prinzip das wir bereits befolgen, aber nicht explizit dokumentiert haben.

6. **Aus verify.md**: Prueft Console-Logs und Git-Status als Teil der Verifikation — unser verify-app macht das nicht.

7. **Aus model-route.md**: Kategorisierung "mechanical tasks" → haiku — wir haben das in agents.md, aber als Rule statt als interaktiver Advisor.

## Architektur-Patterns

### Pattern 1: Agent Frontmatter (YAML)
ECC nutzt YAML-Frontmatter in Agent-Dateien: `name`, `description`, `tools`, `model`, `color`.
**Unser Ansatz**: Kein Frontmatter, alles im Markdown-Body.
**Bewertung**: ECC-Ansatz ist maschinenlesbarer (validierbar), aber Claude Code nutzt das Frontmatter-Format offiziell. Wir sollten migrieren.
**Token-Impact**: Minimal (5-10 Zeilen pro Agent).

### Pattern 2: "When NOT to Use" Section in Agents
ECC hat explizite "When NOT to Use" mit Verweis auf bessere Alternativen.
**Unser Ansatz**: Wir haben "Avoid If" — aequivalent.
**Bewertung**: ✅ Bereits abgedeckt.

### Pattern 3: Hook Recipes
ECC dokumentiert 5 konkrete Hook-Recipes (TODO warnings, file size limits, auto-formatting).
**Unser Ansatz**: Hooks in settings.json ohne Rezeptsammlung.
**Bewertung**: Eine Hook-Rezeptsammlung waere nuetzlich fuer Onboarding neuer Projekte.

### Pattern 4: Harness Audit Scoring
ECC hat ein numerisches Scoring-System fuer die Claude Code Config-Qualitaet.
**Unser Ansatz**: /doctor prueft Checks, aber ohne Score.
**Bewertung**: Score wuerde Gamification-Effekt haben, ist aber nicht kritisch.

## Gesamtranking nach Aufwand/Nutzen

| # | Item | Value | Aufwand | Empfehlung |
|---|------|-------|---------|------------|
| 1 | Security Reviewer Agent | ★★★★★ | Klein | ✅ Adaptieren — OWASP-Checklist + False Positives |
| 2 | Code-Reviewer Confidence + AI-Code Checks | ★★★★ | Klein | ✅ Adaptieren — 3 Zeilen ergaenzen |
| 3 | Build-Fix Command | ★★★★ | Klein | ✅ Adaptieren — aktiver Fixer statt passiver Reporter |
| 4 | Agent YAML Frontmatter | ★★★ | Mittel | ⚠️ Evaluieren — Migration aller 11 Agents |
| 5 | CI Validation Scripts | ★★★ | Mittel | ⚠️ Eigene Spec erstellen |
| 6 | False Positive Guidance (alle Agents) | ★★★ | Klein | ✅ Adaptieren — Section in relevante Agents |
| 7 | E2E Command | ★★ | Klein | ⏸️ Spaeter — bei Bedarf |
| 8 | TDD Command | ★★ | Mittel | ⏸️ Spaeter — Team nutzt kein TDD |
| 9 | /learn + /evolve Pipeline | ★★ | Hoch | ❌ Nicht adaptieren — claude-mem ist besser |
| 10 | Checkpoint System | ★ | Mittel | ❌ Nicht adaptieren — Commits reichen |
| 11 | Hook Recipe Collection | ★★ | Klein | ⚠️ Nice-to-have fuer Docs |
| 12 | Harness Audit Score | ★ | Klein | ❌ Nicht adaptieren — /doctor reicht |
