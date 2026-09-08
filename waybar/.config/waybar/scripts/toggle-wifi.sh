#!/bin/bash

if [ "$(nmcli radio wifi)" = "enabled" ]; then
    nmcli radio wifi off
else
    nmcli radio wifi on
fi
pkill -SIGRTMIN+8 waybar 2>/dev/null || true
