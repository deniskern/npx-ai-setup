<!-- bundle: n8n v1 -->
---
abstract: "n8n workflow JSON: nodes array + connections map. Triggers → processors → outputs. Credentials referenced by ID."
---

# Architecture

## Workflow JSON Structure
- `nodes` array: each node has `id`, `name`, `type`, `parameters`, `position`
- `connections` object: maps output handles to downstream node inputs
- `settings`: error workflow, timezone, save preferences
- `staticData`: pinned test data for deterministic dev runs

## Node Categories
- **Triggers**: Webhook (HTTP in), Schedule (cron), Manual (dev), App events (Slack, etc.)
- **Processing**: Set (transform data), Code (JS/Python), If (branch), Merge, Loop Over Items
- **Outputs**: HTTP Request (call APIs), Send Email, Slack, database nodes

## Credential Pattern
- Credentials stored in n8n vault, referenced by `{ id, name }` in node parameters
- Never embed secrets in workflow JSON — they appear in git history
- Each environment (dev/prod) has separate credential records

## Key Patterns
- Error handling: connect "Error" output or set error workflow in settings
- Sub-workflows: Execute Workflow node with `workflowId` parameter
- Pinned data: right-click node → "Pin Data" for reproducible test runs
