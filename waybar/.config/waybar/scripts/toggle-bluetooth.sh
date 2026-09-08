#!/bin/bash

if bluetoothctl show 2>/dev/null | grep -q "Powered: yes"; then
    bluetoothctl power off
else
    bluetoothctl power on
fi
pkill -SIGRTMIN+8 waybar 2>/dev/null || true
