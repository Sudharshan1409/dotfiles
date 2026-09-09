#!/bin/bash

CACHE_FILE="$HOME/.cache/hypr/lockscreen_info.json"

# Check if cache file exists and contains valid JSON; regenerate if missing or corrupt
if [ ! -f "$CACHE_FILE" ] || ! jq empty "$CACHE_FILE" 2>/dev/null; then
    ~/.config/hypr/scripts/cache_lockscreen_info.sh
fi

# Get the requested info from the cache
val=$(jq -r ".$1 // empty" "$CACHE_FILE" 2>/dev/null)
if [ -z "$val" ]; then
    ~/.config/hypr/scripts/cache_lockscreen_info.sh
    val=$(jq -r ".$1 // empty" "$CACHE_FILE" 2>/dev/null)
fi
echo "$val"
