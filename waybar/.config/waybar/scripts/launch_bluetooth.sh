#!/bin/bash

if command -v blueman-manager >/dev/null 2>&1; then
    blueman-manager &
elif command -v blueberry >/dev/null 2>&1; then
    blueberry &
elif [ -x "$HOME/.config/rofi/rofi-bluetooth.sh" ]; then
    "$HOME/.config/rofi/rofi-bluetooth.sh" &
fi
