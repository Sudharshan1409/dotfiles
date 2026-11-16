#!/bin/bash

# Confirmation prompt before exiting Hyprland session.
# Triggered by Super + Ctrl + M.

ROFI_THEME="$HOME/.config/rofi/exit-hyprland.rasi"

choice=$(printf "  No, stay\n  Yes, exit" | rofi -dmenu \
    -p "Exit" \
    -theme "$ROFI_THEME" \
    -mesg "Exit Hyprland session?" \
    -no-custom \
    -selected-row 0)

case "$choice" in
    *"Yes, exit"*)
        hyprctl dispatch exit
        ;;
esac
