#!/bin/bash

# Define the options with Nerd Font icons
options="⏻ Shutdown\n⏼ Reboot\n Lock\n Logout"

# Show Rofi menu and get the chosen option
chosen=$(echo -e "$options" | rofi -dmenu -i -p "Power Menu")

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
