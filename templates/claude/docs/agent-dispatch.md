# Agent Dispatch Table

Full agent delegation reference. See `.claude/rules/agents.md` for model routing rules and delegation criteria.

## When to Delegate

Use agents for focused, isolated work. Call them directly — do not ask the user first.

| Agent | Trigger | Model | Scope |
|-------|---------|-------|-------|
| build-validator | After code changes, before marking work done | haiku | universal |
| code-reviewer | After completing a spec or feature branch | sonnet | universal |
| code-architect | Before implementing high-complexity specs or multi-system changes | opus | universal |
| context-refresher | When stack, architecture, or conventions have changed | haiku | universal |
| performance-reviewer | After changes to hot paths, loops, data fetching, or bundle-affecting code | sonnet | universal |
| staff-reviewer | Final review before merging significant changes | opus | universal |
| test-generator | After adding new functions or modules that lack test coverage | sonnet | universal |
| verify-app | After spec completion to validate tests, build, and functionality | haiku | universal |
| security-reviewer | Before merging auth changes, user input handling, or after dependency updates | sonnet | universal |
| frontend-developer | When building/refactoring UI components, accessibility audits | sonnet | conditional |
| backend-developer | When building API routes, server middleware, or third-party integrations | sonnet | conditional |
| liquid-linter | After editing Liquid templates in Shopify projects | haiku | boilerplate |
| shopware-reviewer | After PHP/Twig changes in Shopware projects | haiku | boilerplate |
| storyblok-reviewer | After Storyblok component schema or Vue integration changes | haiku | boilerplate |

## When NOT to Delegate

- Single-file reads or searches — use Read/Glob/Grep directly
- Trivial fixes (typos, config tweaks) — faster to do inline
- Tasks requiring fewer than 3 tool calls — agent startup overhead exceeds the work
- Follow-up edits after a review — apply fixes yourself, do not re-delegate

## Agent Scopes

- **universal**: Installed globally (~/.claude/agents/) and per-project. Available everywhere.
- **conditional**: Installed per-project only when stack matches (e.g. frontend framework detected).
- **boilerplate**: Installed from stack-specific boilerplate repos (e.g. sp-shopify-boilerplate).

## Scope Limits

- Agents report findings — they do not fix issues unless their description says otherwise
- `test-generator` writes tests only; it does not modify source code
- `code-architect` and `staff-reviewer` run in plan mode — they cannot edit files
- `build-validator` runs commands but does not write code
