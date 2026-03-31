# Spec 605: TDD Enforcement Hook (file_checker)

> **Status**: Draft
> **Source**: Brainstorm 604 (pilot-shell research)
> **Effort**: M
> **Value**: ★★★★

## Problem

Our `testing.md` rules mandate TDD, but nothing enforces them automatically. Claude can modify Python/TypeScript/Go files without test files and no warning fires. The issue is only caught in review, not at the point of edit.

## Solution

A PostToolUse Bash hook (`tdd-checker.sh`) that runs after Write/Edit/MultiEdit. It checks whether a corresponding test file exists for the modified code file. Non-blocking: issues a warning via stdout but does not block the tool.

## Trigger

`PostToolUse` — matcher: `Write|Edit|MultiEdit`

## Logic

```
file_path = tool_input.file_path
if file is a test file → skip
if file extension not in [.py, .ts, .tsx, .js, .jsx, .go] → skip
derive expected test path (language-specific patterns):
  Python: tests/test_<module>.py or <dir>/test_<name>.py
  TypeScript/JS: <base>.test.ts, <base>.spec.ts, __tests__/<name>.test.ts
  Go: <base>_test.go
if none of the expected paths exist:
  print warning (non-blocking, exit 0)
```

## Files to Create/Modify

- **Create**: `templates/claude/hooks/tdd-checker.sh`
- **Modify**: `templates/claude/settings.json` — add PostToolUse hook entry
- **Copy**: `templates/claude/hooks/tdd-checker.sh` → `.claude/hooks/tdd-checker.sh` (install_hooks handles this)

## Constraints

- Must complete in < 50ms — no API calls, no LLM
- Non-blocking (exit 0) — a warning, not a hard block
- Skip test files themselves
- Skip generated files (dist/, node_modules/, .next/, etc.)
- Use jq for JSON parsing (consistent with other hooks)

## Out of Scope

- Language-specific linting or test running
- Blocking the edit entirely
- Covering all languages (only Py/TS/JS/Go initially)

## Acceptance Criteria

- [ ] Hook exists in `templates/claude/hooks/tdd-checker.sh`
- [ ] Hook registered in `templates/claude/settings.json` PostToolUse
- [ ] Editing a .py file without test → warning printed
- [ ] Editing a test file → no output
- [ ] Editing a .md or .json file → no output
- [ ] Hook completes in < 50ms on typical files
