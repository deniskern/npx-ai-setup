# Template-Größenanalyse: @onedot/ai-setup (Baseline, ohne Skill)

**124 Dateien, 708 KB gesamt**

## Befunde

**1. Shopify-Skills (~91 KB) im Paket für alle Nutzer**
Die 8 größten Einzeldateien sind Shopify-spezifische Skills (shopify-graphql-api: 14 KB, shopify-functions: 13,6 KB, shopify-liquid: 11,8 KB) — alle landen im npm-Tarball, auch für Django/Laravel/Rails-Projekte.

**2. Commands: alle 25 werden installiert, kein Stack-Check**
Für Nutzer ohne Spec-Workflow landen spec-work.md (11 KB), spec.md (9 KB), analyze.md, research.md, reflect.md unnötig im Projekt.

**3. Scripts: alle 16 installiert**
release.sh, spec-validate-prep.sh, scan-prep.sh kommen auch in Projekte ohne Release-Workflow.

**4. Agents: 12 Templates, davon nur 1 mit Stack-Check**

## Empfehlungen (nach Priorität)

| Priorität | Massnahme |
|-----------|-----------|
| Hoch | Shopify-Skills aus templates/skills/ entfernen — kommen per npx |
| Hoch | Commands aufteilen: core (immer) vs. spec-workflow (opt-in) |
| Mittel | Scripts mit Existenzcheck koppeln |
| Niedrig | WORKFLOW-GUIDE.md (9,4 KB) kürzen |
