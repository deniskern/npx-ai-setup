#!/bin/bash
# AI generation: CLAUDE.md extension, context generation, skill discovery
# Requires: core.sh, process.sh, skills.sh
# Requires: $TEMPLATE_MAP, $REGEN_*

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
# Requires: claude CLI is available
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
    echo "🚀 Generating project context..."

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

    # Sample source files: targeted selection of architecturally relevant files
    CTX_SAMPLE=""
    local _sample_files=""

    # 1. Entry points (most architecturally informative)
    for _ep in bin/*.sh src/index.* src/main.* app/page.* app/layout.* pages/index.* \
               index.ts index.js main.ts main.js server.ts server.js app.ts app.js \
               src/App.* src/app.* nuxt.config.* next.config.* vite.config.* astro.config.*; do
      [ -f "$_ep" ] && _sample_files="${_sample_files} ${_ep}"
    done

    # 2. First route/component/composable (framework conventions)
    for _dir in components pages routes composables hooks lib/api src/routes src/pages \
                app/api sections snippets Resources/views custom/plugins; do
      if [ -d "$_dir" ]; then
        local _first
        _first=$(find "$_dir" -maxdepth 2 -type f \( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.vue' -o -name '*.svelte' -o -name '*.php' -o -name '*.liquid' -o -name '*.sh' \) 2>/dev/null | head -1)
        [ -n "$_first" ] && _sample_files="${_sample_files} ${_first}"
      fi
    done

    # 3. Deduplicate and limit to 5 files
    local _seen="" _count=0
    for f in $_sample_files; do
      case "$_seen" in *" $f "*) continue ;; esac
      _seen="$_seen $f "
      CTX_SAMPLE+="
--- $f (first 50 lines) ---
$(head -50 "$f" 2>/dev/null)"
      _count=$((_count + 1))
      [ "$_count" -ge 5 ] && break
    done

    # 4. Fallback: if nothing matched, use first 3 from file list (original behavior)
    if [ "$_count" -eq 0 ]; then
      for f in $(echo "$CACHED_FILES" | head -3); do
        CTX_SAMPLE+="
--- $f (first 50 lines) ---
$(head -50 "$f" 2>/dev/null)"
      done
    fi

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
Based on the eslint/prettier config below and the detected framework, write concrete, actionable rules. Max 5 sections, 3-5 bullet points each.
Cover these categories where evidence exists: code style (formatting, naming), TypeScript (strict mode, type patterns), imports (path aliases, barrel files), framework-specific (SSR, routing, state), testing (commands, patterns). Omit categories where no evidence exists in the config — do not fabricate rules.
$TDD_INSTRUCTION

Rules:
- Edit CLAUDE.md directly. Replace both sections including any <!-- comments -->.
- No umlauts. English only.
- Keep CLAUDE.md content stable and static — it is a prompt cache layer. Do not add timestamps, random IDs, or session-specific data.

$CONTEXT
EOF
)
    AGENTS_MD_PROMPT=$(cat <<EOF
IMPORTANT: All project context is provided below. Do NOT read any files. Directly edit AGENTS.md in a single turn.

Replace the ## Project Overview, ## Architecture Summary, ## Commands, and ## Critical Rules sections in AGENTS.md (remove any HTML comments in those sections).

## Project Overview
Write 4-6 concise bullet points: project purpose, main framework/runtime/language, key dependencies, and delivery/runtime context if available.

## Architecture Summary
Write 4-6 concise bullet points covering entry points, directory layout, data flow, and important boundaries.

## Commands
Based on package.json scripts, list the most important commands (dev, build, lint, test, etc.) with a short description.
If the project includes spec workflow commands or skills, also include /spec, /spec-board, /spec-review, /spec-validate, /spec-work, and /spec-work-all.
For Codex-compatible projects, do not claim custom /spec* client commands. Instead add one bullet noting that Codex uses the corresponding skills via .codex/skills with \$spec* or natural language, while /spec* remains client-dependent.

## Critical Rules
Based on eslint/prettier and detected framework, write actionable engineering rules.
Max 5 sections, 3-5 bullet points each.
Cover categories only if evidence exists: formatting/naming, typing patterns, imports/module boundaries, framework conventions, testing.
$TDD_INSTRUCTION

Rules:
- Edit AGENTS.md directly. Replace all four sections including any <!-- comments -->.
- Keep content deterministic and static; do not add timestamps, random IDs, or session-specific data.
- No umlauts. English only.

$CONTEXT
EOF
)
    CONTEXT_PROMPT=$(cat <<EOF
IMPORTANT: All project context is provided below. Do NOT read any files. Create all 3 files directly in a single turn.

Create exactly 3 files in .agents/context/ using the Write tool:

- **.agents/context/STACK.md** — runtime, framework (with versions), key dependencies (categorized: UI, state, data, testing, build), package manager, build tooling, and libraries/patterns to avoid
- **.agents/context/ARCHITECTURE.md** — project type, directory structure, entry points, data flow, key patterns
- **.agents/context/CONVENTIONS.md** — naming patterns, import style, component structure, error handling, TypeScript usage, testing patterns. Include a "## Definition of Done" section with project-appropriate quality gates derived from detected tools (e.g. linter: no lint errors, TypeScript: no explicit any/type errors, test runner: all tests green, formatter: code formatted). If a tool is not detected, omit its gate.

Rules:
- Create all 3 files in one turn using the Write tool.
- Base ALL content on the provided context. Do not invent details.
- Keep each file concise: 30-60 lines max.
- Use markdown headers and bullet points.
- If information is not available, write 'Not determined from available context.'
- No umlauts. English only.

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

  claude -p --model claude-haiku-4-5-20251001 --permission-mode acceptEdits --max-turns 8 "$CONTEXT_PROMPT" >"$ERR_CTX" 2>&1 &
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
      claude -p --model claude-haiku-4-5-20251001 --permission-mode acceptEdits --max-turns 12 "$CONTEXT_PROMPT" >"$ERR_CTX" 2>&1
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
    fi
  else
    echo "⏭️  Skipping AI context generation (not selected)."
  fi

  # Step 3: Search and install skills (AI-curated, haiku for ranking)
  if [ "$REGEN_SKILLS" = "yes" ]; then
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
    fi
  else
    echo "  No package.json found."
  fi

  # Default + curated skills for this project
  SYSTEM_SKILLS=()
  # Universal skills installed for every project regardless of stack
  SYSTEM_SKILLS+=("vercel-labs/agent-browser@agent-browser")
  SYSTEM_SKILLS+=("vercel-labs/skills@find-skills")

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
    echo "  📦 Installing skills..."

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
