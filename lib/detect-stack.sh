#!/bin/bash
# detect-stack.sh — detect stack profile from project directory
# Usage: detect-stack.sh [project-dir]
# Output: stack_profile=<profile> on stdout, graphify_candidate=true|false on stdout
# Profiles: nuxt-storyblok | nuxtjs | shopify-liquid | laravel | nextjs | default

set -e

PROJECT_DIR="${1:-$PWD}"

# Count files matching a glob extension within a directory (max depth 3)
_count_files() {
  local dir="$1"
  local ext="$2"
  local count=0
  if [ -d "$dir" ]; then
    count=$(find "$dir" -maxdepth 3 -name "$ext" 2>/dev/null | wc -l | tr -d ' ')
  fi
  echo "$count"
}

# Determine if this project is a good graphify candidate.
# Returns 0 (true) when the codebase has enough typed/templated files to benefit from a semantic graph.
# Thresholds: Nuxt ≥50 .vue, Shopify ≥30 .liquid, Laravel ≥100 .php, JS/TS ≥100 .ts/.tsx/.js
_detect_graphify_candidate() {
  local dir="$1"

  # .vue files — Nuxt/Vue projects
  local vue_count
  vue_count=$(_count_files "$dir" "*.vue")
  [ "$vue_count" -ge 50 ] && return 0

  # .liquid files — Shopify
  local liquid_count
  liquid_count=$(_count_files "$dir" "*.liquid")
  [ "$liquid_count" -ge 30 ] && return 0

  # .php files — Laravel / PHP projects
  local php_count
  php_count=$(_count_files "$dir" "*.php")
  [ "$php_count" -ge 100 ] && return 0

  # TypeScript / JavaScript — modern JS/TS projects
  local ts_count tsx_count js_count total_ts
  ts_count=$(_count_files "$dir" "*.ts")
  tsx_count=$(_count_files "$dir" "*.tsx")
  js_count=$(_count_files "$dir" "*.js")
  total_ts=$((ts_count + tsx_count + js_count))
  [ "$total_ts" -ge 100 ] && return 0

  return 1
}

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

# Detection: nuxtjs (plain Nuxt without Storyblok — runs AFTER nuxt-storyblok check)
_detect_nuxtjs() {
  local dir="$1"

  if ls "${dir}/nuxt.config."* 1>/dev/null 2>&1; then
    return 0
  fi

  if [ -f "${dir}/package.json" ] && _pkg_has "${dir}/package.json" '"nuxt"'; then
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
  elif _detect_nextjs "$dir"; then
    profile="nextjs"
  elif _detect_nuxtjs "$dir"; then
    profile="nuxtjs"
  fi

  echo "stack_profile=${profile}"

  # Graphify candidate detection
  if _detect_graphify_candidate "$dir"; then
    echo "graphify_candidate=true"
  else
    echo "graphify_candidate=false"
  fi
}

main
