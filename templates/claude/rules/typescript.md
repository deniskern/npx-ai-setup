---
globs: ["**/*.ts", "**/*.tsx", "tsconfig.json", "tsconfig.*.json"]
---
# TypeScript Rules

## Strict Types
Enable and maintain `strict: true` in `tsconfig.json`.
Never disable strictness to silence errors — fix the types instead.

## No `any`
Do not use `any` unless wrapping third-party code with no types available.
If you must use `any`, add an inline comment explaining why: `// any: no types available for legacy-sdk`.
Prefer `unknown` over `any` when the type is genuinely unknown — it forces you to narrow before use.

## Prefer Type Inference
Let TypeScript infer types where the value is obvious:
```ts
// Good — type inferred as string[]
const names = items.map(i => i.name);

// Unnecessary annotation
const names: string[] = items.map(i => i.name);
```
Add explicit annotations at public API boundaries (function parameters, return types, exported constants).

## Use Existing Project Patterns
Before adding a new type, check `types/`, `@/types/`, or adjacent files for existing definitions.
Do not duplicate types that already exist elsewhere in the project.
Follow the naming conventions already in use (e.g., `PascalCase` for interfaces and types, `UPPER_SNAKE_CASE` for enums).

## Type Narrowing
Use type guards and narrowing instead of casting:
```ts
// Prefer narrowing
if (typeof value === "string") { ... }

// Avoid casting unless truly necessary
const name = value as string;
```

## Avoid Non-Null Assertions
Do not use `!` (non-null assertion) unless you have verified the value is never null at that point.
Prefer optional chaining (`?.`) and nullish coalescing (`??`) instead.
