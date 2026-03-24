# Setup Overhead Audit

## Baseline Tokens/Nachricht

| Komponente | Zeilen | ~Tokens | Status |
|------------|--------|---------|--------|
| CLAUDE.md (Projekt) | 105 | ~1260 | OK |
| Rules (immer geladen, 7 von 8) | 149 | ~1788 | Groß |
| Rules (scoped: testing.md) | 37 | 0 | OK |
| Skills Menü (14 Skills) | — | ~1400 | Groß |
| `.agents/context/` (L0 via Hook) | ~472 Zeilen full, Hook ≈ 3 Dateien | ~400 | OK |
| Settings/Hooks Overhead | — | ~100 | OK |
**Gesamt: ~4948 Tokens/Nachricht (Schätzung)**

## Probleme nach Priorität

| Problem | Tokens-Waste | Aufwand | Fix |
|---------|-------------|---------|-----|
| 9 von 14 Skills mit >400-Zeichen-Descriptions | ~700 | Niedrig | Descriptions auf ≤200 Zeichen kürzen |
| 7 Rules immer geladen, kein Scope-Filter | ~1788 | Mittel | paths: Frontmatter für TypeScript/Git/Quality Rules |
| skill-creator-workspace im Skills-Menü | ~100 | Niedrig | Kein SKILL.md gefunden — interne Workspace, kein Nutzer-Skill |
| CLAUDE.md Commands/Critical-Rules-Sections leer (Placeholder) | ~0 real, aber 10 Zeilen Overhead | Niedrig | Leere Sections entfernen |

## Detailbefunde

### Skills mit >400 Zeichen Description (kosten ~50+ Tokens statt ~25)
- agent-browser: 488 Zeichen
- context-load: 581 Zeichen
- explore: 600 Zeichen
- release: 616 Zeichen
- spec-board: 520 Zeichen
- spec-create: 497 Zeichen
- spec-review: 457 Zeichen
- spec-validate: 469 Zeichen
- spec-work: 444 Zeichen
- spec-work-all: 513 Zeichen

### Rules ohne paths: Frontmatter (laden bei JEDER Nachricht)
- agents.md (26 Zeilen)
- general.md (26 Zeilen)
- git.md (23 Zeilen)
- quality-general.md (18 Zeilen)
- quality-maintainability.md (20 Zeilen)
- quality-performance.md (19 Zeilen)
- quality-security.md (17 Zeilen)

### Positiv
- `.agents/context/` hat YAML Frontmatter mit abstract — Hook lädt nur ~400 Tokens statt ~5664 Tokens (volle Dateien)
- testing.md korrekt mit paths: gescopet
- CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: 80 gesetzt

## Geschätzte Einsparung: ~700-900 Tokens/Nachricht
(Skills Descriptions kürzen: ~500, leere Sections bereinigen: ~120, Code-Review-Rule entfernen: ~0 da bereits im Projekt gelöscht)
