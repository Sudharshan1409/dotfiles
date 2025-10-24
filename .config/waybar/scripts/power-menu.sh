#!/bin/bash

# Define the options with the new "Sleep" option included
# The moon icon () is from Nerd Fonts
options="⏻ Shutdown\n⏼ Reboot\n Sleep\n Lock\n Logout" # <-- ADDED SLEEP OPTION

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
    " Sleep") # <-- ADDED THIS BLOCK
        systemctl suspend
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
