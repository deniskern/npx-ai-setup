<!-- bundle: n8n v1 -->
---
abstract: "n8n workflow automation, self-hosted or cloud. JSON workflow definitions, webhook triggers, credential vault."
---

# Stack

## Runtime & Distribution
- n8n self-hosted (Docker/npm) or n8n.cloud
- Node.js 18+ (if self-hosted)
- Workflows stored as JSON; version via git export

## Framework & Dependencies
- n8n core nodes (HTTP Request, Code, Set, If, Merge)
- Trigger nodes: Webhook, Schedule, Manual
- Credential storage: n8n encrypted vault (never in workflow JSON)
- Optional custom nodes as npm packages in `~/.n8n/nodes/`

## Build & Tooling
- `n8n start` → local instance; `n8n export` / `n8n import` for version control
- No build step for built-in nodes
- Custom nodes: `npm run build` → compiled to `dist/`
