---
id: 587
title: Template Domain-Skills optionale Install-Gruppen
status: draft
priority: medium
created: 2026-03-25
---

# Spec 587 — Template Domain-Skills optionale Install-Gruppen

## Problem

15 von 30 Template-Skills sind domänenspezifisch (Shopify, Shopware, Framework-spezifisch), laden aber bei allen Installationen. Token-Overhead: ~1.500 Token/Session für User ohne diese Domains. Template-Setup verursacht 6.920 Token/Message vs. 4.948 im Projekt (+40%).

## Goal

Domain-spezifische Skills nur dann installieren, wenn der User den passenden Stack auswählt. Core-Skills für alle, Domain-Skills optional per Selektor.

## Acceptance Criteria

- [ ] `templates/skills/` in `core/` und Domain-Gruppen aufgeteilt (z.B. `shopify/`, `shopware/`)
- [ ] `lib/install.sh` fragt nach Stack-Auswahl und kopiert nur relevante Skills
- [ ] User ohne Shopify/Shopware bekommt ~1.500 Token weniger overhead
- [ ] Bestehende Installationen nicht gebrochen (Migration-Hinweis in CHANGELOG)

## Out of Scope

- Neue Skills erstellen
- Skill-Inhalte ändern
- Non-skill Template-Dateien anfassen

## Files

- `templates/skills/` — Verzeichnisstruktur umbauen
- `lib/install.sh` — Stack-Selektor ergänzen
- `CHANGELOG.md`

## Notes

Audit-Daten: `outputs/audit/templates.md` (generiert 2026-03-24).
Domain-Skills identifizieren via: `ls templates/skills/` + Keyword-Check auf Shopify/Shopware in SKILL.md.
