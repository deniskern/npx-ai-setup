#!/bin/bash
# JSON wrapper — uses jq when available, falls back to Node.js >= 18.
# Detect once at load time; callers use _json_* functions.

if command -v jq >/dev/null 2>&1; then
  _JSON_CMD="jq"
else
  _JSON_CMD="node"
fi

# Read a single field from a JSON file.
# Usage: _json_read FILE DOTPATH  (e.g. _json_read pkg.json '.version')
_json_read() {
  local file="$1" path="$2"
  if [ "$_JSON_CMD" = "jq" ]; then
    jq -r "${path} // empty" "$file" 2>/dev/null
  else
    local keys
    keys=$(echo "$path" | sed 's/^\.//' | tr '.' ' ')
    node -e "
      try {
        let d = JSON.parse(require('fs').readFileSync('$file','utf8'));
        for (const k of '$keys'.split(' ').filter(Boolean)) d = d?.[k];
        if (d != null) process.stdout.write(String(d));
      } catch(e) {}
    " 2>/dev/null
  fi
}

# Validate that a file contains valid JSON. Returns 0 if valid, 1 otherwise.
_json_valid() {
  local file="$1"
  if [ "$_JSON_CMD" = "jq" ]; then
    jq -e . "$file" >/dev/null 2>&1
  else
    node -e "
      try{JSON.parse(require('fs').readFileSync('$file','utf8'));process.exit(0);}
      catch(e){process.exit(1);}
    " 2>/dev/null
  fi
}

# Deep-merge a JSON object into a file. Overwrites file with merged result.
# Usage: _json_merge TARGET_FILE MERGE_JSON_STRING
_json_merge() {
  local target="$1" merge="$2" tmp
  tmp=$(mktemp)
  if [ "$_JSON_CMD" = "jq" ]; then
    jq --argjson m "$merge" '. * $m' "$target" > "$tmp" && mv "$tmp" "$target" || rm -f "$tmp"
  else
    node -e "
      const fs=require('fs');
      const deep=(a,b)=>typeof b!=='object'||Array.isArray(b)?b:Object.fromEntries(
        [...new Set([...Object.keys(a||{}),...Object.keys(b)])].map(k=>[k,k in b?
        (typeof b[k]==='object'&&!Array.isArray(b[k])&&k in (a||{})?deep(a[k],b[k]):b[k]):a[k]]));
      fs.writeFileSync('$target',JSON.stringify(deep(JSON.parse(fs.readFileSync('$target','utf8')),$merge),null,2));
    " 2>/dev/null || return 1
    rm -f "$tmp"
  fi
}

# Build the initial .ai-setup.json structure.
# Usage: _json_build_metadata VER INST_TIME UPD_TIME SYSTEM
_json_build_metadata() {
  local ver="$1" inst="$2" upd="$3" sys="$4"
  if [ "$_JSON_CMD" = "jq" ]; then
    jq -n --arg ver "$ver" --arg inst "$inst" --arg upd "$upd" --arg sys "$sys" \
      '{version:$ver,installed_at:$inst,updated_at:$upd,system:$sys,files:{}}'
  else
    node -e "process.stdout.write(JSON.stringify(
      {version:'$ver',installed_at:'$inst',updated_at:'$upd',system:'$sys',files:{}},null,2));"
  fi
}

# Set .files[KEY] = VALUE in a JSON string (stdin → stdout).
# Usage: echo "\$json" | _json_set_file KEY VALUE
_json_set_file() {
  local key="$1" val="$2"
  if [ "$_JSON_CMD" = "jq" ]; then
    jq --arg f "$key" --arg c "$val" '.files[$f] = $c'
  else
    node -e "
      const d=JSON.parse(require('fs').readFileSync('/dev/stdin','utf8'));
      d.files=d.files||{};d.files['$key']='$val';
      process.stdout.write(JSON.stringify(d,null,2));"
  fi
}
