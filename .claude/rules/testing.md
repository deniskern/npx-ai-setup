---
paths:
  - "**/*.test.*"
  - "**/*.spec.*"
  - "**/tests/**"
  - "**/__tests__/**"
  - "**/*.test.sh"
---

# Testing Rules

## Test First
Write tests before or alongside implementation — never after the fact as an afterthought.
When fixing a bug, write a failing test that reproduces it first, then fix the code.

## Assertion Expectations
Assert the specific value, not just that something is truthy.
Prefer `expect(result).toBe(42)` over `expect(result).toBeTruthy()`.
Include the expected value in assertion messages to aid debugging.

## Edge Case Coverage
Every function must cover: empty input, null/undefined, boundary values, and error paths.
Do not only test the happy path — edge cases are where bugs live.

## No Mocks by Default
Prefer real implementations over mocks.
Only mock: network calls, external services, file system side effects, and time-dependent behavior.
When mocking, document why a real implementation could not be used.

## Isolation
Each test must be fully independent — no shared mutable state between tests.
Reset all side effects in `afterEach` / `teardown` blocks.
Tests must pass in any order and when run in isolation.

## Test Naming
Use descriptive names that explain the scenario and expected outcome:
`it("returns null when the user ID does not exist")` not `it("works correctly")`.
