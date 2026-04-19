<!-- bundle: n8n v1 -->
---
abstract: "n8n conventions: workflow names as [System] Action, descriptive node names, pin test data, no hardcoded secrets."
---

# Conventions

## Naming
- Workflow names: `[System] Action Description` (`[Shopify] New Order to Slack`)
- Node names: describe the action, not the node type
  - Good: `Get Customer by Email`, `Send Order Confirmation`
  - Bad: `HTTP Request`, `Set`, `Function`
- Credential names: `ServiceName (environment)` (`Shopify (production)`)

## Workflow Design
- One trigger per workflow — split multi-trigger logic into sub-workflows
- Always connect the error output or set an error workflow in settings
- Use Set node to normalize data shape early in the flow
- Sub-workflows via Execute Workflow node — pass minimal required data

## Testing
- Pin test data on trigger and key nodes before building downstream logic
- Test with sample payloads before connecting to production credentials
- Verify error branch fires correctly with a forced failure test

## Definition of Done
- [ ] Execution succeeds end-to-end with real or pinned test data
- [ ] Error branch is handled (error output connected or error workflow set)
- [ ] No hardcoded secrets in node parameters
- [ ] Workflow exported to JSON and committed to version control
