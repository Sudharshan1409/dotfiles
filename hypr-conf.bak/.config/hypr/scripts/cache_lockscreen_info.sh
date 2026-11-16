#!/bin/bash

# Create cache directory if it doesn't exist
mkdir -p ~/.cache/hypr

# Get static information
OS_STRING=$(~/.config/hypr/scripts/get_lockscreen_info.sh os)
PACKAGES=$(~/.config/hypr/scripts/get_lockscreen_info.sh packages)
KERNEL=$(~/.config/hypr/scripts/get_lockscreen_info.sh kernel)
SHELL=$(~/.config/hypr/scripts/get_lockscreen_info.sh shell)
CPU=$(~/.config/hypr/scripts/get_lockscreen_info.sh cpu)
GPU=$(~/.config/hypr/scripts/get_lockscreen_info.sh gpu)

# Create JSON file safely with jq to ensure valid formatting
if command -v jq &>/dev/null; then
    jq -n \
        --arg os "$OS_STRING" \
        --arg packages "$PACKAGES" \
        --arg kernel "$KERNEL" \
        --arg shell "$SHELL" \
        --arg cpu "$CPU" \
        --arg gpu "$GPU" \
        '$ARGS.named' > ~/.cache/hypr/lockscreen_info.json
else
    python3 -c "
import json, sys, os
data = {
    'os': sys.argv[1],
    'packages': sys.argv[2],
    'kernel': sys.argv[3],
    'shell': sys.argv[4],
    'cpu': sys.argv[5],
    'gpu': sys.argv[6]
}
with open(os.path.expanduser('~/.cache/hypr/lockscreen_info.json'), 'w') as f:
    json.dump(data, f, indent=4)
" "$OS_STRING" "$PACKAGES" "$KERNEL" "$SHELL" "$CPU" "$GPU" 2>/dev/null
fi
