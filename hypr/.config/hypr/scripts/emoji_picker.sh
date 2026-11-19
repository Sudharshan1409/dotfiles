#!/usr/bin/env bash
# =============================================================================
# Emoji & Nerd Font Glyph Picker (powered by Caelestia + Material You Rofi)
# =============================================================================

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"
ROFI_THEME="$HOME/.config/rofi/emoji.rasi"

CHOICE="$(caelestia emoji 2>/dev/null | rofi -dmenu -i -p "Emoji" -theme "$ROFI_THEME")"
[ -z "$CHOICE" ] && exit 0

GLYPH="$(printf '%s' "$CHOICE" | awk '{print $1}')"
LABEL="$(printf '%s' "$CHOICE" | cut -d' ' -f2-)"

if [ -n "$GLYPH" ]; then
    printf '%s' "$GLYPH" | wl-copy
    notify-send -a "Emoji Picker" -t 2000 "Copied $GLYPH to clipboard" "${LABEL:-Ready to paste}"
fi
