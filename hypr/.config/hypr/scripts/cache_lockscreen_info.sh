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

# Create JSON file
cat <<EOF > ~/.cache/hypr/lockscreen_info.json
{
    "os": "$OS_STRING",
    "packages": "$PACKAGES",
    "kernel": "$KERNEL",
    "shell": "$SHELL",
    "cpu": "$CPU",
    "gpu": "$GPU"
}
EOF
