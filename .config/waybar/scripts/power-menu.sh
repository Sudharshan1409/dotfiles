#!/bin/bash

# Define the options for the menu
options="⏻ Shutdown\n⏼ Reboot\n Lock\n Logout"

# Rofi command using the reliable vertical theme in dmenu mode
chosen=$(echo -e "$options" | rofi -dmenu \
    -mesg "Power Menu" \
    -theme ~/.config/rofi/powermenu-vertical.rasi)

# Execute a command based on the choice
case "$chosen" in
    "⏻ Shutdown")
        systemctl poweroff
        ;;
    "⏼ Reboot")
        systemctl reboot
        ;;
    " Lock")
        hyprlock
        ;;
    " Logout")
        hyprctl dispatch exit ""
        ;;
    *)
        exit 1
        ;;
esac
