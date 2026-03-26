# Brainstorm: Claude Code Auto Mode Adaptionen für npx-ai-setup

> **Source**: https://code.claude.com/docs/en/best-practices#run-autonomously-with-auto-mode
> **Status**: ✅ Completed — Research abgeschlossen, Auto-Mode dokumentiert
> **Erstellt**: 2026-03-25
> **Zweck**: Research welche Auto-Mode- und Autonomie-Patterns adaptierbar sind

## Bestandsvergleich: Was haben wir schon?

| External Pattern | Unser Equivalent | Status |
|---|---|---|
| Auto Mode (`--permission-mode auto`) | `yolo/SKILL.md` (bypassPermissions) | ⚠️ Partial |
| `--bare` Flag für CI | `CLAUDE.md` Automation Section (erwähnt `-p`) | ⚠️ Partial |
| `--allowedTools` Granularität | `templates/settings.json` Permissions | ⚠️ Partial |
| `--disallowedTools` | Nicht dokumentiert | ❌ Missing |
| `--max-budget-usd` Budget-Cap | `yolo/SKILL.md` hat kein Budget-Limit | ❌ Missing |
| `--max-turns` Turn-Limit | Kein Equivalent | ❌ Missing |
| `--effort` Level | Model Routing in `agents.md` (manuell) | ⚠️ Partial |
| `--json-schema` Structured Output | Prep-Scripts nutzen `jq` post-hoc | ⚠️ Partial |
| `--no-session-persistence` | Nicht dokumentiert | ❌ Missing |
| `--fallback-model` | Kein Equivalent | ❌ Missing |
| `dontAsk` Permission Mode | `ci/SKILL.md` nutzt read-only | ⚠️ Partial |
| `--fork-session` | Kein Equivalent | ❌ Missing |
| `--bare` + `--allowedTools` CI-Pattern | Kein CI-Template | ❌ Missing |
| Permission Mode Dokumentation | `CLAUDE.md` erwähnt `Shift+Tab` nicht | ⚠️ Partial |
| Classifier Trusted Infrastructure | Kein Equivalent | ❌ Missing |

**Zusammenfassung**: 0 voll abgedeckt, 6 teilweise, 9 fehlend.

## Kandidaten für Adaption

### K1: Budget-Guard für yolo-Skill ★★★★★

**Was**: `--max-budget-usd` als Safety-Net in den yolo-Skill integrieren.
**Unsere Lücke**: yolo läuft unbegrenzt — kein finanzieller Fallback.
**Aufwand**: Klein — eine Zeile Frontmatter oder CLI-Flag-Dokumentation.
**Empfehlung**: ADOPT — verhindert Runaway-Sessions. Default z.B. $5.

### K2: `--bare` CI-Template ★★★★☆

**Was**: Ein CI/CD-Template das `--bare` + `--allowedTools` + `--max-budget-usd` kombiniert.
**Unsere Lücke**: Unsere `CLAUDE.md` Automation Section erwähnt `-p` und `--output-format json`, aber nicht `--bare` (das Hooks/Skills/MCP deaktiviert — kritisch für reproduzierbare CI).
**Aufwand**: Mittel — neue Section in CLAUDE.md Template oder eigenes CI-Dokument.
**Empfehlung**: ADOPT — `--bare` wird zukünftig Default für `-p`, wir sollten das jetzt dokumentieren.

### K3: Permission Mode Awareness in CLAUDE.md ★★★★☆

**Was**: CLAUDE.md Template um Permission-Mode-Referenz erweitern.
**Unsere Lücke**: User kennen nur den Default-Modus. `Shift+Tab`-Cycling, `auto`, `dontAsk` sind nicht dokumentiert.
**Aufwand**: Klein — 3-5 Zeilen in CLAUDE.md Template.
**Empfehlung**: ADOPT — niedrige Kosten, hoher Awareness-Gewinn.

### K4: `--effort` Integration in Model Routing ★★★☆☆

**Was**: `--effort low/medium/high/max` als Alternative/Ergänzung zum Model-Routing.
**Unsere Lücke**: Wir routen via `model: haiku/sonnet/opus`. `--effort` könnte innerhalb eines Modells Kosten sparen.
**Aufwand**: Klein — Dokumentation in CLAUDE.md und agents.md Rule.
**Empfehlung**: EVALUATE — `--effort` ist CLI-global, nicht per-Agent steuerbar. Nur für `-p` Mode relevant.

### K5: `--max-turns` für autonome Skills ★★★☆☆

**Was**: Turn-Limit für Skills die in Loops arbeiten (build-fix, test, yolo).
**Unsere Lücke**: build-fix hat eigene Iteration-Limits (max 10), aber kein CLI-seitiges Limit.
**Aufwand**: Klein — Dokumentation + optionaler Default in yolo/build-fix.
**Empfehlung**: ADOPT für yolo — redundant für build-fix (hat eigene Limits).

### K6: `--json-schema` für Prep-Scripts ★★★☆☆

**Was**: Structured Output mit Schema-Validierung statt Post-hoc-jq-Parsing.
**Unsere Lücke**: Prep-Scripts sammeln Daten in Shell, Claude analysiert. Structured Output würde die Analyse-Phase verbessern.
**Aufwand**: Mittel — Prep-Scripts müssten Schema-Dateien mitliefern.
**Empfehlung**: EVALUATE — nur relevant wenn wir `-p` Calls in Prep-Scripts einbauen, was wir aktuell nicht tun.

### K7: `dontAsk` Mode für strikte Environments ★★☆☆☆

**Was**: Permission Mode der nur pre-approved Rules erlaubt.
**Unsere Lücke**: Nicht dokumentiert als Option für Enterprise-Teams.
**Aufwand**: Minimal — Erwähnung in Permission-Mode-Doku.
**Empfehlung**: DOCUMENT — kein Code-Change, nur Awareness.

### K8: Auto Mode Classifier Trusted Infrastructure ★★☆☆☆

**Was**: Managed Settings die dem Classifier sagen welche Repos/Buckets/Services trusted sind.
**Unsere Lücke**: Wir generieren keine Managed Settings.
**Aufwand**: Hoch — neues Feature in ai-setup.
**Empfehlung**: SKIP — Auto Mode ist Research Preview, Team-Plan only. Zu früh.

### K9: `--fallback-model` ★★☆☆☆

**Was**: Automatischer Model-Fallback bei Überlastung.
**Unsere Lücke**: Nicht dokumentiert.
**Aufwand**: Minimal — Erwähnung in Automation-Doku.
**Empfehlung**: DOCUMENT — nützlich für `-p` Mode Nutzer.

### K10: `--no-session-persistence` ★★☆☆☆

**Was**: Kein Disk-Write für ephemere Runs.
**Unsere Lücke**: Nicht dokumentiert.
**Aufwand**: Minimal.
**Empfehlung**: DOCUMENT — relevant für CI.

## Einzelne Sätze/Patterns zum Adaptieren

### Aus dem Auto-Mode-Konzept

1. **Classifier Fallback**: "Bei 3 aufeinanderfolgenden oder 20 totalen Blocks pausiert Auto Mode" — Unser yolo-Skill hat kein ähnliches Fallback-Konzept. Wenn Claude 3x hintereinander scheitert, sollte yolo ebenfalls stoppen.

2. **`--bare` als CI-Default**: "Kein Auto-Discovery von hooks, skills, plugins, MCP-Servern, Auto Memory, CLAUDE.md" — Kritisch für reproduzierbare CI-Runs. Unsere Automation-Doku sollte das prominent erwähnen.

3. **Bash-Matching in allowedTools**: `Bash(git diff *),Bash(git log *)` — Feingranulare Permissions die wir in unserer Permission-Referenz dokumentieren sollten.

4. **Budget als primärer Cost-Control**: Kein Timeout-Flag, stattdessen `--max-budget-usd` — Passt zu unserem Token-Optimierungs-Fokus.

### Aus unseren bestehenden Skills (was wir BESSER machen)

1. **build-fix Iteration-Limits**: Unsere "max 10 Iterationen, max 5% Lines pro Fix, Architektur-Abbruch" sind differenzierter als ein simples `--max-turns`.

2. **Model Routing per Agent**: Unser `model: haiku/sonnet/opus` System ist granularer als `--effort` (das nur global wirkt).

3. **Prep-Scripts**: Shell-basierte Datensammlung vor LLM-Analyse ist token-effizienter als Claude alles selbst lesen zu lassen — das fehlt in den offiziellen Best Practices komplett.

## Architektur-Patterns

### Pattern 1: Tiered Autonomy
Die offizielle Hierarchie: `default` → `acceptEdits` → `plan` → `auto` → `dontAsk` → `bypassPermissions`
Unser Equivalent: Task Complexity Routing (Simple → Medium → Complex), aber ohne Permission-Mode-Mapping.
**Gap**: Wir könnten Permission Modes an Task-Complexity koppeln.

### Pattern 2: Declarative Tool Scoping
`--allowedTools`, `--disallowedTools`, `--tools` als drei Achsen der Tool-Kontrolle.
Unser Equivalent: `allowed-tools` Frontmatter in Skills.
**Gap**: Unsere Skills nutzen `allowed-tools` inkonsistent. Audit opportunity.

### Pattern 3: Budget-First Safety
`--max-budget-usd` als primärer Guard statt Timeouts.
**Gap**: Kein Budget-Awareness in unserem Setup. Wäre ideal für yolo + autonome Workflows.

## Gesamtranking nach Aufwand/Nutzen

| # | Item | Value | Aufwand | Empfehlung |
|---|------|-------|---------|------------|
| K1 | Budget-Guard für yolo | ★★★★★ | Klein | **ADOPT** |
| K2 | `--bare` CI-Template | ★★★★☆ | Mittel | **ADOPT** |
| K3 | Permission Mode Awareness | ★★★★☆ | Klein | **ADOPT** |
| K5 | `--max-turns` für yolo | ★★★☆☆ | Klein | **ADOPT** |
| K4 | `--effort` Dokumentation | ★★★☆☆ | Klein | EVALUATE |
| K6 | `--json-schema` Prep-Scripts | ★★★☆☆ | Mittel | EVALUATE |
| K7 | `dontAsk` Dokumentation | ★★☆☆☆ | Minimal | DOCUMENT |
| K9 | `--fallback-model` Doku | ★★☆☆☆ | Minimal | DOCUMENT |
| K10 | `--no-session-persistence` | ★★☆☆☆ | Minimal | DOCUMENT |
| K8 | Auto Mode Trusted Infra | ★★☆☆☆ | Hoch | SKIP |
