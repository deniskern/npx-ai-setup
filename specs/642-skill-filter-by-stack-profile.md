# Spec: Skill-Filter by Stack Profile (Boilerplate-Pull)

> **Spec ID**: 642 | **Created**: 2026-04-19 | **Status**: draft | **Complexity**: medium | **Branch**: —

## Goal
Bei Boilerplate-Pull aus `onedot-digital-crew/*` nur die für das Ziel-Stack-Profil relevanten Skills installieren. Shopify-Themes bekommen keine Nuxt/Storyblok-spezifischen Skills, Laravel keine Liquid-Skills. Reduziert Skill-Listen im SessionStart → weniger Tokens pro Turn + sauberere User-Skill-Auswahl.

## Context
`lib/boilerplate.sh` holt Skills/Rules aus `onedot-digital-crew/<boilerplate-repo>` via `gh api`. Aktuell wird alles gezogen was im Boilerplate-Skills-Verzeichnis liegt. Skills kommen bei SessionStart in Claudes Context — bei 70+ Skills sind das ~2k Tokens nur für Listings, jeden Turn.

Nicht alle Skills gelten überall: `/shopify-*`, `/storyblok-*`, `/liquid-*`, `/obsidian-*` sind offensichtlich stack-spezifisch. Filter-Mechanik: Frontmatter-Feld `stacks: [shopify-liquid, nuxt-storyblok]` im Skill-Markdown, Setup liest Profil (aus Spec 638) und überspringt Skills deren `stacks`-Liste nicht matcht. Fehlendes Feld = gilt überall (safe default).

## Steps
- [ ] Step 1: Skill-Frontmatter-Schema dokumentieren in `templates/skills/README.md`: optionales `stacks:` Array, Werte identisch zu `stack_profile` aus Spec 638 + Special-Value `all`
- [ ] Step 2: `lib/boilerplate.sh` um Post-Download-Filter erweitern: für jeden Skill `awk`-Parse des Frontmatters, wenn `stacks:` Liste vorhanden und `stack_profile` nicht drin → Skill verwerfen (nicht kopieren)
- [ ] Step 3: `lib/setup-skills.sh` gleiche Filter-Logik bei lokalem Install-Path
- [ ] Step 4: Boilerplate-Skill-Files mit passenden `stacks:` Einträgen versehen — Aufgabe BRAUCHT Koordination mit Boilerplate-Repos. Diese Spec liefert nur den Reader + Migration-Doc, das Tagging wird pro Boilerplate-Repo separat committed
- [ ] Step 5: `--force-all-skills` Flag für Setup, wenn User bewusst alle Skills will (Edge-Case: Meta-Projekt, Multi-Stack-Monorepo)
- [ ] Step 6: Log-Output zeigt transparent welche Skills gefiltert wurden mit Stack-Grund ("Skipping storyblok-push-story: stacks=[nuxt-storyblok], profile=shopify-liquid")
- [ ] Step 7: `doctor.sh` Check: wenn Skill installiert aber frontmatter-stacks nicht matchend → Warning (Drift-Erkennung)
- [ ] Step 8: Smoke-Test in sp-alpensattel (Shopify) und nuxt-onedot (Nuxt): Skills-Liste je nach Profil unterschiedlich, keine Cross-Contamination

## Acceptance Criteria
- [ ] Skill mit `stacks: [shopify-liquid]` wird in sp-alpensattel installiert, in nuxt-onedot NICHT
- [ ] Skill ohne `stacks:` Feld wird überall installiert (Safe Default)
- [ ] `ai-setup --force-all-skills` installiert alle, unabhängig vom Profil
- [ ] Log enthält Zeilen wie `Skipping <skill>: stacks=[...], profile=<p>` für jeden gefilterten Skill
- [ ] `.claude/skills/` in Shopify-Target enthält keine `nuxt-*` oder `storyblok-*` Skills
- [ ] `bash .claude/scripts/doctor.sh` erkennt Mismatch (Skill aus anderem Profil noch lokal)
- [ ] `shellcheck lib/boilerplate.sh lib/setup-skills.sh` passt
- [ ] `bash .claude/scripts/quality-gate.sh` grün

## Files to Modify
- `lib/boilerplate.sh` — Frontmatter-Filter bei Pull
- `lib/setup-skills.sh` — gleiche Filter-Logik
- `ai-setup.sh` — `--force-all-skills` Flag-Handling
- `.claude/scripts/doctor.sh` — Drift-Check
- `templates/skills/README.md` — Schema-Doku
- `README.md` — Section "Skills Stack-Filter"

## Out of Scope
- Retagging der Skills in den Boilerplate-Repos (`onedot-digital-crew/*`) selbst — separate Commits dort, nicht Teil dieses Specs. Diese Spec liefert nur Reader + Migration-Guide.
- Dynamische Skills-Toggle während Session (nicht möglich ohne Restart)
- Skill-Deps untereinander (Skill A requires Skill B) — bleibt Out of Scope bis erkennbarer Bedarf

## Dependencies
- Hard-Dep auf Spec 638 (`stack_profile` Detection) — 642 kann erst nach 638
