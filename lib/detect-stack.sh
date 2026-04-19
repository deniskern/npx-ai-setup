#!/bin/bash
# detect-stack.sh — detect stack profile from project directory
# Usage: detect-stack.sh [project-dir]
# Output: stack_profile=<profile> on stdout
# Profiles: nuxt-storyblok | shopify-liquid | laravel | mcp-server | nextjs | n8n | default

set -e

PROJECT_DIR="${1:-$PWD}"

# Count liquid files in a given subdirectory
_count_liquid_files() {
  local dir="$1"
  local count=0
  if [ -d "$dir" ]; then
    count=$(find "$dir" -maxdepth 2 -name "*.liquid" 2>/dev/null | wc -l | tr -d ' ')
  fi
  echo "$count"
}

# Check if package.json contains a specific string
_pkg_has() {
  local pkg_file="$1"
  local search="$2"
  grep -q "$search" "$pkg_file" 2>/dev/null
}

# Detection: nuxt-storyblok
# nuxt.config.* exists AND @storyblok/nuxt in package.json
_detect_nuxt_storyblok() {
  local dir="$1"
  local has_nuxt_config=0
  local has_storyblok=0

  if ls "${dir}/nuxt.config."* 1>/dev/null 2>&1; then
    has_nuxt_config=1
  fi

  if [ -f "${dir}/package.json" ] && _pkg_has "${dir}/package.json" "@storyblok/nuxt"; then
    has_storyblok=1
  fi

  if [ "$has_nuxt_config" -eq 1 ] && [ "$has_storyblok" -eq 1 ]; then
    return 0
  fi
  return 1
}

# Detection: shopify-liquid
# *.liquid files in sections/ OR snippets/ OR templates/ (count >= 5)
_detect_shopify_liquid() {
  local dir="$1"
  local total=0
  local sections_count snippets_count templates_count

  sections_count=$(_count_liquid_files "${dir}/sections")
  snippets_count=$(_count_liquid_files "${dir}/snippets")
  templates_count=$(_count_liquid_files "${dir}/templates")

  total=$((sections_count + snippets_count + templates_count))

  if [ "$total" -ge 5 ]; then
    return 0
  fi
  return 1
}

# Detection: laravel
# artisan file exists OR composer.json has laravel/framework
_detect_laravel() {
  local dir="$1"

  if [ -f "${dir}/artisan" ]; then
    return 0
  fi

  if [ -f "${dir}/composer.json" ] && _pkg_has "${dir}/composer.json" "laravel/framework"; then
    return 0
  fi

  return 1
}

# Detection: mcp-server
# package.json has @modelcontextprotocol/sdk
_detect_mcp_server() {
  local dir="$1"

  if [ -f "${dir}/package.json" ] && _pkg_has "${dir}/package.json" "@modelcontextprotocol/sdk"; then
    return 0
  fi
  return 1
}

# Detection: nextjs
# next.config.* exists OR next in package.json dependencies
_detect_nextjs() {
  local dir="$1"

  if ls "${dir}/next.config."* 1>/dev/null 2>&1; then
    return 0
  fi

  if [ -f "${dir}/package.json" ] && _pkg_has "${dir}/package.json" '"next"'; then
    return 0
  fi

  return 1
}

# Detection: n8n
# .n8n/ dir exists OR workflow JSON files present OR package has n8n
_detect_n8n() {
  local dir="$1"

  if [ -d "${dir}/.n8n" ]; then
    return 0
  fi

  if find "$dir" -maxdepth 2 -name "*.workflow.json" 2>/dev/null | grep -q .; then
    return 0
  fi

  if [ -f "${dir}/package.json" ] && _pkg_has "${dir}/package.json" '"n8n"'; then
    return 0
  fi

  return 1
}

main() {
  local dir="$PROJECT_DIR"
  local profile="default"

  if _detect_nuxt_storyblok "$dir"; then
    profile="nuxt-storyblok"
  elif _detect_shopify_liquid "$dir"; then
    profile="shopify-liquid"
  elif _detect_laravel "$dir"; then
    profile="laravel"
  elif _detect_mcp_server "$dir"; then
    profile="mcp-server"
  elif _detect_nextjs "$dir"; then
    profile="nextjs"
  elif _detect_n8n "$dir"; then
    profile="n8n"
  fi

  echo "stack_profile=${profile}"
}

main

# liquid_graph_hint — prints a build hint when profile=shopify-liquid
# Called by external scripts; NOT invoked inside detect-stack itself (detect is read-only).
# Usage: liquid_graph_hint [project-dir]
liquid_graph_hint() {
  local dir="${1:-$PWD}"
  local profile
  profile=$(bash "$(dirname "$0")/detect-stack.sh" "$dir" 2>/dev/null | grep '^stack_profile=' | cut -d= -f2 || echo "default")
  if [ "$profile" = "shopify-liquid" ]; then
    echo "hint: run 'bash lib/build-liquid-graph.sh $dir' to build .agents/context/liquid-graph.json"
  fi
}
