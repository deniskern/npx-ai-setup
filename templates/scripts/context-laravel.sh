#!/bin/bash
# context-laravel.sh — Laravel project context scanner
# Generates .agents/context/LARAVEL.md with zero LLM tokens.
# Run: bash .claude/scripts/context-laravel.sh
# Triggered by: /context-refresh skill when artisan is detected

set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$PWD}"
OUTPUT="$PROJECT_DIR/.agents/context/LARAVEL.md"

# --- Laravel version ---
laravel_version=""
if [ -f "$PROJECT_DIR/composer.json" ] && command -v python3 >/dev/null 2>&1; then
  laravel_version=$(python3 -c "
import json
with open('$PROJECT_DIR/composer.json') as f:
  d = json.load(f)
print(d.get('require', {}).get('laravel/framework', ''))
" 2>/dev/null || echo "")
fi

# --- Routes ---
route_count_web=$(grep -c "^Route::" "$PROJECT_DIR/routes/web.php" 2>/dev/null || echo 0)
route_count_api=$(grep -c "^Route::" "$PROJECT_DIR/routes/api.php" 2>/dev/null || echo 0)
extra_routes=$(find "$PROJECT_DIR/routes" -name "*.php" 2>/dev/null \
  | xargs -I{} basename {} .php | grep -vE "^(web|api|console|channels)$" | sort | tr '\n' ',' | sed 's/,$//')

# --- Controllers ---
controller_count=$(find "$PROJECT_DIR/app/Http/Controllers" -name "*.php" 2>/dev/null | wc -l | tr -d ' ')
controllers=$(find "$PROJECT_DIR/app/Http/Controllers" -maxdepth 1 -name "*.php" 2>/dev/null \
  | xargs -I{} basename {} .php | grep -v "^Controller$" | sort | tr '\n' ',' | sed 's/,$//')

# --- Models ---
models=$(find "$PROJECT_DIR/app/Models" -name "*.php" 2>/dev/null \
  | xargs -I{} basename {} .php | sort | tr '\n' ',' | sed 's/,$//')
model_count=$(echo "$models" | tr ',' '\n' | grep -c . 2>/dev/null || echo 0)

# --- Actions / Services / Jobs ---
action_count=$(find "$PROJECT_DIR/app/Actions" -name "*.php" 2>/dev/null | wc -l | tr -d ' ')
service_count=$(find "$PROJECT_DIR/app/Services" -name "*.php" 2>/dev/null | wc -l | tr -d ' ')
job_count=$(find "$PROJECT_DIR/app/Jobs" -name "*.php" 2>/dev/null | wc -l | tr -d ' ')

# --- Views ---
view_count=$(find "$PROJECT_DIR/resources/views" -name "*.blade.php" 2>/dev/null | wc -l | tr -d ' ')
view_dirs=$(find "$PROJECT_DIR/resources/views" -mindepth 1 -maxdepth 1 -type d 2>/dev/null \
  | xargs -I{} basename {} | sort | tr '\n' ',' | sed 's/,$//')

# --- Key .env variables ---
env_keys=""
if [ -f "$PROJECT_DIR/.env.example" ]; then
  env_keys=$(grep -E "^[A-Z_]+=." "$PROJECT_DIR/.env.example" 2>/dev/null \
    | cut -d= -f1 | grep -vE "^(APP_NAME|APP_ENV|APP_KEY|APP_DEBUG|APP_URL|LOG_CHANNEL|DB_CONNECTION|DB_HOST|DB_PORT|DB_DATABASE|DB_USERNAME|DB_PASSWORD|CACHE_DRIVER|SESSION_DRIVER|QUEUE_CONNECTION|REDIS_HOST|MAIL_MAILER|MAIL_HOST|MAIL_PORT|MAIL_FROM_ADDRESS|BROADCAST_DRIVER)$" \
    | sort | tr '\n' ',' | sed 's/,$//')
fi

# --- Build abstract ---
abstract="Laravel${laravel_version:+ ${laravel_version}}: ${model_count} models | ${controller_count} controllers | web: ${route_count_web} + api: ${route_count_api} routes | ${view_count} views${action_count:+ | ${action_count} actions}${service_count:+ | ${service_count} services}"

# --- Write output ---
mkdir -p "$(dirname "$OUTPUT")"
cat > "$OUTPUT" << LARAVEL_EOF
---
abstract: "${abstract}"
---

# Laravel Project Context
${laravel_version:+Version: ${laravel_version}}

## Models (${model_count})
${models:-none}

## Controllers (${controller_count})
${controllers:-none}
${controller_count:+Sub-namespaces: see app/Http/Controllers/ subdirs}

## Routes
web.php: ${route_count_web} routes | api.php: ${route_count_api} routes
${extra_routes:+Extra route files: ${extra_routes}}

## Views (${view_count})
${view_dirs:+Dirs: ${view_dirs}}
${action_count:+
## Actions (${action_count})
See app/Actions/}
${service_count:+
## Services (${service_count})
See app/Services/}
${job_count:+
## Jobs (${job_count})
See app/Jobs/}
${env_keys:+
## Non-Standard .env Keys
${env_keys}}
LARAVEL_EOF

echo "✓ LARAVEL.md written to $OUTPUT"
wc -l < "$OUTPUT" | xargs -I{} echo "  {} lines"
