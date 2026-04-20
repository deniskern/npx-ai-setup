# Brainstorm: mcp-platform Auto-Suggest via Discovery-Endpoint

> **Brainstorm ID**: 640b | **Created**: 2026-04-19 | **Status**: deferred | **Blocked on**: mcp-platform `/api/projects` Endpoint

## Idee
Zielprojekte automatisch mit passenden mcp-platform Endpoints verkabeln (storyblok, shopify, plausible, google-ads, klaviyo) ohne Slug-Raten.

## Warum deferred
Ursprünglicher 640-Draft wollte aus `stack_profile` + Repo-Name einen Platform-Slug ableiten. Problem:
- Repo-Name `sp-alpensattel` ≠ Platform-Slug `alpensattel` ≠ Env `PROJ_ALPENSATTEL`
- Slugs existieren nur wenn serverseitig `PROJ_<SLUG>` gesetzt — Setup-Tool kann das nicht wissen ohne Platform-API-Query
- Falsche Slugs führen zu kaputten `.mcp.json`-Einträgen, die User im Onboarding verwirren

Ohne verlässliche Source-of-Truth bleibt es raten. Nicht akzeptabel.

## Vorbedingung für Spec-Promotion
`mcp-platform` muss einen **read-only Discovery-Endpoint** exposen:

```
GET /api/projects
Authorization: Bearer <token>
→ [
    { slug: "alpensattel", services: ["storyblok", "shopify", "klaviyo"], label: "Alpensattel" },
    { slug: "one_dot", services: ["storyblok", "plausible"], label: "ONEDOT" },
    ...
  ]
```

Dann kann `npx ai-setup`:
1. Token aus `~/.config/mcp-platform/token` oder env-var lesen
2. `/api/projects` fragen → echte Slug-Liste
3. User via AskUserQuestion aus echten Slugs wählen lassen (Freitext nur als Fallback)
4. `.mcp.json` mit garantiert funktionierendem Endpoint generieren

## Mögliche Folge-Arbeiten (nicht jetzt)
- mcp-platform: `/api/projects` Endpoint implementieren (server-side, mit Auth, read-only)
- mcp-platform: Rate-Limiting für Discovery
- npx-ai-setup: Spec schreiben (640b-real) wenn Endpoint live ist
- Dokumentation: "Hosted MCP Onboarding" Guide

## Alternative falls nie Discovery-Endpoint
- Statisches YAML-File `~/.config/onedot/projects.yml` das User manuell pflegt
- CLI-Command `ai-setup projects list/add/remove` um diese Datei zu managen
- Quality-niedriger als Server-API aber machbar

## Entscheidung
Erstmal nicht bauen. Wenn mcp-platform sowieso mal API-Rework kriegt, Discovery mitimplementieren. Bis dahin bleibt MCP-Konfiguration für hosted Services **manuell** und `npx ai-setup` schlägt nur kuratierte Standard-MCPs vor (Spec 640).
