---
name: ais:bash-defensive-patterns
model: haiku
description: "Master defensive Bash programming techniques for production-grade scripts. Use when writing robust shell scripts, CI/CD pipelines, or system utilities requiring fault tolerance and safety."
---

# Bash Defensive Patterns

## When to Use

- Writing production automation or CI/CD scripts
- Scripts that must handle errors, edge cases, and cleanup safely
- System utilities requiring idempotency and fault tolerance

## Core Patterns

**Strict mode** — always first line after shebang: `set -Eeuo pipefail`
- `-E` inherits ERR trap in functions, `-e` exits on error, `-u` exits on unset var, `-o pipefail` fails pipe on any stage

**Error trapping & cleanup:**
- `trap 'echo "Error on line $LINENO"' ERR`
- `trap 'rm -rf -- "$TMPDIR"' EXIT` combined with `TMPDIR=$(mktemp -d)`
- Signal handling: `trap cleanup SIGTERM SIGINT`

**Atomic writes:** write to `mktemp`, then `mv` to target — never write directly

**Null-byte safe iteration:** `while IFS= read -r -d '' file; do ...; done < <(find ... -print0)` — process substitution keeps variables in scope (pipe creates subshell)

**Arrays:** `mapfile -t lines < <(cmd)` — never use unquoted `$array`, always `"${items[@]}"`

**Dry-run:** `if [[ "$DRY_RUN" == "true" ]]; then echo "[DRY RUN] $*"; return 0; fi`

**Dependency checks:** `command -v` (not `which`) — `command -v jq &>/dev/null || { echo "jq required" >&2; exit 1; }`

**Logging:** `echo "[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $*" >&2` — always to stderr, levels: INFO/WARN/ERROR/DEBUG

**Variable safety:** quote everything `"$var"`, use `[[ -n "${VAR:-}" ]]`, required vars: `: "${REQUIRED:?not set}"`

**Arg parsing:** `while [[ $# -gt 0 ]]; do case "$1" in -v|--verbose) ...` with defaults declared at top

**Script directory (non-obvious):**
```bash
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
```

**Process orchestration with signals:**
```bash
PIDS=()
trap 'for p in "${PIDS[@]}"; do kill -0 "$p" 2>/dev/null && kill -TERM "$p"; done; wait' SIGTERM SIGINT
background_task & PIDS+=($!)
```

**Dependency check loop:**
```bash
missing=(); required=("jq" "curl" "git")
for cmd in "${required[@]}"; do command -v "$cmd" &>/dev/null || missing+=("$cmd"); done
[[ ${#missing[@]} -eq 0 ]] || { echo "Missing: ${missing[*]}" >&2; exit 1; }
```

## Key Rules

- `[[ ]]` over `[ ]` for Bash conditionals
- `local -r` for function-scoped read-only vars
- Functions prefix: `handle_*`, `process_*`, `check_*`, `validate_*`
- Design for idempotency — `ensure_directory()` style guards
