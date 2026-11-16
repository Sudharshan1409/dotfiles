#!/bin/bash
export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

TARGET_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$TARGET_DIR"
FILENAME="$TARGET_DIR/screenshot-$(date +'%Y-%m-%d_%H-%M-%S').png"

# Select region via slurp; exit gracefully if canceled (Esc)
GEOM="$(slurp)" || exit 0
[ -z "$GEOM" ] && exit 0

if command -v satty >/dev/null 2>&1; then
    grim -g "$GEOM" - | satty --filename - \
        --output-filename "$FILENAME" \
        --early-exit \
        --actions-on-enter save-to-clipboard \
        --save-after-copy \
        --copy-command 'wl-copy'
elif command -v swappy >/dev/null 2>&1; then
    grim -g "$GEOM" - | swappy -f - -o "$FILENAME"
    if [ -f "$FILENAME" ]; then
        wl-copy < "$FILENAME"
        notify-send "Screenshot Captured" "Saved to $FILENAME and copied to clipboard" -i camera-photo
    fi
else
    grim -g "$GEOM" "$FILENAME"
    wl-copy < "$FILENAME"
    notify-send "Screenshot Captured" "Saved to $FILENAME and copied to clipboard" -i camera-photo
fi