# Spec: architectural-decisions Skill

> **Spec ID**: 627 | **Created**: 2026-04-08 | **Status**: in-review | **Complexity**: low | **Branch**: —

## Goal

Einen auto-triggering Skill implementieren, der bei "Warum"-Fragen über Code-Entscheidungen automatisch `decisions.md`, WHY-Kommentare im Code und ADR-Commits auswertet und eine kohärente Antwort synthetisiert.

## Context

Projekterinnerungen über Architekturentscheidungen sind verstreut: `decisions.md` im Root, `# WHY:`-Kommentare im Code, ADR-Commit-Messages. Ohne diesen Skill antwortet Claude aus dem Kontext heraus oder erfindet Rationale — beide Optionen sind schlechter als die tatsächlich dokumentierten Gründe.

Inspiration: Repowise's `architectural-decisions` Skill nutzt denselben Trigger-Ansatz (`ALWAYS use this skill when asked WHY something is the way it is`).

### Install mechanism

Skills werden generisch installiert: `lib/update.sh` und `lib/core.sh` scannen `templates/skills/` — jedes Verzeichnis mit `SKILL.template.md` wird automatisch nach `.claude/skills/<name>/SKILL.md` kopiert. **Keine Änderung an `lib/` nötig**, nur die neue Template-Datei anlegen.

## Acceptance Criteria

### Truths

1. `templates/skills/architectural-decisions/SKILL.template.md` existiert und ist valide YAML-Frontmatter + Markdown
2. Nach `npx ai-setup` (oder Update) existiert `.claude/skills/architectural-decisions/SKILL.md` im Zielprojekt
3. Der Skill hat `user-invocable: false` im Frontmatter
4. Der Skill liest `decisions.md` wenn vorhanden, findet `# WHY:`, `# DECISION:`, `# TRADEOFF:`, `# ADR:` Marker und nutzt `git log --grep`
5. Der Skill hat einen Fallback wenn keine Quellen gefunden werden
6. `bash scripts/skill-lint.sh` meldet keine Fehler für den neuen Skill
7. `bash tests/smoke.sh` läuft grün (kein Smoke-Test für den neuen Skill nötig — skill-lint reicht)

### Artifacts

- `templates/skills/architectural-decisions/SKILL.template.md` — einzige neue Datei

### Key Links

- `lib/core.sh:190` — generisches Skill-Scanning (`find .claude/skills -name "SKILL.md"`)
- `lib/update.sh:294` — Update-Pfad für Skills (`find templates/skills -mindepth 1 -maxdepth 1 -type d`)
- `scripts/skill-lint.sh` — validiert Frontmatter aller Skills in `templates/skills/`

## Steps

- [ ] Step 1: `templates/skills/architectural-decisions/SKILL.template.md` anlegen (Inhalt unten)
- [ ] Step 2: `bash scripts/skill-lint.sh` — Frontmatter validieren
- [ ] Step 3: `bash tests/smoke.sh` — Regressionscheck

## Files to Modify

- **New:** `templates/skills/architectural-decisions/SKILL.template.md`

Keine weiteren Dateien — der generische Install-Mechanismus erfasst den Skill automatisch.

## Out of Scope

- Automatisches Anlegen von `decisions.md` wenn es fehlt — eigene Überlegung
- Integration in den `explore` Skill (würde den Scope dieses Skills verwischen)
- Smoke-Test für den Skill-Content — skill-lint ist ausreichend für Templates

---

## SKILL.template.md Content

Folgendes ist der exakte Inhalt für `templates/skills/architectural-decisions/SKILL.template.md`:

```markdown
---
name: architectural-decisions
description: "ALWAYS use this skill when asked WHY something is built a certain way, why a specific technology was chosen, or why an architectural approach was taken."
user-invocable: false
effort: low
allowed-tools: Read, Glob, Grep, Bash
---

# Architectural Decisions

Answers WHY-questions about code and architecture by reading documented decisions before reasoning from context.

## Trigger

Activate when the user asks:
- "Why is X implemented this way?"
- "Why does this use X instead of Y?"
- "What was the reason for Z?"
- "Why not use [alternative]?"
- Any question containing "why", "reason", "rationale", "decision" about code structure or technology choices

## Lookup Order

Execute these steps in order, stop when you have enough to answer:

### 1. decisions.md

```bash
[ -f decisions.md ] && cat decisions.md
```

Filter rows matching the topic. A matching row answers the question directly — cite the row number and rationale.

### 2. WHY-Markers in Source Files

Search for inline decision markers near the relevant code:

```bash
grep -rn "# WHY:\|# DECISION:\|# TRADEOFF:\|# ADR:" --include="*.ts" --include="*.js" --include="*.py" --include="*.go" --include="*.rb" --include="*.sh" . 2>/dev/null | head -40
```

If the file/module in question is known, search it directly first:
```bash
grep -n "# WHY:\|# DECISION:\|# TRADEOFF:\|# ADR:" <relevant-file>
```

### 3. Git Log (ADR commits)

```bash
git log --oneline --grep="ADR\|decision\|why\|chose\|switch\|replace\|migrate" -- <relevant-path> 2>/dev/null | head -20
```

Follow up with `git show <hash>` on the most relevant commit to read the full message.

### 4. Fallback

If no documented decision is found in steps 1-3:
- State clearly: "No documented decision found for this."
- Offer a brief inference based on code structure, but label it as inference, not fact.
- Suggest documenting the decision: "Add a row to `decisions.md` to capture this for the future."

## Output Format

**If documented decision found:**
> **Decision [#N / commit abc1234]:** [rationale from source]
> Source: `decisions.md` / `path/to/file.ts:42` / `git show abc1234`

**If inferred only:**
> **No documented decision found.** Inference: [reasoning]. Consider adding to `decisions.md`.

Keep answers under 150 words unless the decision has multiple relevant tradeoffs.
```
