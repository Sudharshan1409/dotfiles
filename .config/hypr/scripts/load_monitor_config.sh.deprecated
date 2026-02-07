#!/bin/bash

CONFIG_DIR="$HOME/.config/hypr/monitors"
OUTPUT_FILE="$HOME/.config/hypr/monitors.gen.conf"
CONFIG_FILE="$HOME/.config/hypr/monitor_config"

if [ -f "$CONFIG_FILE" ] && [ "$(cat "$CONFIG_FILE")" = "WORK" ]; then
    echo "source=$CONFIG_DIR/work.conf" > "$OUTPUT_FILE"
else
    echo "source=$CONFIG_DIR/default.conf" > "$OUTPUT_FILE"
fi
