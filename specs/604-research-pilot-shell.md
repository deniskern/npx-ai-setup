# Brainstorm: pilot-shell Adaptionen für npx-ai-setup

> **Source**: https://github.com/maxritter/pilot-shell
> **Erstellt**: 2026-04-01
> **Zweck**: Research welche Patterns adaptierbar sind

---

## Bestandsvergleich: Was haben wir schon?

| External Item | Our Equivalent | Status |
|--------------|---------------|--------|
| `/spec` Dispatcher | `spec` + `spec-work` Skills | ⚠️ Partial |
| `/spec-plan` | `spec/SKILL.md` | ⚠️ Partial |
| `/spec-implement` | `spec-work/SKILL.md` | ⚠️ Partial |
| `/spec-verify` | `spec-review/SKILL.md` | ⚠️ Partial |
| `/spec-bugfix-plan` | `/debug` Skill | ⚠️ Partial (kein Plan-File) |
| `/spec-bugfix-verify` | — | ❌ Missing |
| `/setup-rules` | `/analyze` | ⚠️ Partial |
| `/create-skill` | `skill-creator-workspace/` | ⚠️ Partial |
| `changes-review` Agent | `code-reviewer` Agent | ⚠️ Partial |
| `spec-review` Agent | `verify-app` Agent | ⚠️ Partial |
| `context_monitor.py` | — | ❌ Missing |
| `file_checker.py` (TDD enforcement) | testing.md (rule only) | ❌ Missing (kein Hook) |
| `pre_compact.py` | `/pause` Skill (manuell) | ❌ Missing (kein Auto-Hook) |
| `post_compact_restore.py` | `/resume` Skill (manuell) | ❌ Missing (kein Auto-Hook) |
| `session_clear.py` | — | ❌ Missing |
| `session_end.py` | — | ❌ Missing |
| `spec_mode_guard.py` | — | ❌ Missing |
| `spec_plan_validator.py` | — | ❌ Missing |
| `spec_stop_guard.py` | — | ❌ Missing |
| `spec_verify_validator.py` | — | ❌ Missing |
| `tool_redirect.py` | CLAUDE.md Regel (unenforciert) | ⚠️ Partial |
| `tool_token_saver.py` (RTK hook) | RTK in CLAUDE.md | ✅ Covered |
| `task-and-workflow.md` | `workflow.md` | ⚠️ Partial |
| `context-management.md` | CLAUDE.md Sektion | ✅ Covered |
| `development-practices.md` | `quality.md` + `general.md` | ⚠️ Partial |
| `verification.md` | `quality.md` | ⚠️ Partial |
| `testing.md` | `.claude/rules/testing.md` | ⚠️ Partial |
| `code-review-reception.md` | — | ❌ Missing |
| `browser-automation.md` | CLAUDE.md + agent-browser | ✅ Covered |
| `cli-tools.md` | CLAUDE.md RTK-Sektion | ⚠️ Partial |
| `mcp-servers.md` | CLAUDE.md MCP-Sektion | ✅ Covered |

**EXTERNAL**: 8 commands, 2 agents, 13 hooks, 9 rules, 4 scripts
**OURS**: 20 commands, 12 agents, 6 rules, 18+ skills, 0 hooks in templates/

---

## Kandidaten für Adaption

### 1. `testing.md` verbessern (⚠️ Partial → Lücken schließen)

Pilot-shell hat die deutlich stärkere Testing-Regel. Konkrete Lücken in unserer `/rules/testing.md`:

- **TDD-Zyklus mit exakten Schritten** (RED → VERIFY RED → GREEN → VERIFY GREEN → REFACTOR) mit Naming Conventions per Sprache
- **Mock Audit Checklist**: "When adding a new dependency to an existing function, MUST update ALL existing tests" — #1 Ursache für CI-only Failures
- **Anti-Pattern Liste** (9 konkrete Anti-Patterns inkl. "Mocking without understanding", "Test-only methods in production")
- **Zero Tolerance für Failing Tests**: "Pre-existing failure is not an excuse — if you see it, you fix it"
- **Condition-Based Waiting** statt `sleep` (flaky test pattern)
- **Property-Based Testing** Sektion (Hypothesis, fast-check, Go fuzz)

**Gap**: Unsere Datei hat die Kernprinzipien, aber kaum die konkreten Mechanismen. Effort: S. Value: ★★★★★

---

### 2. `tool_redirect` Hook — WebFetch/WebSearch blockieren (❌ Missing)

Pilot-shell blockiert `WebFetch` und `WebSearch` per PreToolUse-Hook hart und leitet auf MCP-Alternativen um. Wir haben das als CLAUDE.md-Regel (defuddle bevorzugen), aber ohne Enforcement.

```python
# tool_redirect.py Kernlogik
"WebFetch": {
    "message": "WebFetch is blocked (truncates at ~8KB)",
    "alternative": "Use defuddle parse <url> --md instead",
}
```

**Unser Equivalent**: `rules/general.md` hat "Prefer defuddle" — aber als Bitte, nicht als Block.

Ein leichtgewichtiger Hook (Bash, <50ms) könnte WebFetch/WebSearch blockieren und auf `defuddle parse <url> --md` umleiten — ohne Python-Dependencies.

**Gap**: Enforcement fehlt komplett. Effort: S. Value: ★★★★

---

### 3. `development-practices.md` Patterns (⚠️ Partial → 3 konkrete Patterns)

Drei Patterns fehlen in unserer `quality.md`:

**a) Revert-First Debugging Protocol:**
```
1. Revert — undo the change that broke it. Clean state.
2. Delete — can the broken thing be removed entirely?
3. One-liner — minimal targeted fix only.
3+ failed fixes = the approach is wrong, not the fix.
```

**b) Ghost Constraints:**
> "Past constraints baked into the current approach that no longer apply. Ask 'why can't we do X?' — if nobody can point to a current requirement, it may be a ghost."
Klassifizierung: Hard / Soft / Ghost — Ghost-Constraints zu finden ist wertvoller als Hard/Soft.

**c) Systematic Debugging Phasen** (Root Cause → Pattern Analysis → Hypothesis → Implementation):
Unsere `quality.md` hat "fail fast with clear error messages" aber keine strukturierten Debugging-Phasen.

**Gap**: `quality.md` hat Korrektheit/Sicherheit/Performance — kein Debugging-Prozess. Effort: S. Value: ★★★★

---

### 4. `file_checker.py` Hook — TDD-Enforcement (❌ Missing)

PostToolUse-Hook auf Write/Edit/MultiEdit: Prüft ob eine Test-Datei zur geänderten Datei existiert, warnt wenn nicht.

```python
# file_checker.py Kernlogik
# Für jede geänderte .py/.ts/.go Datei:
# Prüfe ob test_<module>.py / <base>.test.ts / <base>_test.go existiert
# Wenn nicht: non-blocking warning via context message
```

Pilot-shell macht das als Python-Hook mit Language-Checker-Klassen (go.py, python.py, tdd.py, typescript.py).

**Unser Gap**: Wir haben `testing.md` als Regel — aber kein Hook, der automatisch warnt wenn Codedateien ohne Tests geändert werden. Unser Hook muss <50ms sein und darf keine API-Calls machen.

**Implementierung für uns**: Einfacherer Bash-Hook ist möglich (kein Python required), prüft nur ob Testdatei existiert.

**Gap**: Automatische TDD-Enforcement fehlt komplett. Effort: M. Value: ★★★★

---

### 5. `spec_stop_guard.py` — Premature Stop Blockierung (❌ Missing)

Stop-Hook der Claude blockiert, wenn eine Spec-Session läuft und noch unerledigte Tasks existieren. Kernbotschaft:

> "IMMEDIATELY continue working on the next pending task. Your VERY NEXT action must be a tool call"

Pilot-shell implementiert das mit einer `active_plan.json` State-Datei + Plan-Status-Check.

**Unser Gap**: Unsere Spec-Skills (spec-work, spec-run) haben keine Enforcement — Claude kann jederzeit stoppen, auch mid-spec. Ein Stop-Hook könnte `.continue-here.md` prüfen und blockieren wenn es existiert.

**Einfachere Variante für uns**: Stop-Hook der `.continue-here.md` prüft (unsere WIP-Checkpoint Datei) und warnt wenn aktive Session unfertig ist.

**Gap**: Null Enforcement bei Spec-Abbrüchen. Effort: M. Value: ★★★

---

### 6. `code-review-reception.md` — Review-Feedback Handling (❌ Missing)

Strukturierter Prozess für Review-Feedback von verschiedenen Quellen:
- User-Feedback: trusted, implement after understanding
- External Reviewers: verify technical correctness first
- Review Agents: mandatory fixes immediately, suggestions if straightforward

**YAGNI-Check**: "When reviewers suggest new features, search for actual usage — unused code = pushback"
**No effusive language**: "Absolutely right" / "Great point" verboten

**Gap**: Wir haben keine dedizierte Regel wie mit Review-Feedback umzugehen ist. Effort: S. Value: ★★★ (Team > Solo)

---

### 7. Automated Pre/Post Compact Hooks (❌ Missing)

Pilot-shell hat PreCompact + SessionStart(compact) Hooks die State automatisch sichern/restoren.

Unser Setup: `/pause` und `/resume` Skills — manuell. Der Unterschied: bei Pilot passiert das automatisch ohne Nutzeraktion.

**Implementierungsaufwand**: Pilot braucht einen Worker-API (localhost:41777) als Backend. Ohne den ist die Fallback-Variante einfaches JSON-File-Write in `~/.pilot/sessions/`.

**Für uns**: PreCompact-Hook könnte `.continue-here.md` automatisch schreiben (was `/pause` manuell macht). SessionStart(compact)-Hook könnte es lesen.

**Gap**: Manuelle Aktion vs. Automatik. Effort: M. Value: ★★★

---

## Einzelne Sätze/Patterns zum Adaptieren

Aus `development-practices.md`:
> "Meta-Debugging: Treat your own code as foreign. Your mental model is a guess — the code's behavior is truth."

Aus `testing.md`:
> "Mock Audit on Dependency Changes: When adding a new dependency to an existing function, you MUST update ALL existing tests — this is the #1 cause of CI-only test failures."

Aus `testing.md`:
> "Mocking without understanding: before mocking a dependency, understand what it actually does. A mock that doesn't reflect real behavior is a lie — tests pass against the lie, then fail against reality."

Aus `development-practices.md`:
> "3+ failed fixes = architectural problem. Question the pattern, don't fix again."

Aus `verification.md`:
> "Stop signals trigger immediate verification: uncertain language ('probably'), satisfaction expressions, commits/pushes, or task completion claims all require pre-execution checks."

Aus `tool_redirect.py`:
> "WebFetch is blocked (truncates at ~8KB)" — diese Begründung ist besser als unsere (wir sagen nur "bevorzuge defuddle")

---

## Architektur-Patterns

### Pattern 1: Stop-Hook als Workflow-Wächter
Pilot nutzt den `Stop` Lifecycle-Event um Workflow-Compliance zu erzwingen. Das ist ein eleganteres Muster als reine Regel-Prosa. Ein Stop-Hook kann prüfen: "Ist gerade eine Spec aktiv?" und basierend darauf blockieren oder durchlassen.

### Pattern 2: Hook statt Regel für Enforcement
Das wiederkehrende Muster: Überall wo Pilot etwas WIRKLICH erzwingen will, ist ein Hook — nicht eine Regel in CLAUDE.md. WebFetch-Block → Hook. TDD-Check → Hook. Stop-Guard → Hook. Das ist exakt die Philosophie aus unserem CONCEPT.md ("Hook-Based Safety"), aber wir haben es in der Praxis noch nicht für diese Cases implementiert.

### Pattern 3: Language-conditional Hooks
`file_checker.py` hat separate Checker-Klassen pro Sprache (go.py, python.py, typescript.py). Hooks werden nur für relevante Dateitypen ausgelöst. Sauberere Separation als alles in einen Hook zu packen.

### Pattern 4: Non-blocking Warnings als Hook-Output
Statt `exit 2` (hard block) nutzen viele Pilot-Hooks `post_tool_use_context()` für Warnings — Claude sieht die Warnung aber wird nicht geblockt. Das ist weniger aggressiv als unser `.env`-Block-Ansatz, aber für TDD-Enforcement sinnvoller.

---

## Philosophy Check (Phase 5.5)

Gegen CONCEPT.md und decisions.md geprüft:

| Kandidat | ADD Safety? | Base oder Boilerplate? | Bereits covered? | Verdict |
|----------|-------------|----------------------|-----------------|---------|
| testing.md verbessern | ✅ ADD | Base (alle Projekte) | Nein (Lücken) | **GO** |
| tool_redirect Hook | ✅ ADD (enforcement) | Base | Nein | **GO** |
| development-practices Patterns | ✅ ADD | Base | Nein | **GO** |
| file_checker Hook (TDD) | ✅ ADD | Base | Nein | **GO** |
| spec_stop_guard Hook | ✅ ADD | Base (spec-Nutzer) | Nein | **GO** |
| code-review-reception.md | neutral | Base oder Template | Nein | **PIVOT** (templates/agents) |
| pre/post compact Hooks | ✅ ADD | Base | Manuell via Skills | **PIVOT** (simplifizierten Bash-Hook) |
| spec_plan_validator | neutral | Spec-only | — | **SKIP** (andere Plan-Struktur) |
| spec_mode_guard | neutral | Minor UX | — | **SKIP** (geringer Impact) |
| create-skill Command | neutral | Partial covered | skill-creator-workspace | **SKIP** |

**D3-Check**: Entscheidung D3 betrifft "Agent lifecycle hooks" (Metrics). Diese Hooks sind Quality/Safety hooks — D3 gilt nicht.

---

## Was wir NICHT adaptieren

| Pilot-Schicht | Grund |
|--------------|-------|
| Console / Web-Dashboard (localhost:41777) | Produkt-Layer, nicht Setup-Schicht. Widerspricht "lightweight, one command". |
| Python/uv-Runtime-Hooks | Unser Kernversprechen ist Bash + keine schweren Dependencies. Alle unsere Hooks bleiben <50ms Bash-only. |
| Lizenz- und Trial-System | Irrelevant für Open-Source-Setup-Tool. |
| RTK als forced Bash-Hook | RTK ist optional in CLAUDE.md dokumentiert — kein Enforcement-Hook, da nicht jeder es hat. |
| worker-service.cjs + Node-Worker-API | Komplexe Infra für Memory/Session-API. Weit außerhalb unseres Scope. |
| Multi-Session-Isolation via `PILOT_SESSION_ID` | Wir sind repo-local committed — keine globale Session-Verwaltung nötig. |
| Globale CLI (`pilot` Binary in `~/.pilot/`) | Unser Setup ist explizit repo-local committable. Global = nicht überprüfbar, nicht versionierbar. |

**Leitprinzip**: Jede Adaption muss als Bash-Script in `templates/claude/hooks/` committed und reviewed sein. Keine Binaries, kein Python, keine externen Services.

---

## Gesamtranking nach Aufwand/Nutzen

| Rang | Item | Value ★ | Aufwand | Empfehlung |
|------|------|---------|---------|------------|
| 1 | `testing.md` verbessern (TDD-Zyklus, Mock-Audit, Anti-Patterns) | ★★★★★ | S | GO — sofort umsetzbar |
| 2 | `tool_redirect` Hook (WebFetch/WebSearch → defuddle) | ★★★★ | S | GO — Bash-Hook, keine Dependencies |
| 3 | `development-practices` Patterns (Revert-First, Ghost Constraints, Debugging Phasen) | ★★★★ | S | GO — in quality.md oder general.md |
| 4 | `file_checker` Hook (TDD-Enforcement als non-blocking Warning) | ★★★★ | M | GO — Bash-Hook, einfachere Version |
| 5 | `spec_stop_guard` Hook (Stop blockieren wenn .continue-here.md aktiv) | ★★★ | M | GO — spec-Nutzer profitieren direkt |
| 6 | `code-review-reception.md` | ★★★ | S | PIVOT — templates/agents, nicht base |
| 7 | Auto Pre/Post Compact Hooks | ★★★ | M | PIVOT — simplifizierten Bash-Hook ohne Worker-API |
