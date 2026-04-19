# Spec: Graph-Before-Read PreToolUse Hint-Hook

> **Spec ID**: 645 | **Created**: 2026-04-19 | **Status**: draft | **Complexity**: small | **Branch**: —

## Goal
PreToolUse-Hook der beim `Read`-Aufruf auf große Files (>500 Zeilen) oder beim wiederholten `Grep`/`Glob` ohne vorherige Graph-Abfrage einen nicht-blockierenden Hint ausgibt. Zweck: Claude verwendet zuerst `graph.json` / `liquid-graph.json` / `graphify-out/graph.json` bevor teure Full-File-Reads gemacht werden.

## Context
`agents.md` hat die Rule "Search before Read, Graph before Search" bereits als Text — aber Text-Rules werden inkonsistent befolgt wenn Claude unter Druck ist oder die Rule aus dem Sliding-Window rausgerutscht ist. Ein Hook enforced das deterministisch.

Strategie: **Hint, nicht Block**. Hook darf den Tool-Call nicht verweigern (würde legitime Fälle brechen wie "Lies CHANGELOG.md" oder gezielte Debug-Reads), sondern nur vor dem Call einen stderr-Hint zeigen den Claude im nächsten Turn mitbekommt.

Heuristiken für Trigger:
- `Read` auf File mit >500 Zeilen (pre-stat File-Size) und `graph.json` vorhanden → Hint "Datei hat 1200 Zeilen. Prüfe erst `jq '...' .agents/context/graph.json` für relevante Sections"
- `Grep` im 4. Aufruf in Folge ohne Graph-Query dazwischen (tracked via `~/.cache/ai-setup/tool-history-<session>.log`) → Hint "4× Grep hintereinander. Graph-Lookup wäre hier billiger"

## Steps
- [ ] Step 1: `templates/hooks/graph-before-read.sh` — PreToolUse Hook, empfängt Tool-Name + args via stdin/env, prüft Heuristiken, schreibt Hint nach stderr wenn relevant, exit 0 (niemals 1/2 — würde blocken)
- [ ] Step 2: Session-Tool-History als `~/.cache/ai-setup/tool-history-<session-id>.log` — append-only, cleanup nach 24h via cron/tmpreaper oder bei SessionStart-Hook
- [ ] Step 3: Hook-Registration in Template `.claude/settings.json` unter `hooks.PreToolUse` matching `tool_name: "Read|Grep|Glob"`
- [ ] Step 4: Line-Count-Check nutzt `wc -l <file>` mit Cap-Timeout (50ms), fallback ohne Hint bei timeout
- [ ] Step 5: Hook-Output bewusst kurz halten (<100 Tokens, Konflikt mit Spec 643 harter Cap einhalten)
- [ ] Step 6: Opt-out via `.claude/settings.local.json` mit `graphBeforeRead: false` für User die den Hint nicht wollen
- [ ] Step 7: `doctor.sh` Check: warnt wenn Hook aktiv aber `graph.json` fehlt (dann ist der Hint nutzlos)
- [ ] Step 8: Smoke-Test: Read auf 1000-Zeilen-File in Repo mit `graph.json` → stderr enthält Hint-String; Read auf 50-Zeilen-File → keine Ausgabe; 4× Grep hintereinander → Hint nach 4tem

## Acceptance Criteria
- [ ] `templates/hooks/graph-before-read.sh` ist shellcheck-clean
- [ ] Hook exitet immer mit 0 (nie blockiert) — testbar via `exit_code=$(bash graph-before-read.sh; echo $?)` mit diversen Inputs
- [ ] Read auf >500-Zeilen-File mit vorhandenem `graph.json` → stderr enthält "graph.json" substring
- [ ] Read auf <500-Zeilen-File → kein Output
- [ ] 4× Grep in Folge triggert Hint, 3× nicht
- [ ] Hook-Output nach char-count <400 chars (≈100 Tokens, siehe Spec 643 Policy)
- [ ] `graphBeforeRead: false` in settings.local.json schaltet Hook stumm
- [ ] `bash .claude/scripts/doctor.sh` warnt bei aktivem Hook ohne graph.json
- [ ] `bash .claude/scripts/quality-gate.sh` grün

## Files to Modify
- `templates/hooks/graph-before-read.sh` — NEU
- `templates/claude/settings.json` — Hook-Registration
- `.claude/scripts/doctor.sh` — Sanity-Check
- `templates/rules/agents.md` — verweist auf Hook als Enforcement
- `README.md` — Section "Graph-First Navigation"

## Out of Scope
- Hard-Block bei Missachtung (Hint-only by design)
- Metriken/Telemetrie wie oft Hook feuert (nice-to-have, später)
- Integration mit graphify's `graphify-out/graph.json` (anderer Graph-Typ, andere jq-Queries — in Hint-Text beide erwähnen falls vorhanden)
- Liquid-Graph-Hint für Shopify (kann später ergänzt werden, sobald Spec 639 Liquid-Graph baut — dann hier nachziehen)

## Dependencies
- Soft-Dep auf Spec 639 (Liquid-Graph) und 637 (Graphify) — Hook funktioniert ohne, wird aber reichhaltiger wenn diese existieren
- Hart-Dep auf Spec 643 (Hook-Token-Policy) — Caps müssen eingehalten werden
