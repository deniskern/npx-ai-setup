---
abstract: "POSIX sh style, snake_case, quoted expansions, local scoping, fail-fast, templates copied verbatim in English"
sections:
  - "Bash Style: POSIX sh compatible, snake_case vars/functions, UPPER constants, quoted expansions"
  - "Function Structure: doc comments, local args, || return 1, explicit return"
  - "Error Handling: set -e in scripts, no silent failures, descriptive error messages"
  - "Template Conventions: copied verbatim, no generation, English only, idempotent"
  - "Testing & Done: smoke tests, shellcheck, quoting verified, idempotency verified"
---

# Conventions

## Bash Style & Naming
- **Language:** POSIX sh compatible; avoid bashisms (arrays, =~, declare -A)
- **Variables:** snake_case for all variables and functions
- **Constants:** UPPERCASE_WITH_UNDERSCORES for constants
- **Quoting:** Always quote expansions: `"$var"`, `"${var}"`, `"$@"`
- **Scoping:** Use `local` for all function-scoped variables
- **Shebangs:** `#!/bin/bash` for executable scripts

## Function Structure
```bash
# Doc comment with purpose, args, return
function_name() {
  local arg1="$1"
  local arg2="${2:-default}"
  
  # Logic
  command || return 1
  
  # Return value or exit
  echo "result"
}
```

## Error Handling
- Fail fast: `set -e` in scripts, `|| return 1` in functions
- No silent failures: log errors before returning
- Explicit exit codes: `return 1` for failure, `return 0` for success
- Error messages: what failed, why, and (if possible) how to fix

## Template Conventions
- **Copied verbatim:** Templates in templates/ are deterministic, reviewed, versioned
- **No generation inside templates:** Use generation logic in bin/ai-setup.sh instead
- **Language:** All generated content in English (no umlauts, non-ASCII)
- **Idempotency:** Template installation must be safe to run multiple times

## File & Path Conventions
- Check before creating: use Glob/Bash to verify file doesn't exist first
- Idempotent operations: never silently clobber existing user files
- User approval gates: major destructive ops (rm -rf) require explicit gates
- Module sourcing: `source_lib "module.sh"` instead of relative paths

## Testing
- Smoke tests in tests/smoke.sh verify core functionality
- Test new features in smoke.sh before marking done
- No unit testing framework (bash limitations); functional tests only

## Definition of Done

### Bash Scripts
- [ ] Shellcheck passes (no warnings or errors)
- [ ] Quoting verified (`"$var"` not $var)
- [ ] Functions use `local` for all scoped variables
- [ ] Error cases return explicit exit codes (1 on failure, 0 on success)
- [ ] No hardcoded paths; use $SCRIPT_DIR or passed arguments

### Templates
- [ ] Copied to templates/ from reference implementation
- [ ] No project-specific content (only generic/parameterizable)
- [ ] Verified copy produces expected output in target project
- [ ] Language: English only

### Features
- [ ] Smoke tests pass (`bash tests/smoke.sh`)
- [ ] Idempotency verified (run twice, same outcome)
- [ ] Git workflow: spec created, changes committed, reviewed

### Context Files
- [ ] STACK.md: runtime, dependencies, build tooling, patterns
- [ ] ARCHITECTURE.md: project type, directory structure, data flow
- [ ] CONVENTIONS.md: naming, style, error handling, done criteria
