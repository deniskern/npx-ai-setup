# Spec 627: Lightweight Dependency Graph (graph.json)

> **Status**: in-review
> **Origin**: Research 626 (Graphify), User Decision: eigenes Lightweight-Mapping statt Python-Dependency
> **Erstellt**: 2026-04-08
> **Aufwand**: M (2-3 Tage)

## Problem

Claude liest in jeder Session dieselben Dateien um Abhaengigkeiten zu verstehen. Ein Projekt mit 50 Dateien kostet ~30k Tokens pro "was importiert X?"-Frage. Diese Information ist statisch und aendert sich nur bei Code-Aenderungen.

## Loesung

Ein Bash/Node-Script das Import/Export-Beziehungen aus JS/TS/Vue-Dateien extrahiert und als `graph.json` persistiert. Ein Context-Hook surfaced relevante Nachbarn wenn Claude eine Datei oeffnet.

## Scope

### In Scope
- Import/Export-Parsing fuer: JS, TS, Vue (SFC), JSX/TSX
- Output: `.agents/context/graph.json` mit Nodes (Dateien) und Edges (Import-Beziehungen)
- Integration in `/analyze` Pipeline (nach ARCHITECTURE.md Generation)
- Context-Hook: Bei Read/Edit einer Datei die direkten Nachbarn aus graph.json liefern
- Incremental Updates: nur geaenderte Dateien neu parsen (mtime-basiert)

### Out of Scope
- Andere Sprachen (Go, Rust, Java) — dafuer Graphify empfehlen
- Call-Graph-Analyse (welche Funktionen rufen welche auf) — braucht AST-Parser
- Community Detection / Clustering — Overkill fuer 20-80 Dateien
- MCP Server — graph.json direkt im Hook lesen reicht
- Visualisierung (HTML, SVG) — nicht noetig fuer Context-Priming

## Technisches Design

### graph.json Schema

```json
{
  "version": 1,
  "generated": "2026-04-08T10:00:00Z",
  "root": "/Users/user/project",
  "nodes": [
    {
      "id": "src/services/user.ts",
      "type": "file",
      "exports": ["UserService", "createUser", "UserType"]
    }
  ],
  "edges": [
    {
      "source": "src/pages/profile.vue",
      "target": "src/services/user.ts",
      "imports": ["UserService", "UserType"]
    }
  ]
}
```

### Import-Parsing (Regex-basiert)

Patterns die abgedeckt werden muessen:
```js
import { Foo } from './bar'           // Named import
import Foo from './bar'               // Default import
import * as Foo from './bar'          // Namespace import
import './bar'                        // Side-effect import
const Foo = require('./bar')          // CommonJS
export { Foo } from './bar'           // Re-export
import type { Foo } from './bar'      // Type import (TS)
```

Vue SFC: `<script>` und `<script setup>` Bloecke extrahieren, dann wie TS parsen.

### Pfad-Resolution

- Relative Imports (`./`, `../`) zu absoluten Pfaden aufloesen
- `@/` Alias zu `src/` mappen (aus tsconfig.json/vite.config lesen)
- `node_modules` Imports ignorieren (nur project-interne Edges)
- Index-Files aufloesen (`./utils` → `./utils/index.ts`)

### Script: `scripts/build-graph.sh`

```
Input:  Projektverzeichnis
Output: .agents/context/graph.json
Speed:  <2s fuer 100 Dateien (kein LLM, kein Netzwerk)
```

1. Alle JS/TS/Vue-Dateien finden (respektiert .gitignore)
2. Pro Datei: Imports und Exports extrahieren (Regex)
3. Pfade aufloesen (relativ → absolut)
4. JSON zusammenbauen
5. Manifest mit mtimes speichern fuer Incremental Updates

### Context-Hook: `hooks/graph-context.sh`

Trigger: PreToolUse auf Read/Edit
Logik:
1. Pruefe ob `.agents/context/graph.json` existiert
2. Extrahiere Dateiname aus dem Tool-Argument
3. Finde alle direkten Nachbarn (importiert von + importiert)
4. Gib 1-Zeiler zurueck: `[GRAPH] profile.vue imports: UserService (user.ts), AuthGuard (auth.ts). Imported by: router.ts, app.vue`

Performance-Budget: <50ms (JSON-Parsing + jq Query).

### Integration in /analyze

Nach der ARCHITECTURE.md-Generation:
1. `build-graph.sh` ausfuehren
2. graph.json Statistiken in ARCHITECTURE.md einbetten:
   - "X Dateien, Y Import-Beziehungen"
   - "Hub-Dateien (meiste Imports): [liste]"
   - "Isolierte Dateien (keine Imports/Exports): [liste]"

## Acceptance Criteria

1. `build-graph.sh` laeuft auf einem Nuxt-Projekt mit 50+ Dateien in <2s
2. graph.json enthaelt korrekte Import-Edges fuer: named imports, default imports, re-exports, Vue SFCs
3. Pfad-Aliases (@/) werden korrekt aufgeloest
4. Context-Hook liefert Nachbarn in <50ms
5. Incremental Update parst nur geaenderte Dateien
6. node_modules-Imports werden ignoriert
7. Zirkulaere Imports werden erkannt und geloggt (aber nicht blockiert)

## Risiken

| Risiko | Mitigation |
|--------|-----------|
| Regex-Parsing deckt nicht alle Edge Cases ab | 90% Coverage reicht — komplexe Faelle (dynamic imports, computed paths) bewusst ignorieren |
| Pfad-Resolution bei Monorepos komplex | V1: nur Single-Package-Projekte. Monorepo-Support spaeter |
| graph.json wird stale | context-freshness.sh erweitern: warnen wenn graph.json aelter als letzter git commit |

## Abgrenzung zu Graphify

| Feature | Unser graph.json | Graphify |
|---------|------------------|----------|
| Sprachen | JS/TS/Vue | 19 Sprachen |
| Parsing | Regex | tree-sitter AST |
| Granularitaet | Datei-Level | Funktions-Level |
| Dependencies | Keine (Bash + jq) | Python + tree-sitter |
| Aufwand | 2-3 Tage | pip install |
| Maintenance | Selbst | Community (7.5k Stars) |

Fuer Teams die mehr brauchen: Graphify empfehlen (`pip install graphifyy && graphify .`).

## Steps

1. **Script**: `scripts/build-graph.sh` — Import/Export-Parsing + JSON-Output
2. **Hook**: `hooks/graph-context.sh` — Nachbar-Surfacing bei Read/Edit
3. **Integration**: `/analyze` Pipeline um graph.json erweitern
4. **Freshness**: `context-freshness.sh` um graph.json Staleness-Check erweitern
5. **Template**: graph-context Hook in templates/hooks/ aufnehmen
6. **Docs**: ARCHITECTURE.md Template um Graph-Statistiken erweitern
