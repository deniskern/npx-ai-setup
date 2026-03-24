# Setup Overhead Audit

## Baseline Tokens/Nachricht

| Komponente | Zeilen | ~Tokens | Status |
|------------|--------|---------|--------|
| CLAUDE.md (Projektebene) | 105 | ~1,575 | Groß |
| Rules (immer geladen, 7 von 8) | 149 | ~2,235 | OK (kurz) |
| Rules (testing.md, scoped) | 37 | — | OK |
| .agents/context/ (SessionStart-Inject) | 472 | ~400 | OK |
| Skills-Menü (.claude/skills/, 14 Skills) | 14 Skills | ~1,400 | Groß |

**Gesamt: ~5,610 Tokens/Nachricht**

## Probleme nach Priorität

| Problem | Tokens-Waste | Aufwand | Fix |
|---------|-------------|---------|-----|
| Skills-Menü 14 lokale Skills | ~1,400 | Mittel | Domain-Skills optional; skill-creator-workspace entfernen |
| CLAUDE.md 105 Zeilen | ~300+ | Klein | Sections kürzen, Tiered Loading |
| Nur testing.md gescoped | 0 | Klein | Weitere Rules mit paths: versehen |

## Geschätzte Einsparung: ~400 Tokens/Nachricht

- CLAUDE.md 20 Zeilen kürzen: ~300 Tokens
- 3 projektspezifische Skills aus Menü entfernen: ~300 Tokens
