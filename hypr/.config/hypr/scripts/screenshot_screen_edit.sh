#!/bin/bash
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

TARGET_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$TARGET_DIR"
FILENAME="$TARGET_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"

MONITOR="$(hyprctl -j monitors 2>/dev/null | jq -r '.[] | select(.focused == true) | .name')"
[ -z "$MONITOR" ] && MONITOR="$(hyprctl -j monitors 2>/dev/null | jq -r '.[0].name')"

if command -v satty >/dev/null 2>&1; then
    grim ${MONITOR:+-o "$MONITOR"} - | satty --filename - \
        --output-filename "$FILENAME" \
        --early-exit \
        --actions-on-enter save-to-clipboard \
        --save-after-copy \
        --copy-command 'wl-copy'
else
    grim ${MONITOR:+-o "$MONITOR"} "$FILENAME"
    wl-copy < "$FILENAME"
    notify-send "Screenshot Captured" "Saved to $FILENAME and copied to clipboard" -i camera-photo
fi