#!/bin/bash
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

TARGET_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$TARGET_DIR"
FILENAME="$TARGET_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"

GEOM="$(hyprctl -j activewindow 2>/dev/null | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"

if [ -z "$GEOM" ] || [ "$GEOM" = "null,null nullxnull" ]; then
    GEOM="$(slurp)" || exit 0
fi

[ -z "$GEOM" ] && exit 0

if command -v satty >/dev/null 2>&1; then
    grim -g "$GEOM" - | satty --filename - \
        --output-filename "$FILENAME" \
        --early-exit \
        --actions-on-enter save-to-clipboard \
        --save-after-copy \
        --copy-command 'wl-copy'
else
    grim -g "$GEOM" "$FILENAME"
    wl-copy < "$FILENAME"
    notify-send "Screenshot Captured" "Saved to $FILENAME and copied to clipboard" -i camera-photo
fi
