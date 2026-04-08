# Brainstorm: Repowise Adaptionen für npx-ai-setup

> **Source**: https://github.com/repowise-dev/repowise
> **Erstellt**: 2026-04-08
> **Zweck**: Research welche Patterns adaptierbar sind
> **Plugin**: `plugins/claude-code/` — Claude Code Plugin mit 4 Skills + 5 Commands + MCP Server

---

## Was ist Repowise?

**Codebase Intelligence Platform** — selbstgehostet (AGPL-3.0), für Claude Code/Cursor/AI-Editoren.

Kernidee: Beantwortet "**warum** existiert dieser Code?" statt "**was** macht dieser Code?"

### Vier Intelligence Layer
1. **Graph Intelligence** — Tree-sitter AST → NetworkX dependency graph → PageRank
2. **Git Intelligence** — 500 Commits minen: Hotspots, Ownership, Co-changes, Bus Factor
3. **Documentation Intelligence** — LLM-generiertes Wiki, RAG-Search, Freshness Scoring
4. **Decision Intelligence** — ADR-Extraktion aus Git mit Staleness Tracking

### 8 MCP Tools
`get_overview`, `get_context`, `get_risk`, `get_why`, `search_codebase`, `get_dependency_path`, `get_dead_code`, `get_architecture_diagram`

### Plugin-Architektur
- `plugins/claude-code/` mit eigenem `plugin.json` + `marketplace.json`
- 4 automatische Skills (`user-invocable: false`)
- 5 Slash-Commands (`/repowise:init`, `:status`, `:update`, `:search`, `:reindex`)
- MCP-Server als `repowise mcp` gestartet

---

## Bestandsvergleich: Was haben wir schon?

| Repowise Feature | Unser Äquivalent | Status |
|-----------------|-----------------|--------|
| `/repowise:init` — MCP setup wizard | `bin/ai-setup.sh` (Install-Pipeline) | ⚠️ Partial (kein interaktiver MCP-Wizard) |
| `/repowise:status` — Health check | `/doctor` Skill | ✅ Besser (12 Health Checks, nicht nur MCP) |
| `/repowise:update` — Incremental sync | `/update` Skill | ⚠️ Partial (kein Incremental-Index-Konzept) |
| `/repowise:search` — Wiki-Suche | `/explore` + `search_codebase` via MCP | ❌ Missing (kein Code-Wiki, kein semantic search) |
| `/repowise:reindex` — Rebuild embeddings | `/context-refresh` | ⚠️ Partial (nur LLM-Context, kein Vector-Index) |
| Skill: codebase-exploration | `explore` Skill + Code Agents | ⚠️ Partial (ohne MCP-Tool-Integration) |
| Skill: pre-modification | `code-architect` Agent | ⚠️ Partial (kein automatischer Risk-Trigger) |
| Skill: architectural-decisions | `/explore` + git logs | ❌ Missing (kein ADR-System) |
| Skill: dead-code-cleanup | `techdebt` Skill | ⚠️ Partial (LLM-basiert, nicht graph-basiert) |
| plugin.json + marketplace.json | `/plugin marketplace add` | ⚠️ Partial (wir haben Marketplace, aber anderes Format) |
| Auto-generated CLAUDE.md | `generate.sh` via Agent | ✅ Äquivalent |
| Risk Assessment vor Änderungen | `code-architect` Agent | ⚠️ Partial (kein automatischer Pre-Modification Trigger) |
| ADR-Tracking mit Git | `/decisions.md` | ⚠️ Partial (statisch, kein Git-Mining) |
| MCP-Server als separate Process | Context7 MCP | ✅ Konzept bekannt (anderer Fokus) |

**Inventory:**
```
REPOWISE: 4 skills (auto-triggered), 5 commands, 1 MCP server, 8 MCP tools
OURS:     31 skills, 20 commands, 12 agents, 28 hooks, 8 rules, 1 plugin system
```

**Fazit:** Wir haben mehr Breite (Spec-Workflow, CI, Release, Security). Repowise hat mehr Tiefe (Codebase Intelligence, Risk, ADRs).

---

## Kandidaten für Adaption

### A. Pre-Modification Risk Trigger (Skill)
**Was es macht:** Skill mit `user-invocable: false` + spezifischem Trigger → aktiviert automatisch vor Code-Änderungen → ruft `get_risk()` auf

**Ihr Skill-Trigger (exakt):**
```
description: "ALWAYS run this BEFORE modifying, refactoring, editing, or changing any existing code."
```

**Unser Gap:** Wir haben `code-architect` als Subagent, aber keinen automatisch getriggerten Skill-Flow vor jedem Edit. User muss manuell die richtige Agent aufrufen.

**Adaptierbar ohne Repowise?** Ja — ein `pre-modification` Skill der `/code-architect` delegiert, ohne MCP-Dependency.

**Aufwand:** Klein (1 Skill-File + Routing in workflow.md)
**Wert:** Mittel (würde Architektur-Reviews automatisieren)

---

### B. Architectural Decision Records (ADR) Skill
**Was es macht:** Skill mit Trigger für "warum"-Fragen → liest `# WHY:`, `# DECISION:`, `# TRADEOFF:`, `# ADR:` Kommentare + `/decisions.md`

**Ihr Skill-Trigger:**
```
description: "ALWAYS use this skill when asked WHY something is the way it is, or why a specific architectural approach was chosen."
```

**Unser Gap:** Wir haben `/decisions.md` als statisches ADR-Dokument, aber kein Skill der es automatisch abfragt oder populiert. User weiß nicht, dass es existiert.

**Adaptierbar ohne Repowise?** Ja — ein `architectural-decisions` Skill der:
1. `/decisions.md` liest
2. Git-Log nach ADR-Markers durchsucht
3. Context7 (MCP) nutzt falls Docs verfügbar

**Aufwand:** Mittel (Skill + Ergänzung von decisions.md Template)
**Wert:** Hoch (deckt eine echte Lücke — "warum existiert dieser Code so?" bleibt oft unbeantwortet)

---

### C. Dead Code Skill (Graph-basiert, kein LLM)
**Was es macht:** `get_dead_code()` → liefert strukturierte Confidence Scores ohne LLM-Hallucination

**Ihr Ansatz:**
- `unreachable_file`: in_degree == 0
- `unused_export`: public symbols mit 0 external callers
- `zombie_package`: declared aber nie imported
- `safe_to_delete` flag bei Confidence > 0.7

**Unser Gap:** `techdebt` Skill ist LLM-basiert — kann halluzinieren. Repowise macht es rein graphisch.

**Adaptierbar ohne Repowise?** Nur mit Repowise als Dependency — das ist genau ihr Value Prop.
**Ohne Repowise:** Nicht direkt adaptierbar. Aber der Confidence-Score-Ansatz + `safe_only=true` Pattern für unseren techdebt-Skill wäre wertvolles Pattern.

**Aufwand für den Pattern-Transfer:** Klein (techdebt Skill um Confidence-Level-Ausgabe erweitern)
**Wert:** Mittel

---

### D. Plugin.json / Marketplace.json Format
**Was es macht:** Strukturiertes Plugin-Manifest für Marketplace-Discovery

**Ihr Format:**
```json
{
  "name": "repowise",
  "metadata": { "version": "0.1.0" },
  "plugins": [{ "category": "productivity", "tags": [...] }]
}
```

**Unser Gap:** Unser Marketplace-System existiert (`/plugin marketplace add`). Ob unser `plugin.json` Format identisch ist — unklar.

**Aufwand:** Research (prüfen ob Kompatibilität vorhanden)
**Wert:** Niedrig bis Mittel (nur relevant wenn wir wollen dass Repowise via unseren Marketplace installierbar ist)

---

### E. Repowise als Marketplace-Plugin anbieten
**Was es macht:** `npx @onedot/ai-setup` → Option Repowise als Codebase-Intelligence-Layer mitinstallieren

**Vorteil:** Wir müssen nichts bauen — nur `lib/plugins.sh` um Repowise-Plugin-Support erweitern.

**Technische Anforderungen:**
- Python 3.11+ erforderlich (nicht alle Projekte haben das)
- `pip install repowise` + `repowise init` (~25 Min, ~$5-15 LLM-Kosten)
- Separater Setup-Flow nötig

**Aufwand:** Mittel (conditional install mit Python-Check)
**Wert:** Hoch — differenzierender Feature ("deep codebase intelligence" out of the box)
**Risiko:** Hohe Abhängigkeit auf externes Tool, Initialkosten können abschrecken

---

## Einzelne Sätze/Patterns zum Adaptieren

### 1. Auto-Trigger Skill Pattern (★★★)
```yaml
# Repowise pre-modification/SKILL.md
user-invocable: false
description: "ALWAYS run this BEFORE modifying, refactoring, editing, or changing any existing code."
```
→ Dieses Pattern für unseren `code-architect` Agent nutzbar: als Skill wrappen mit identischem Trigger.

### 2. Fallback-First Pattern in Skills (★★★)
Repowise Skills haben immer einen expliziten Fallback-Block:
```
## If MCP Unavailable
If the MCP server is not available or returns an error:
- Continue with the task using your built-in knowledge
- Remind the user to run `/repowise:status`
```
→ Unser `explore` und `debug` Skills haben keinen MCP-Fallback. Wäre robuster.

### 3. Confidence-Level Output für Destructive Actions (★★)
```
## Confidence Tiers
- **SAFE** (confidence ≥ 0.9): Require no LLM verification
- **REVIEW** (0.7-0.9): Check usage + document removal
- **SKIP** (< 0.7): Don't touch without manual review
```
→ Unser `techdebt` Skill gibt keine Confidence Scores aus. Dieses Pattern würde Vertrauen erhöhen.

### 4. DEVELOPER.md für Plugin-Wartung (★★)
Repowise hat ein separates `DEVELOPER.md` das Plugin-Versionierung, Release-Prozess und Sync mit Standalone-Repo dokumentiert.
→ Wir haben kein Plugin-Contributor-Guide. Bei wachsendem Marketplace relevant.

### 5. Structured WHY-Markers im Code (★★)
```
# WHY: Explain rationale
# DECISION: Document choice
# TRADEOFF: Note tradeoffs
# ADR: Link to decision record
```
→ Diese Marker-Konvention könnten wir in CONVENTIONS.md oder rules/general.md dokumentieren.

---

## Architektur-Patterns

### "Intelligence Layer" Separation
Repowise trennt sauber: Graph Intelligence | Git Intelligence | Doc Intelligence | Decision Intelligence.
Wir haben alles in einem Monolith-Skill-Set. Kein architectural damage — aber die klare Trennung ist kommunikativ wertvoll für Docs.

### MCP als "Backend für Skills"
Skills rufen MCP-Tools auf, statt direkt Bash/Grep. Das ist sauberer als unsere Hooks-als-Datenlieferant-Pattern. Skills werden vom MCP-Server entkoppelt.

### Plugin als Thin Wrapper
Repowise Plugin ist 14 Files, ~500 Zeilen total. Die Intelligence sitzt im Python-Backend. Das Plugin ist nur "Claude-Interface". Unser Setup ist das Gegenteil — wir sind der Intelligence-Layer.

---

## Token Economics

| Pattern | Token Impact |
|---------|-------------|
| Pre-Modification Skill | +100-300 Token per Edit-Trigger (Risk Assessment) |
| ADR Skill | +50-200 Token wenn "warum"-Fragen kommen |
| Repowise MCP Integration | Erste Calls teuer (Init ~$5-15), danach < 30s per Update |
| Dead Code Confidence Scores | Neutral (Text-Output-Format-Änderung) |

**Kritisch:** Repowise Init kostet einmalig $5-15 LLM-Kosten — das muss transparent kommuniziert werden.

---

## Gesamtranking nach Aufwand/Nutzen

| # | Item | Wert ★ | Aufwand | Empfehlung |
|---|------|---------|---------|------------|
| 1 | ADR Skill (`architectural-decisions`) | ★★★★ | S (1 Tag) | **GO** — deckt echte Lücke, kein Repowise nötig |
| 2 | Pre-Modification Skill (auto-trigger) | ★★★ | S (0.5 Tag) | **GO** — wraps code-architect, kein neues Feature |
| 3 | Repowise als Marketplace-Plugin | ★★★★ | M (2-3 Tage) | **CONSIDER** — hohe Wirkung, aber Dependency-Risiko |
| 4 | Confidence Levels in techdebt Skill | ★★★ | S (0.5 Tag) | **GO** — besserer Output, kein Repowise nötig |
| 5 | MCP-Fallback Pattern in Skills | ★★ | XS (2h) | **GO** — Robustheit, easy win |
| 6 | WHY-Marker Konvention in CONVENTIONS | ★★ | XS (1h) | **GO** — Dokumentations-Pattern |
| 7 | Plugin.json Format-Kompatibilität | ★★ | S (Research) | **RESEARCH** — prüfen ob nötig |
| 8 | DEVELOPER.md für Plugin-Maintainer | ★ | XS (1h) | **SKIP** — zu früh |

---

## Strategische Einschätzung

**Solltest du Repowise lokal installieren?**

**Für npx-ai-setup als Projekt:** Nein, nicht sinnvoll. Das Repo hat 200 Dateien, keine komplexen Architektur-Entscheidungen, kein Bus-Factor-Problem. Repowise ist für große, langlebige Codebases konzipiert (3000+ Dateien, Teams, historische Schulden).

**Für deine Kundenprojekte (one-dot.de):** Potenziell ja — für Projekte mit >500 Files und komplexer Legacy-Architektur. Die $5-15 Init-Kosten zahlen sich aus wenn Claude sonst 30+ Tool-Calls braucht um zu verstehen was wo liegt.

**Interessanteste Adoption:** Der ADR-Skill und Pre-Modification-Trigger sind unabhängig von Repowise sinnvoll. Die bringen uns Repowise-ähnliche Intelligence ohne die Python-Dependency.
