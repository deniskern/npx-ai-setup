#!/bin/bash
# AI generation: CLAUDE.md extension, context generation, skill discovery
# Requires: core.sh, process.sh, detect.sh, skills.sh
# Requires: $SYSTEM, $TEMPLATE_MAP, $SHOPIFY_SKILLS_MAP, $REGEN_*

# Gather Shopware-specific context for Claude prompts.
# Sets: CTX_SHOPWARE, SHOPWARE_INSTRUCTION, SHOPWARE_RULE
gather_shopware_context() {
  CTX_SHOPWARE=""
  SHOPWARE_INSTRUCTION=""
  SHOPWARE_RULE=""

  [ "$SYSTEM" != "shopware" ] && return 0

  # Read composer.json
  local composer_content
  composer_content=$(cat composer.json 2>/dev/null || echo "")

  # Extract Shopware plugins from composer require
  local composer_plugins
  composer_plugins=$(jq -r '
    (.require // {}) + (.["require-dev"] // {}) | to_entries[]
    | select(.key | startswith("store.shopware.com/") or startswith("swag/") or startswith("shopware/"))
    | "\(.key): \(.value)"
  ' composer.json 2>/dev/null || echo "none")

  # Scan custom/ subdirectories for plugins and apps
  local custom_plugins="none"
  local custom_apps="none"
  if [ -d "custom/static-plugins" ]; then
    custom_plugins=$(ls -1 custom/static-plugins/ 2>/dev/null)
    [ -z "$custom_plugins" ] && custom_plugins="none"
  elif [ -d "custom/plugins" ]; then
    custom_plugins=$(ls -1 custom/plugins/ 2>/dev/null)
    [ -z "$custom_plugins" ] && custom_plugins="none"
  fi
  if [ -d "custom/apps" ]; then
    custom_apps=$(ls -1 custom/apps/ 2>/dev/null)
    [ -z "$custom_apps" ] && custom_apps="none"
  fi

  # Check for deployment overrides (patched vendor packages)
  local deploy_overrides="none"
  if [ -d "deployment-overrides" ]; then
    deploy_overrides=$(find deployment-overrides -maxdepth 3 -type d 2>/dev/null | head -20)
    [ -z "$deploy_overrides" ] && deploy_overrides="none"
  fi

  CTX_SHOPWARE="--- composer.json ---
$composer_content
--- Shopware plugins (composer) ---
$composer_plugins
--- Custom plugins (filesystem) ---
$custom_plugins
--- Custom apps (filesystem) ---
$custom_apps
--- Deployment overrides ---
$deploy_overrides
--- Shopware project type ---
$SHOPWARE_TYPE"

  # System-specific instructions for context generation (Step 2)
  if [ "$SHOPWARE_TYPE" = "shop" ]; then
    SHOPWARE_INSTRUCTION="
This is a Shopware 6 full shop installation.

Shopware 6 directory structure:
  bin/              - CLI (bin/console)
  config/           - Symfony/Shopware config (packages/shopware.yaml, services.yaml)
  custom/           - Plugins and apps
    static-plugins/ - Developer-managed plugins, committed to Git (YOUR WORKING AREA)
      MeinPlugin/
        src/
          MeinPlugin.php       - Plugin base class
          Controller/
          Service/
          Entity/
          Migration/           - DB migrations
          Resources/
            config/services.xml - Dependency Injection
            config/routes.xml
            views/             - Twig templates
            public/            - Assets (JS, CSS)
        composer.json
    plugins/        - Plugins installed via Shopware Admin UI (DO NOT MODIFY)
    apps/           - Shopware Apps (lightweight)
  public/           - Web root (index.php, compiled assets)
  src/              - Project-level PHP overrides (Controllers etc.)
  var/              - Cache, logs, temporary files
  vendor/           - Composer dependencies
  deployment-overrides/ - Patched vendor files (DO NOT MODIFY)

In ARCHITECTURE.md, include a 'Working Scope' section:
- Allowed working directories: custom/static-plugins/, config/
- READ-ONLY: vendor/, public/, var/, bin/, files/ (managed by Shopware/Composer)
- NEVER TOUCH: custom/plugins/ (managed by Shopware Admin), deployment-overrides/ (managed by deployment pipeline)
- List installed custom plugins and apps from custom/ and their paths
- Core Shopware code in vendor/shopware/ must NEVER be modified"

    SHOPWARE_RULE="
Add a 'Shopware 6' section under Critical Rules:
- DAL-First: Always use EntityRepository -- never raw DBAL/SQL queries
- Service-Container: Business logic belongs in Services, registered in
  src/Resources/config/services.xml using Constructor Injection only
- Migrations: SQL migrations go in src/Migration/ and must be idempotent
- Criteria Performance: Add only required associations -- avoid over-fetching
- Code Style: PSR-12, strict_types=1 declarations in every PHP file
- Admin: Vue.js 3 + Shopware meteor-component-library for Admin extensions
- Cache: Always run bin/console cache:clear after config/container changes
- Only modify files in custom/static-plugins/ and config/
- Never modify custom/plugins/ (admin-managed), vendor/, public/, var/, deployment-overrides/, or core Shopware files
- Use Shopware plugin hooks and decorators for customization
- Plugin structure: src/ (PHP), Resources/config/ (DI, routes), Resources/views/ (Twig), Resources/public/ (assets)
- Run bin/console commands for cache clear, plugin lifecycle

Also add a 'MCP Servers' section to CLAUDE.md:
## MCP Servers
### shopware-admin-mcp
Configured in .mcp.json -- provides direct access to the Shopware Admin API.

Use it when you need to:
- Inspect live entity data (products, orders, customers, categories, properties)
- Look up field names, associations, or entity schemas before writing DAL code
- Verify that a plugin's data changes actually persisted correctly
- Create or update entities to set up test fixtures or seed data
- Debug data issues without writing a one-off console command

Do NOT use it for:
- Code generation or file edits (use standard tools)
- Tasks that only touch the local codebase with no data dependency"
  else
    SHOPWARE_RULE="
Add a 'Shopware 6 Plugin' section under Critical Rules:
- DAL-First: Always use EntityRepository -- never raw DBAL/SQL queries
- Service-Container: Logic in Services, registered in src/Resources/config/services.xml
  using Constructor Injection; never use service locator pattern
- Migrations: SQL migrations in src/Migration/ -- must be idempotent (CREATE TABLE IF NOT EXISTS)
- Subscribers: New event subscribers need both the PHP class AND the XML service tag
  (shopware.event.subscriber) in services.xml
- Controllers: Use Symfony routing attributes/annotations with correct RouteScope
- Tests: Integration tests extend KernelTestBase; unit tests are plain PHPUnit
- Criteria Performance: Minimize associations -- only add what the use-case requires
- Code Style: PSR-12 standards, strict_types=1, typed properties

Also add a 'MCP Servers' section to CLAUDE.md:
## MCP Servers
### shopware-admin-mcp
Configured in .mcp.json -- provides direct access to the Shopware Admin API of the target shop.

Use it when you need to:
- Inspect live entity data (products, orders, customers, categories, properties)
- Look up field names, associations, or entity schemas before writing DAL code
- Verify that the plugin's data changes actually persisted correctly in the shop
- Create or update entities to set up test fixtures or reproduce a bug
- Debug data issues without writing a one-off console command

Do NOT use it for:
- Code generation or file edits (use standard tools)
- Tasks that only touch the local plugin codebase with no data dependency"

    SHOPWARE_INSTRUCTION="
This is a standalone Shopware 6 plugin project.
Stack: Shopware 6.6+, Symfony 7.x, Vue.js 3, PHP 8.3+.

Standard Shopware plugin structure:
  src/
    PluginName.php       - Plugin base class (extends Plugin)
    Controller/          - Storefront/API controllers
    Service/             - Business logic services
    Entity/              - Custom entities (ORM)
    Migration/           - Database migrations
    Subscriber/          - Event subscribers
    Resources/
      config/
        services.xml     - Dependency Injection definitions
        routes.xml       - Route definitions
      views/             - Twig templates (storefront, admin)
      public/            - Static assets (JS, CSS, images)
  tests/                 - PHPUnit tests
  composer.json          - Plugin metadata and dependencies

In ARCHITECTURE.md, include:
- Plugin namespace and bootstrap class location (src/*Plugin.php or src/*Bundle.php)
- Standard directory conventions as above
- Key patterns: DAL (EntityRepository for all DB access), Services (DI container),
  Subscribers (event-driven hooks), Admin Extensions (Vue.js 3 components)
- This plugin installs into a Shopware 6 shop via Composer"
  fi
}

setup_shopware_mcp() {
  [ "$SYSTEM" != "shopware" ] && return 0

  # Ensure .mcp.json exists
  [ -f ".mcp.json" ] || echo '{"mcpServers":{}}' > .mcp.json

  # Warn if an existing server stores credentials in a git-tracked file
  if jq -e '(.mcpServers["shopware-admin-mcp"].env.SHOPWARE_API_CLIENT_ID? != null) or (.mcpServers["shopware-admin-mcp"].env.SHOPWARE_API_CLIENT_SECRET? != null)' .mcp.json >/dev/null 2>&1; then
    echo "  ⚠️  shopware-admin-mcp credentials found in .mcp.json."
    echo "     Move secrets to local shell env vars (do not commit credentials)."
  fi

  # Idempotency: skip if already configured
  if jq -e '.mcpServers["shopware-admin-mcp"]' .mcp.json >/dev/null 2>&1; then
    return 0
  fi

  echo ""
  echo "Shopware Admin MCP"
  echo "   Gives Claude direct access to the Shopware Admin API."

  # Try to read APP_URL from .env early (needed for the integration link)
  local ENV_URL=""
  if [ -f ".env" ]; then
    ENV_URL=$(grep -E '^APP_URL=' .env | cut -d= -f2- | tr -d '"' | tr -d "'")
  fi

  if [ -n "$ENV_URL" ]; then
    echo "   Create an integration at: ${ENV_URL}/admin#/sw/integration/index"
  fi

  read -r -p "   Set up Shopware Admin MCP? [y/N]: " SETUP_MCP
  if [ "$SETUP_MCP" != "y" ] && [ "$SETUP_MCP" != "Y" ]; then
    echo "   Skipped."
    return 0
  fi
  echo ""

  if [ -n "$ENV_URL" ]; then
    echo "   Found APP_URL in .env: $ENV_URL"
    read -r -p "   Use this URL? [Y/n]: " USE_ENV
    if [ -z "$USE_ENV" ] || [ "$USE_ENV" = "y" ] || [ "$USE_ENV" = "Y" ]; then
      SW_URL="$ENV_URL"
    else
      read -r -p "   Shop URL (optional, e.g. https://your-shop.com): " SW_URL
    fi
  else
    read -r -p "   Shop URL (optional, e.g. https://your-shop.com): " SW_URL
  fi

  local TMP_MCP
  TMP_MCP=$(mktemp)
  if [ -n "$SW_URL" ]; then
    jq --arg url "$SW_URL" \
      '.mcpServers["shopware-admin-mcp"] = {
        "command": "npx",
        "args": ["-y", "@shopware-ag/admin-mcp"],
        "env": {
          "SHOPWARE_API_URL": $url
        }
      }' .mcp.json > "$TMP_MCP" && mv "$TMP_MCP" .mcp.json
  else
    jq \
      '.mcpServers["shopware-admin-mcp"] = {
        "command": "npx",
        "args": ["-y", "@shopware-ag/admin-mcp"]
      }' .mcp.json > "$TMP_MCP" && mv "$TMP_MCP" .mcp.json
  fi

  echo "   shopware-admin-mcp added to .mcp.json"
  echo "   ℹ️  Set credentials locally before starting Claude Code:"
  echo "      export SHOPWARE_API_CLIENT_ID=..."
  echo "      export SHOPWARE_API_CLIENT_SECRET=..."
  if [ -z "$SW_URL" ]; then
    echo "      export SHOPWARE_API_URL=https://your-shop.com"
  fi
}

# Count generated context files in .agents/context/.
count_generated_context_files() {
  local count=0
  [ -f .agents/context/STACK.md ] && count=$((count + 1))
  [ -f .agents/context/ARCHITECTURE.md ] && count=$((count + 1))
  [ -f .agents/context/CONVENTIONS.md ] && count=$((count + 1))
  echo "$count"
}

# Main generation orchestrator
# Called by both normal setup (Auto-Init) and --regenerate mode.
# Requires: $SYSTEM is set, claude CLI is available
# Sets: $INSTALLED (number of skills installed)
run_generation() {
  # Disable errexit — background processes, wait, and command substitutions
  # cause silent exits with set -e (especially bash 3.2 on macOS).
  # This function has comprehensive error handling for all steps.
  set +e
  local regen_failed=0

  # Default: regenerate everything unless flags were explicitly set by ask_regen_parts
  : "${REGEN_CLAUDE_MD:=yes}"
  : "${REGEN_AGENTS_MD:=${REGEN_CLAUDE_MD}}"
  : "${REGEN_CONTEXT:=yes}"
  : "${REGEN_COMMANDS:=yes}"
  : "${REGEN_AGENTS:=${REGEN_COMMANDS}}"
  : "${REGEN_SKILLS:=yes}"

  # Keep a single canonical skills directory and expose it under .agents/skills as alias.
  if command -v ensure_skills_alias >/dev/null 2>&1; then
    ensure_skills_alias
  fi

  local regen_ai_context="no"
  if [ "$REGEN_CLAUDE_MD" = "yes" ] || [ "$REGEN_AGENTS_MD" = "yes" ] || [ "$REGEN_CONTEXT" = "yes" ]; then
    regen_ai_context="yes"
  fi

  # Re-deploy slash commands and/or agent templates from package templates.
  if [ "$REGEN_COMMANDS" = "yes" ] || [ "$REGEN_AGENTS" = "yes" ]; then
    echo "📋 Updating command and agent templates..."
    local cmd_updated=0
    for mapping in "${TEMPLATE_MAP[@]}"; do
      local tpl="${mapping%%:*}"
      local target="${mapping#*:}"
      if { [[ "$tpl" == templates/commands/* ]] && [ "$REGEN_COMMANDS" = "yes" ]; } \
        || { [[ "$tpl" == templates/agents/* ]] && [ "$REGEN_AGENTS" = "yes" ]; }; then
        if [ -f "$SCRIPT_DIR/$tpl" ]; then
          mkdir -p "$(dirname "$target")"
          cp "$SCRIPT_DIR/$tpl" "$target"
          cmd_updated=$((cmd_updated + 1))
        fi
      fi
    done
    echo "  ✅ $cmd_updated file(s) updated"
  fi

  if [ "$regen_ai_context" = "yes" ]; then
    echo "🚀 Generating project context (System: $SYSTEM)..."

    # Detect Shopware sub-type and gather system-specific context
    detect_shopware_type
    if [ -n "$SHOPWARE_TYPE" ]; then
      echo "  Shopware type: $SHOPWARE_TYPE"
    fi
    gather_shopware_context
    setup_shopware_mcp

    # Cache file list once (avoid running collect_project_files 3x)
    CACHED_FILES=$(collect_project_files 80)

    # Gather all context upfront
    CONTEXT="--- package.json ---
$(cat package.json 2>/dev/null)
--- package.json scripts ---
$(jq -r '.scripts | to_entries[] | "- \(.key): \(.value)"' package.json 2>/dev/null)
--- Directory structure (max 80 files) ---
$CACHED_FILES
--- ESLint Config ---
$(cat eslint.config.* .eslintrc* 2>/dev/null | head -100)
--- Prettier Config ---
$(cat .prettierrc* 2>/dev/null)
--- CLAUDE.md (current) ---
$(cat CLAUDE.md 2>/dev/null)
--- AGENTS.md (current) ---
$(cat AGENTS.md 2>/dev/null)"

    # Sanitize CONTEXT: replace backticks with single quotes to prevent heredoc command substitution
    CONTEXT=$(printf '%s' "$CONTEXT" | tr '`' "'")

    # Extended context for project context generation
    CTX_PKG=$(cat package.json 2>/dev/null || echo "No package.json")
    CTX_TSCONFIG=$(cat tsconfig.*.json 2>/dev/null; [ -f tsconfig.json ] && cat tsconfig.json 2>/dev/null || echo "No tsconfig")
    CTX_TSCONFIG=$(echo "$CTX_TSCONFIG" | head -80)
    CTX_DIRS=$(find . -maxdepth 3 -type d \
      \( -name node_modules -o -name .git -o -name dist -o -name build \
         -o -name .next -o -name vendor -o -name .nuxt -o -name .output \) -prune -o \
      -type d -print 2>/dev/null | head -60)
    CTX_FILES="$CACHED_FILES"
    CTX_CONFIGS=$(ls -1 *.config.* .eslintrc* .prettierrc* tailwind.config.* \
      vite.config.* nuxt.config.* next.config.* astro.config.* \
      webpack.config.* rollup.config.* docker-compose* Dockerfile \
      Makefile Cargo.toml go.mod requirements.txt pyproject.toml \
      biome.json 2>/dev/null || echo "No config files found")
    CTX_README=$(head -50 README.md 2>/dev/null || echo "No README")

    # Sample source files (generic: first 3 project files)
    CTX_SAMPLE=""
    for f in $(echo "$CACHED_FILES" | head -3); do
      CTX_SAMPLE+="
--- $f (first 50 lines) ---
$(head -50 "$f" 2>/dev/null)"
    done

    # Temp files for error capture (cleaned up on exit/interrupt)
    ERR_CM=$(mktemp)
    ERR_AM=$(mktemp)
    ERR_CTX=$(mktemp)
    trap "rm -f '$ERR_CM' '$ERR_AM' '$ERR_CTX'" RETURN

    # Detect test framework for conditional TDD rule
    HAS_TESTS=""
    if cat package.json 2>/dev/null | grep -qE '"(jest|vitest|mocha|jasmine|ava)"'; then
      HAS_TESTS="jest/vitest/mocha"
    elif [ -f "pytest.ini" ] || [ -f "pyproject.toml" ] && grep -q "pytest" pyproject.toml 2>/dev/null; then
      HAS_TESTS="pytest"
    elif [ -f "requirements.txt" ] && grep -qi "pytest" requirements.txt 2>/dev/null; then
      HAS_TESTS="pytest"
    fi

    TDD_INSTRUCTION=""
    if [ -n "$HAS_TESTS" ]; then
      TDD_INSTRUCTION="
## TDD Workflow ($HAS_TESTS detected)
If a test framework is present, add a 'TDD Workflow' subsection under Critical Rules:
- Before implementing ANY logic, write a failing test first (Red)
- Implement minimum code to make the test pass (Green)
- Refactor if needed, keep tests green (Refactor)
- Never write implementation code without a test first"
    fi

    # Step 1a: Extend CLAUDE.md (sonnet, background)
    PID_CM=""
    PID_AM=""
    CLAUDE_MD_BEFORE=""
    AGENTS_MD_BEFORE=""
    CLAUDE_MD_PROMPT=$(cat <<EOF
IMPORTANT: All project context is provided below. Do NOT read any files. Directly edit CLAUDE.md in a single turn.

Replace the ## Commands and ## Critical Rules sections in CLAUDE.md (remove any HTML comments in those sections).

## Commands
Based on the package.json scripts below, document the most important ones (dev, build, lint, test, etc.) as a bullet list.

## Critical Rules
Based on the eslint/prettier config below and the framework/system ($SYSTEM), write concrete, actionable rules. Max 5 sections, 3-5 bullet points each.
Cover these categories where evidence exists: code style (formatting, naming), TypeScript (strict mode, type patterns), imports (path aliases, barrel files), framework-specific (SSR, routing, state), testing (commands, patterns). Omit categories where no evidence exists in the config — do not fabricate rules.
$TDD_INSTRUCTION
$SHOPWARE_RULE

Rules:
- Edit CLAUDE.md directly. Replace both sections including any <!-- comments -->.
- No umlauts. English only.
- Keep CLAUDE.md content stable and static — it is a prompt cache layer. Do not add timestamps, random IDs, or session-specific data.

$CONTEXT
$CTX_SHOPWARE
EOF
)
    AGENTS_MD_PROMPT=$(cat <<EOF
IMPORTANT: All project context is provided below. Do NOT read any files. Directly edit AGENTS.md in a single turn.

Replace the ## Project Overview, ## Architecture Summary, ## Commands, and ## Critical Rules sections in AGENTS.md (remove any HTML comments in those sections).

## Project Overview
Write 4-6 concise bullet points: project purpose, main system/framework ($SYSTEM), runtime/language, key dependencies, and delivery/runtime context if available.

## Architecture Summary
Write 4-6 concise bullet points covering entry points, directory layout, data flow, and important boundaries.

## Commands
Based on package.json scripts, list the most important commands (dev, build, lint, test, etc.) with a short description.
If the project includes spec workflow commands or skills, also include /spec, /spec-board, /spec-review, /spec-validate, /spec-work, and /spec-work-all.
For Codex-compatible projects, do not claim custom /spec* client commands. Instead add one bullet noting that Codex uses the corresponding skills via .codex/skills with \$spec* or natural language, while /spec* remains client-dependent.

## Critical Rules
Based on eslint/prettier and detected framework/system ($SYSTEM), write actionable engineering rules.
Max 5 sections, 3-5 bullet points each.
Cover categories only if evidence exists: formatting/naming, typing patterns, imports/module boundaries, framework conventions, testing.
$TDD_INSTRUCTION

Rules:
- Edit AGENTS.md directly. Replace all four sections including any <!-- comments -->.
- Keep content deterministic and static; do not add timestamps, random IDs, or session-specific data.
- No umlauts. English only.

$CONTEXT
$CTX_SHOPWARE
EOF
)
    CONTEXT_PROMPT=$(cat <<EOF
IMPORTANT: All project context is provided below. Do NOT read any files. Create all 3 files directly in a single turn.

Create exactly 3 files in .agents/context/ using the Write tool:

- **.agents/context/STACK.md** — runtime, framework (with versions), key dependencies (categorized: UI, state, data, testing, build), package manager, build tooling, and libraries/patterns to avoid
- **.agents/context/ARCHITECTURE.md** — project type, directory structure, entry points, data flow, key patterns
- **.agents/context/CONVENTIONS.md** — naming patterns, import style, component structure, error handling, TypeScript usage, testing patterns. Include a "## Definition of Done" section with project-appropriate quality gates derived from detected tools (e.g. linter: no lint errors, TypeScript: no explicit any/type errors, test runner: all tests green, formatter: code formatted). If a tool is not detected, omit its gate.

Project system/framework: $SYSTEM

Rules:
- Create all 3 files in one turn using the Write tool.
- Base ALL content on the provided context. Do not invent details.
- Keep each file concise: 30-60 lines max.
- Use markdown headers and bullet points.
- If information is not available, write 'Not determined from available context.'
- No umlauts. English only.
$SHOPWARE_INSTRUCTION

--- package.json ---
$CTX_PKG
--- tsconfig ---
$CTX_TSCONFIG
--- Directory tree ---
$CTX_DIRS
--- File list ---
$CTX_FILES
--- Config files present ---
$CTX_CONFIGS
--- README (first 50 lines) ---
$CTX_README
--- Sample source files ---
$CTX_SAMPLE
$CTX_SHOPWARE
EOF
)

    if [ "$REGEN_CLAUDE_MD" = "yes" ]; then
      if [ ! -f CLAUDE.md ] && [ -f "$SCRIPT_DIR/templates/CLAUDE.md" ]; then
        cp "$SCRIPT_DIR/templates/CLAUDE.md" CLAUDE.md
      fi
      CLAUDE_MD_BEFORE=$(cksum CLAUDE.md 2>/dev/null || echo "none")

      claude -p --model claude-sonnet-4-6 --permission-mode acceptEdits --max-turns 5 "$CLAUDE_MD_PROMPT" >"$ERR_CM" 2>&1 &
      PID_CM=$!
    fi

    # Step 1b: Extend AGENTS.md (sonnet, background, parallel with CLAUDE.md)
    if [ "$REGEN_AGENTS_MD" = "yes" ]; then
      if [ ! -f AGENTS.md ] && [ -f "$SCRIPT_DIR/templates/AGENTS.md" ]; then
        cp "$SCRIPT_DIR/templates/AGENTS.md" AGENTS.md
      fi
      AGENTS_MD_BEFORE=$(cksum AGENTS.md 2>/dev/null || echo "none")

      claude -p --model claude-sonnet-4-6 --permission-mode acceptEdits --max-turns 5 "$AGENTS_MD_PROMPT" >"$ERR_AM" 2>&1 &
      PID_AM=$!
    fi

    # Step 2: Generate project context (sonnet, background, parallel with Step 1)
    PID_CTX=""
    if [ "$REGEN_CONTEXT" = "yes" ]; then
    mkdir -p .agents/context

  claude -p --model claude-sonnet-4-6 --permission-mode acceptEdits --max-turns 8 "$CONTEXT_PROMPT" >"$ERR_CTX" 2>&1 &
    PID_CTX=$!
    fi

    # Wait for background processes
    WAIT_ARGS=()
    [ -n "$PID_CM" ] && WAIT_ARGS+=("$PID_CM:CLAUDE.md:30:120")
    [ -n "$PID_AM" ] && WAIT_ARGS+=("$PID_AM:AGENTS.md:30:120")
    [ -n "$PID_CTX" ] && WAIT_ARGS+=("$PID_CTX:Project context:45:180")
    echo ""
    [ ${#WAIT_ARGS[@]} -gt 0 ] && wait_parallel "${WAIT_ARGS[@]}"

    # Verify Step 1a: CLAUDE.md was actually modified
    if [ -n "$PID_CM" ]; then
    EXIT_CM=0
    wait "$PID_CM" 2>/dev/null || EXIT_CM=$?
    CLAUDE_MD_AFTER=$(cksum CLAUDE.md 2>/dev/null || echo "none")
    if [ "$EXIT_CM" -eq 0 ] && [ "$CLAUDE_MD_BEFORE" = "$CLAUDE_MD_AFTER" ]; then
      echo "  ↻ CLAUDE.md unchanged after initial generation, retrying with --max-turns 6..."
      claude -p --model claude-sonnet-4-6 --permission-mode acceptEdits --max-turns 6 "$CLAUDE_MD_PROMPT" >"$ERR_CM" 2>&1
      EXIT_CM=$?
      CLAUDE_MD_AFTER=$(cksum CLAUDE.md 2>/dev/null || echo "none")
      if [ "$EXIT_CM" -eq 0 ] && [ "$CLAUDE_MD_BEFORE" != "$CLAUDE_MD_AFTER" ]; then
        echo "  ✅ CLAUDE.md updated after retry"
      fi
    fi
    if [ "$EXIT_CM" -ne 0 ] || [ "$CLAUDE_MD_BEFORE" = "$CLAUDE_MD_AFTER" ]; then
      regen_failed=1
      echo ""
      echo "  ⚠️  CLAUDE.md was not updated (exit code $EXIT_CM)."
      if [ -s "$ERR_CM" ]; then
        echo "  Output: $(tail -5 "$ERR_CM")"
      fi
      echo "  Fix: Run 'claude' in your terminal to check authentication, then re-run."
    fi
    fi

    # Verify Step 1b: AGENTS.md was actually modified
    if [ -n "$PID_AM" ]; then
    EXIT_AM=0
    wait "$PID_AM" 2>/dev/null || EXIT_AM=$?
    AGENTS_MD_AFTER=$(cksum AGENTS.md 2>/dev/null || echo "none")
    if [ "$EXIT_AM" -eq 0 ] && [ "$AGENTS_MD_BEFORE" = "$AGENTS_MD_AFTER" ]; then
      echo "  ↻ AGENTS.md unchanged after initial generation, retrying with --max-turns 6..."
      claude -p --model claude-sonnet-4-6 --permission-mode acceptEdits --max-turns 6 "$AGENTS_MD_PROMPT" >"$ERR_AM" 2>&1
      EXIT_AM=$?
      AGENTS_MD_AFTER=$(cksum AGENTS.md 2>/dev/null || echo "none")
      if [ "$EXIT_AM" -eq 0 ] && [ "$AGENTS_MD_BEFORE" != "$AGENTS_MD_AFTER" ]; then
        echo "  ✅ AGENTS.md updated after retry"
      fi
    fi
    if [ "$EXIT_AM" -ne 0 ] || [ "$AGENTS_MD_BEFORE" = "$AGENTS_MD_AFTER" ]; then
      regen_failed=1
      echo ""
      echo "  ⚠️  AGENTS.md was not updated (exit code $EXIT_AM)."
      if [ -s "$ERR_AM" ]; then
        echo "  Output: $(tail -5 "$ERR_AM")"
      fi
      echo "  Fix: Run 'claude' in your terminal to check authentication, then re-run."
    fi
    fi

    # Verify Step 2: context files were created
    if [ -n "$PID_CTX" ]; then
    EXIT_CTX=0
    wait "$PID_CTX" 2>/dev/null || EXIT_CTX=$?
    CTX_COUNT=$(count_generated_context_files)

    if [ "$EXIT_CTX" -eq 0 ] && [ "$CTX_COUNT" -lt 3 ]; then
      echo "  ↻ Context generation created $CTX_COUNT of 3 files, retrying with --max-turns 12..."
      claude -p --model claude-sonnet-4-6 --permission-mode acceptEdits --max-turns 12 "$CONTEXT_PROMPT" >"$ERR_CTX" 2>&1
      EXIT_CTX=$?
      CTX_COUNT=$(count_generated_context_files)
      if [ "$EXIT_CTX" -eq 0 ] && [ "$CTX_COUNT" -eq 3 ]; then
        echo "  ✅ All 3 context files created after retry"
      fi
    fi

    if [ "$CTX_COUNT" -eq 3 ]; then
      echo "  ✅ All 3 context files created in .agents/context/"
    elif [ "$CTX_COUNT" -gt 0 ]; then
      regen_failed=1
      echo "  ⚠️  $CTX_COUNT of 3 context files created (partial, exit code $EXIT_CTX)"
      if [ -s "$ERR_CTX" ]; then
        echo "  Output: $(tail -5 "$ERR_CTX")"
      fi
    else
      regen_failed=1
      echo "  ⚠️  Context generation failed (exit code $EXIT_CTX)."
      if [ -s "$ERR_CTX" ]; then
        echo "  Output: $(tail -5 "$ERR_CTX")"
      fi
      echo "  Fix: Check 'claude' works, then run: npx @onedot/ai-setup --regenerate"
    fi
    fi

    # Save state for freshness detection
    STATE_FILE=".agents/context/.state"
    if [ -d ".agents/context" ]; then
      echo "PKG_HASH=$(cksum package.json 2>/dev/null | cut -d' ' -f1,2)" > "$STATE_FILE"
      echo "TSCONFIG_HASH=$(cksum tsconfig.json 2>/dev/null | cut -d' ' -f1,2)" >> "$STATE_FILE"
      echo "DIR_HASH=$(echo "$CACHED_FILES" | cksum | cut -d' ' -f1,2)" >> "$STATE_FILE"
      echo "GENERATED_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$STATE_FILE"
      if [ "$SYSTEM" = "shopware" ] && [ -f composer.json ]; then
        echo "COMPOSER_HASH=$(cksum composer.json 2>/dev/null | cut -d' ' -f1,2)" >> "$STATE_FILE"
        echo "SHOPWARE_TYPE=$SHOPWARE_TYPE" >> "$STATE_FILE"
      fi
    fi
  else
    echo "⏭️  Skipping AI context generation (not selected)."
  fi

  # Step 3: Search and install skills (AI-curated, haiku for ranking)
  if [ "$REGEN_SKILLS" = "yes" ]; then
  # Ensure bundled Shopify skills are present when relevant.
  if [[ "${SYSTEM:-}" == *shopify* ]]; then
    for mapping in "${SHOPIFY_SKILLS_MAP[@]}"; do
      local tpl="${mapping%%:*}"
      local target="${mapping#*:}"
      if [ -f "$SCRIPT_DIR/$tpl" ]; then
        mkdir -p "$(dirname "$target")"
        cp "$SCRIPT_DIR/$tpl" "$target"
      fi
    done
  fi

  echo ""
  echo "🔌 Searching and installing skills..."
  INSTALLED=0
  SKIPPED=0

  KEYWORDS=()
  if [ -f package.json ]; then
    if [ "$_JSON_CMD" = "jq" ]; then
      DEPS=$(jq -r '(.dependencies // {} | keys[]) , (.devDependencies // {} | keys[])' package.json 2>/dev/null | sort -u)
    else
      DEPS=$(node -e "
        try{const p=JSON.parse(require('fs').readFileSync('package.json','utf8'));
        const d=[...Object.keys(p.dependencies||{}),...Object.keys(p.devDependencies||{})];
        [...new Set(d)].sort().forEach(x=>console.log(x));}catch(e){}
      " 2>/dev/null)
    fi

    for dep in $DEPS; do
      case "$dep" in
        # Frontend frameworks (specific patterns before general globs)
        vue|vue-router|@vue/*) [[ ! " ${KEYWORDS[*]} " =~ " vue " ]] && KEYWORDS+=("vue") ;;
        @nuxt/ui|@nuxt/ui-pro) [[ ! " ${KEYWORDS[*]} " =~ " nuxt-ui " ]] && KEYWORDS+=("nuxt-ui") ;;
        nuxt|@nuxt/*) [[ ! " ${KEYWORDS[*]} " =~ " nuxt " ]] && KEYWORDS+=("nuxt") ;;
        react|react-dom|@react/*) [[ ! " ${KEYWORDS[*]} " =~ " react " ]] && KEYWORDS+=("react") ;;
        next|@next/*) [[ ! " ${KEYWORDS[*]} " =~ " next " ]] && KEYWORDS+=("next") ;;
        svelte|@sveltejs/*) [[ ! " ${KEYWORDS[*]} " =~ " svelte " ]] && KEYWORDS+=("svelte") ;;
        astro|@astrojs/*) [[ ! " ${KEYWORDS[*]} " =~ " astro " ]] && KEYWORDS+=("astro") ;;
        # UI libraries
        tailwindcss|@tailwindcss/*) [[ ! " ${KEYWORDS[*]} " =~ " tailwind " ]] && KEYWORDS+=("tailwind") ;;
        @shadcn/*|shadcn-ui) [[ ! " ${KEYWORDS[*]} " =~ " shadcn " ]] && KEYWORDS+=("shadcn") ;;
        @radix-ui/*) [[ ! " ${KEYWORDS[*]} " =~ " radix " ]] && KEYWORDS+=("radix") ;;
        @headlessui/*) [[ ! " ${KEYWORDS[*]} " =~ " headless-ui " ]] && KEYWORDS+=("headless-ui") ;;
        reka-ui) [[ ! " ${KEYWORDS[*]} " =~ " reka-ui " ]] && KEYWORDS+=("reka-ui") ;;
        primevue|@primevue/*) [[ ! " ${KEYWORDS[*]} " =~ " primevue " ]] && KEYWORDS+=("primevue") ;;
        vuetify) [[ ! " ${KEYWORDS[*]} " =~ " vuetify " ]] && KEYWORDS+=("vuetify") ;;
        element-plus) [[ ! " ${KEYWORDS[*]} " =~ " element-plus " ]] && KEYWORDS+=("element-plus") ;;
        quasar|@quasar/*) [[ ! " ${KEYWORDS[*]} " =~ " quasar " ]] && KEYWORDS+=("quasar") ;;
        # Languages & runtimes
        typescript) [[ ! " ${KEYWORDS[*]} " =~ " typescript " ]] && KEYWORDS+=("typescript") ;;
        # Backend
        express) [[ ! " ${KEYWORDS[*]} " =~ " express " ]] && KEYWORDS+=("express") ;;
        @nestjs/*) [[ ! " ${KEYWORDS[*]} " =~ " nestjs " ]] && KEYWORDS+=("nestjs") ;;
        @hono/*|hono) [[ ! " ${KEYWORDS[*]} " =~ " hono " ]] && KEYWORDS+=("hono") ;;
        # E-commerce
        @shopify/*|shopify-*) [[ ! " ${KEYWORDS[*]} " =~ " shopify " ]] && KEYWORDS+=("shopify") ;;
        @angular/*|angular) [[ ! " ${KEYWORDS[*]} " =~ " angular " ]] && KEYWORDS+=("angular") ;;
        # Databases & ORMs
        prisma|@prisma/*) [[ ! " ${KEYWORDS[*]} " =~ " prisma " ]] && KEYWORDS+=("prisma") ;;
        drizzle-orm|drizzle-kit) [[ ! " ${KEYWORDS[*]} " =~ " drizzle " ]] && KEYWORDS+=("drizzle") ;;
        # BaaS
        supabase|@supabase/*) [[ ! " ${KEYWORDS[*]} " =~ " supabase " ]] && KEYWORDS+=("supabase") ;;
        firebase|@firebase/*|firebase-admin) [[ ! " ${KEYWORDS[*]} " =~ " firebase " ]] && KEYWORDS+=("firebase") ;;
        # Testing
        vitest) [[ ! " ${KEYWORDS[*]} " =~ " vitest " ]] && KEYWORDS+=("vitest") ;;
        playwright|@playwright/*) [[ ! " ${KEYWORDS[*]} " =~ " playwright " ]] && KEYWORDS+=("playwright") ;;
        # State management
        pinia) [[ ! " ${KEYWORDS[*]} " =~ " pinia " ]] && KEYWORDS+=("pinia") ;;
        @tanstack/*) [[ ! " ${KEYWORDS[*]} " =~ " tanstack " ]] && KEYWORDS+=("tanstack") ;;
        zustand) [[ ! " ${KEYWORDS[*]} " =~ " zustand " ]] && KEYWORDS+=("zustand") ;;
      esac
    done

    if [ ${#KEYWORDS[@]} -eq 0 ]; then
      echo "  No technologies detected."
    else
      echo "  Detected: ${KEYWORDS[*]}"

      # Cache check: skip search + Claude ranking if hashes match
      SKILL_CACHE_FILE=".agents/.skill-cache.json"
      CACHED_SELECTED=""
      if [ -z "${FORCE_SKILLS:-}" ] && [ -f "$SKILL_CACHE_FILE" ]; then
        local _cur_pkg_hash _cur_stack_hash _cached_pkg _cached_stack
        _cur_pkg_hash=$(cksum package.json 2>/dev/null | cut -d' ' -f1,2)
        _cur_stack_hash=$(cksum .agents/context/STACK.md 2>/dev/null | cut -d' ' -f1,2)
        _cached_pkg=$(_json_read "$SKILL_CACHE_FILE" '.pkg_hash')
        _cached_stack=$(_json_read "$SKILL_CACHE_FILE" '.stack_hash')
        if [ -n "$_cur_pkg_hash" ] && [ "$_cur_pkg_hash" = "$_cached_pkg" ] && [ "$_cur_stack_hash" = "$_cached_stack" ]; then
          if [ "$_JSON_CMD" = "jq" ]; then
            CACHED_SELECTED=$(jq -r '.selected // [] | .[]' "$SKILL_CACHE_FILE" 2>/dev/null)
          else
            CACHED_SELECTED=$(node -e "
              try{const d=JSON.parse(require('fs').readFileSync('$SKILL_CACHE_FILE','utf8'));
              (d.selected||[]).forEach(s=>console.log(s));}catch(e){}
            " 2>/dev/null)
          fi
          echo "  ♻️  Using cached skill selection (hash match)"
        fi
      fi

      ALL_SKILLS=""
      SEARCH_TMPDIR=$(mktemp -d)
      declare -a SEARCH_PIDS=()
      declare -a SEARCH_KWS=()

      for kw in "${KEYWORDS[@]}"; do
        [ -n "$CACHED_SELECTED" ] && continue
        # Skip keywords with curated skills — installed directly via KEYWORD_SKILLS below
        if [ -n "$(get_keyword_skills "$kw")" ]; then
          printf "  ✅ %-20s (curated)\n" "$kw:"
          continue
        fi
        printf "  🔍 Searching: %s ...\n" "$kw"
        SEARCH_KWS+=("$kw")
        (
          FOUND=$(search_skills "$kw")
          # Retry once on failure
          if [ -z "$FOUND" ]; then
            sleep 1
            FOUND=$(search_skills "$kw")
          fi
          echo "$FOUND" > "$SEARCH_TMPDIR/$(printf '%s' "$kw" | tr -cd 'a-zA-Z0-9_-')"
        ) &
        SEARCH_PIDS+=($!)
      done

      # Wait for all parallel searches to complete
      for pid in "${SEARCH_PIDS[@]}"; do
        wait "$pid" 2>/dev/null || true
      done

      # Collect results in keyword order
      for kw in "${SEARCH_KWS[@]}"; do
        SAFE_KW=$(printf '%s' "$kw" | tr -cd 'a-zA-Z0-9_-')
        FOUND=$(cat "$SEARCH_TMPDIR/$SAFE_KW" 2>/dev/null || true)
        if [ -n "$FOUND" ]; then
          COUNT=$(printf '%s\n' "$FOUND" | wc -l | tr -d ' ')
          printf "  ✅ %-20s %s skills found\n" "$kw:" "$COUNT"
          ALL_SKILLS="${ALL_SKILLS}${FOUND}"$'\n'
        else
          printf "  ⚠️  %-20s no skills found\n" "$kw:"
        fi
      done
      rm -rf "$SEARCH_TMPDIR"

      # Remove duplicates
      ALL_SKILLS=$(echo "$ALL_SKILLS" | sort -u | sed '/^$/d')

      if [ -n "$ALL_SKILLS" ]; then
        TOTAL_FOUND=$(echo "$ALL_SKILLS" | wc -l | tr -d ' ')

        # Cache search results for fallback
        ALL_SKILLS_CACHE=$(mktemp)
        echo "$ALL_SKILLS" > "$ALL_SKILLS_CACHE"

        # Phase 1.5: Fetch weekly install counts from skills.sh (parallel)
        echo ""
        echo "  📊 Fetching popularity metrics from skills.sh..."
        echo "     (Used to rank skills by real-world usage)"
        INSTALLS_DIR=$(mktemp -d)
        while IFS= read -r sid; do
          if [ -n "$sid" ]; then
            # Cap parallel curl jobs at 8 to avoid overwhelming the server
            while (( $(jobs -r 2>/dev/null | wc -l) >= 8 )); do sleep 0.1; done
            URL_PATH="${sid/@//}"
            (
              COUNT=$(curl -s --max-time 5 "https://skills.sh/$URL_PATH" 2>/dev/null \
                | grep -oE '[0-9]+\.[0-9]+K|[0-9]+K' | head -1)
              SAFE_SID="${sid//\//_}"
              echo "${COUNT:-0}" > "$INSTALLS_DIR/${SAFE_SID//@/_at_}"
            ) &
          fi
        done <<< "$ALL_SKILLS"
        wait

        # Build skills list with install counts
        SKILLS_WITH_COUNTS=""
        while IFS= read -r sid; do
          if [ -n "$sid" ]; then
            SAFE_NAME="${sid//\//_}"
            SAFE_NAME="${SAFE_NAME//@/_at_}"
            COUNT=$(cat "$INSTALLS_DIR/$SAFE_NAME" 2>/dev/null || echo "0")
            SKILLS_WITH_COUNTS="${SKILLS_WITH_COUNTS}${sid} (${COUNT} weekly installs)"$'\n'
          fi
        done <<< "$ALL_SKILLS"
        rm -rf "$INSTALLS_DIR"

        if [ -n "$CACHED_SELECTED" ]; then
          SELECTED="$CACHED_SELECTED"
        else
        echo "  🤖 Claude selecting best skills ($TOTAL_FOUND found)..."

        # Phase 2: Claude selects the most relevant skills (haiku, 60s timeout)
        CLAUDE_TMP=$(mktemp)
        claude -p --model haiku --max-turns 1 "You are a skill curator for AI coding agents. Select the best skills for this project.

Project technologies: ${KEYWORDS[*]}

Available skills (with weekly install counts from skills.sh):
$SKILLS_WITH_COUNTS

Rules:
- Select EXACTLY the top 5 most relevant skills (or fewer if less available)
- Prefer skills with HIGHER install counts (more popular = better quality)
- Avoid duplicates (e.g. not 3x vue-best-practices from different authors)
- Prefer skills from well-known maintainers (antfu, vercel-labs, vuejs-ai, etc.)
- Reply ONLY with skill IDs, one per line, no other text. Format: owner/repo@skill-name" > "$CLAUDE_TMP" 2>/dev/null &
        CLAUDE_PID=$!
        CLAUDE_WAIT=0
        while kill -0 "$CLAUDE_PID" 2>/dev/null && [ "$CLAUDE_WAIT" -lt 60 ]; do
          sleep 1
          CLAUDE_WAIT=$((CLAUDE_WAIT + 1))
        done
        if kill -0 "$CLAUDE_PID" 2>/dev/null; then
          kill_tree "$CLAUDE_PID"
          echo "  ⚠️  Claude timed out (${CLAUDE_WAIT}s). Using fallback..."
          SELECTED=""
        else
          wait "$CLAUDE_PID" 2>/dev/null || true
          SELECTED=$(cat "$CLAUDE_TMP")
        fi
        rm -f "$CLAUDE_TMP"

        if [ -n "$SELECTED" ]; then
          # Extract only valid skill IDs, clean whitespace, strip backticks, enforce max 5
          SELECTED=$(echo "$SELECTED" \
            | sed 's/`//g' \
            | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' \
            | grep -E '^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+@[a-zA-Z0-9_.-]+$' \
            | sort -u \
            | head -5)
        fi

        # Write cache after successful ranking
        if [ -n "$SELECTED" ] && command -v jq >/dev/null 2>&1; then
          local _pkg_h _stack_h
          _pkg_h=$(cksum package.json 2>/dev/null | cut -d' ' -f1,2)
          _stack_h=$(cksum .agents/context/STACK.md 2>/dev/null | cut -d' ' -f1,2)
          mkdir -p .agents
          jq -n \
            --arg pkg_hash "$_pkg_h" \
            --arg stack_hash "$_stack_h" \
            --arg cached_at "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
            --argjson keywords "$(printf '%s\n' "${KEYWORDS[@]}" | jq -R . | jq -s .)" \
            --argjson selected "$(printf '%s\n' "$SELECTED" | jq -R . | jq -s .)" \
            '{pkg_hash: $pkg_hash, stack_hash: $stack_hash, cached_at: $cached_at, keywords: $keywords, selected: $selected}' \
            > "$SKILL_CACHE_FILE" 2>/dev/null || true
        fi

        fi  # end cache-miss branch

        if [ -n "$SELECTED" ]; then
          SELECTED_COUNT=$(printf '%s\n' "$SELECTED" | wc -l | tr -d ' ')
          echo "  ✨ $SELECTED_COUNT skills selected:"
          echo ""

          # Phase 3: Install selected skills in parallel (30s timeout per install)
          INSTALL_TMPDIR=$(mktemp -d)
          declare -a INSTALL_PIDS=()
          declare -a INSTALL_IDS=()
          while IFS= read -r skill_id; do
            # Trim whitespace via parameter expansion (no subshell)
            skill_id="${skill_id#"${skill_id%%[! ]*}"}"
            skill_id="${skill_id%"${skill_id##*[! ]}"}"
            if [ -n "$skill_id" ]; then
              INSTALL_IDS+=("$skill_id")
              (
                install_skill "$skill_id"
                echo $? > "$INSTALL_TMPDIR/$(printf '%s' "$skill_id" | tr -cd 'a-zA-Z0-9_-').exit"
              ) &
              INSTALL_PIDS+=($!)
            fi
          done <<< "$SELECTED"

          # Wait for all installs to finish
          for pid in "${INSTALL_PIDS[@]}"; do
            wait "$pid" 2>/dev/null || true
          done

          # Tally results
          for sid in "${INSTALL_IDS[@]}"; do
            SAFE_ID=$(printf '%s' "$sid" | tr -cd 'a-zA-Z0-9_-')
            EXIT_CODE=$(cat "$INSTALL_TMPDIR/${SAFE_ID}.exit" 2>/dev/null || echo "1")
            if [ "$EXIT_CODE" = "0" ]; then
              INSTALLED=$((INSTALLED + 1))
            fi
          done
          rm -rf "$INSTALL_TMPDIR"
          echo ""
          if [ $SKIPPED -gt 0 ]; then
            echo "  Total: $INSTALLED installed, $SKIPPED skipped (already present)"
          else
            echo "  Total: $INSTALLED skills installed"
          fi
        else
          echo "  ⚠️  Claude could not select skills. Installing top 3 per technology..."
          # Fallback: Top 3 per keyword using cached results
          for kw in "${KEYWORDS[@]}"; do
            SKILL_IDS=$(grep -iE "$kw" "$ALL_SKILLS_CACHE" 2>/dev/null | head -3)
            if [ -n "$SKILL_IDS" ]; then
              while IFS= read -r skill_id; do
                # Trim whitespace via parameter expansion (no subshell)
                skill_id="${skill_id#"${skill_id%%[! ]*}"}"
                skill_id="${skill_id%"${skill_id##*[! ]}"}"
                if [ -n "$skill_id" ]; then
                  install_skill "$skill_id" && INSTALLED=$((INSTALLED + 1))
                fi
              done <<< "$SKILL_IDS"
            fi
          done
          echo ""
          if [ $SKIPPED -gt 0 ]; then
            echo "  Total: $INSTALLED installed, $SKIPPED skipped (fallback)"
          else
            echo "  Total: $INSTALLED skills installed (fallback)"
          fi
        fi
        rm -f "$ALL_SKILLS_CACHE"
      fi
    fi
  else
    echo "  No package.json found."
  fi

  # System-specific default skills (always installed for known systems)
  # Support multiple systems (comma-separated)
  SYSTEM_SKILLS=()
  IFS=',' read -ra SYSTEMS <<< "$SYSTEM"
  for sys in "${SYSTEMS[@]}"; do
    case "$sys" in
      shopify)
        SYSTEM_SKILLS+=(
          "sickn33/antigravity-awesome-skills@shopify-development"
          "jeffallan/claude-skills@shopify-expert"
          "henkisdabro/wookstar-claude-code-plugins@shopify-theme-dev"
        ) ;;
      nuxt)
        SYSTEM_SKILLS+=(
          "antfu/skills@nuxt"
          "onmax/nuxt-skills@nuxt"
          "onmax/nuxt-skills@vue"
          "onmax/nuxt-skills@vueuse"
          "vuejs-ai/skills@vue-best-practices"
          "vuejs-ai/skills@vue-testing-best-practices"
        )
        # Only add nuxt-ui skill if project actually uses it
        if [[ " ${KEYWORDS[*]} " =~ " nuxt-ui " ]]; then
          SYSTEM_SKILLS+=("nuxt/ui@nuxt-ui")
        fi
        ;;
      next)
        SYSTEM_SKILLS+=(
          "vercel-labs/agent-skills@vercel-react-best-practices"
          "vercel-labs/next-skills@next-best-practices"
          "vercel-labs/next-skills@next-cache-components"
          "jeffallan/claude-skills@nextjs-developer"
          "wshobson/agents@nextjs-app-router-patterns"
          "sickn33/antigravity-awesome-skills@nextjs-best-practices"
        ) ;;
      laravel)
        SYSTEM_SKILLS+=(
          "jeffallan/claude-skills@laravel-specialist"
          "iserter/laravel-claude-agents@eloquent-best-practices"
        ) ;;
      shopware)
        SYSTEM_SKILLS+=(
          "bartundmett/skills@shopware6-best-practices"
        ) ;;
      storyblok)
        SYSTEM_SKILLS+=(
          "bartundmett/skills@storyblok-best-practices"
        ) ;;
    esac
  done

  # Add curated keyword-based skills (from detected package.json dependencies)
  if [ ${#KEYWORDS[@]} -gt 0 ]; then
    for kw in "${KEYWORDS[@]}"; do
      kw_skills=$(get_keyword_skills "$kw")
      if [ -n "$kw_skills" ]; then
        for sid in $kw_skills; do
          SYSTEM_SKILLS+=("$sid")
        done
      fi
    done
  fi

  if [ ${#SYSTEM_SKILLS[@]} -gt 0 ]; then
    SYSTEM_SKILLS_UNIQ=()
    while IFS= read -r sid; do
      [ -n "$sid" ] && SYSTEM_SKILLS_UNIQ+=("$sid")
    done <<EOF
$(printf '%s\n' "${SYSTEM_SKILLS[@]}" | sed '/^$/d' | sort -u)
EOF
    SYSTEM_SKILLS=("${SYSTEM_SKILLS_UNIQ[@]}")

    echo ""
    echo "  📦 Installing system-specific skills ($SYSTEM)..."

    # Install system skills in parallel; tally results after all complete
    SYS_INSTALL_TMPDIR=$(mktemp -d)
    declare -a SYS_PIDS=()

    for skill_id in "${SYSTEM_SKILLS[@]}"; do
      (
        install_skill "$skill_id"
        echo $? > "$SYS_INSTALL_TMPDIR/$(printf '%s' "$skill_id" | tr -cd 'a-zA-Z0-9_-').exit"
      ) &
      SYS_PIDS+=($!)
    done

    for pid in "${SYS_PIDS[@]}"; do
      wait "$pid" 2>/dev/null || true
    done

    for skill_id in "${SYSTEM_SKILLS[@]}"; do
      SAFE_ID=$(printf '%s' "$skill_id" | tr -cd 'a-zA-Z0-9_-')
      EXIT_CODE=$(cat "$SYS_INSTALL_TMPDIR/${SAFE_ID}.exit" 2>/dev/null || echo "1")
      if [ "$EXIT_CODE" = "0" ]; then
        INSTALLED=$((INSTALLED + 1))
      fi
    done
    rm -rf "$SYS_INSTALL_TMPDIR"
  fi
  fi # REGEN_SKILLS

  set -e
  if [ "$regen_failed" -ne 0 ]; then
    return 1
  fi
  return 0
}
