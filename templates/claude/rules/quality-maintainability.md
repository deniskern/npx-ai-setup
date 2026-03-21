# Quality: Maintainability Principles

## Structure
- Single Responsibility: each function/module does one thing
- DRY: extract repeated logic; do not copy-paste with minor variations
- Keep functions short enough to fit in one screen — split if they exceed ~40 lines

## Naming
- Names reveal intent: prefer `getUserByEmail` over `getUser` or `fetch`
- No magic numbers or strings — use named constants with explanatory names
- Boolean variables and parameters use `is`, `has`, `should` prefixes

## Error Handling
- Handle errors explicitly at the layer that can act on them
- Error messages include what failed, why, and (if possible) how to fix it
- Do not log and re-throw the same error — pick one

## Testability
- Prefer pure functions: same input → same output, no hidden side effects
- Inject dependencies rather than hard-coding them — makes mocking trivial
