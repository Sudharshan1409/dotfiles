#!/bin/bash

# Check if cache file exists and create it if not
if [ ! -f ~/.cache/hypr/lockscreen_info.json ]; then
    ~/.config/hypr/scripts/cache_lockscreen_info.sh
fi

# Get the requested info from the cache
jq -r ".$1" ~/.cache/hypr/lockscreen_info.json
