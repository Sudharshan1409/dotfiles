#!/bin/bash

if [ -f /etc/os-release ]; then
    . /etc/os-release
    if [[ "$ID" == "arch" || "$ID_LIKE" == "arch" ]]; then
        blueberry &
    else
        # Default fallback
        bzmenu -l custom --launcher-command ~/.config/rofi/rofi-bluetooth.sh &
    fi
else
    # Default fallback
    bzmenu -l custom --launcher-command ~/.config/rofi/rofi-bluetooth.sh &
fi
