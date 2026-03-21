#!/bin/bash
# Shopware-specific context gathering and MCP setup
# Requires: core.sh, detect.sh ($SYSTEM, $SHOPWARE_TYPE)
# Sets: CTX_SHOPWARE, SHOPWARE_INSTRUCTION, SHOPWARE_RULE

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
- Deployment: Never run dep, deployer, or any Deployer commands -- deployment is handled by the team's pipeline, not by Claude

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
- Deployment: Never run dep, deployer, or any Deployer commands -- deployment is handled by the team's pipeline, not by Claude

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
