# Spec 159: Gemini & Codex — Minimal Integration

**Status:** completed
**Complexity:** Medium (2–3 files Shell, 2 Templates)
**Branch:** `feat/159-gemini-codex-integration`

## Goal

Gemini CLI und Codex CLI als optionale, gleichwertige Coding-Agents neben Claude Code unterstützen. AGENTS.md als universeller Kontext, Skills über Symlinks geteilt, minimale Config-Templates für sofortigen Start.

## Context

- Claude Code = Primary (alle User haben es)
- Gemini/Codex = Optional (nur installiert wenn API-Key vorhanden)
- `.claude/skills/` ist die Single Source of Truth für Skills
- Codex-Symlink `.codex/skills → .claude/skills` existiert bereits
- Gemini hat **keinen** Symlink und **keine** Config-Templates
- Gemini kann `context.fileName` in settings.json auf `["AGENTS.md"]` setzen → liest AGENTS.md statt GEMINI.md

## Steps

### Step 1: Gemini Skills-Symlink (`lib/setup-skills.sh`)
- [x] `ensure_gemini_skills_alias()` analog zu `ensure_codex_skills_alias()` erstellen
- [x] Symlink: `.gemini/agents → .claude/skills` (Gemini erwartet Skills unter `.gemini/agents/`)
- [x] In `bin/ai-setup.sh` nach `ensure_codex_skills_alias` aufrufen

### Step 2: Gemini Config-Template (`templates/gemini/settings.json`)
- [x] Minimale `.gemini/settings.json` mit:
  - `context.fileName: ["AGENTS.md", "GEMINI.md"]` — AGENTS.md als Kontext
  - Kein Model-Override (User soll selbst wählen)
- [x] `install_gemini_config()` in `lib/setup.sh` — kopiert Template nur wenn `gemini` CLI vorhanden
- [x] In `bin/ai-setup.sh` aufrufen

### Step 3: Codex Config-Template (`templates/codex/config.toml`)
- [x] Minimale `.codex/config.toml` mit:
  - `project_doc_fallback_filenames = ["AGENTS.md"]` — AGENTS.md als Kontext
  - Kein Model-Override
- [x] `install_codex_config()` in `lib/setup.sh` — kopiert Template nur wenn `codex` CLI vorhanden
- [x] In `bin/ai-setup.sh` aufrufen

### Step 4: Gitignore & Cleanup
- [x] `.gemini/` Einträge in `update_gitignore()` hinzufügen (`.gemini/settings.json` soll tracked werden, `.gemini/agents` ist Symlink → ignore)
- [x] Verify: `.codex/skills` ist bereits in .gitignore

### Step 5: AGENTS.md als Workflow-Router
- [x] Commands-Sektion in `templates/AGENTS.md` komplett überarbeiten als Tool-Router:
  - **Claude Code**: `/spec`, `/spec-work NNN`, `/spec-board` etc. (native Slash-Commands)
  - **Codex**: `$spec`, `$spec-work NNN`, `$spec-board` etc. (Dollar-Prefix für Skills)
  - **Gemini**: Natürliche Sprache — "create a spec for X", "work on spec 159", "show spec board"
  - **Alle Tools**: Verfügbare Workflows auflisten (spec-create, spec-work, spec-board, spec-review, spec-validate, spec-work-all) mit Kurzbeschreibung was jeder tut
- [x] Hinweis dass Skills unter `.claude/skills/` liegen und via Symlinks geteilt werden
- [x] Generate-Logik in `lib/generate.sh` prüfen — dort wird AGENTS.md Commands-Sektion generiert, muss den neuen Router-Text enthalten

## Acceptance Criteria

- [x] `npx @onedot/ai-setup` erstellt `.gemini/settings.json` + `.gemini/agents` Symlink wenn `gemini` installiert
- [x] `npx @onedot/ai-setup` erstellt `.codex/config.toml` wenn `codex` installiert
- [x] Ohne installierte CLIs: keine Gemini/Codex-Dateien angelegt (optional bleibt optional)
- [x] Skills-Symlinks zeigen auf `.claude/skills/` (Single Source of Truth)
- [x] AGENTS.md enthält Hinweise für beide Tools
- [x] Idempotent: zweiter Lauf ändert nichts

## Files to Modify

- `lib/setup-skills.sh` — `ensure_gemini_skills_alias()`
- `lib/setup.sh` — `install_gemini_config()`, `install_codex_config()`, `update_gitignore()`
- `bin/ai-setup.sh` — neue Funktionsaufrufe
- `templates/gemini/settings.json` — neu
- `templates/codex/config.toml` — neu
- `templates/AGENTS.md` — Gemini-Hinweis
