#!/bin/bash

# 1. Check if Bluetooth is soft-blocked
if rfkill list bluetooth | grep -q "Soft blocked: yes"; then
    echo "{\"text\":\" Off\", \"tooltip\":\"Bluetooth is off\", \"class\":\"bt-off\"}"
    exit 0
fi

# 2. Check for connected devices
CONNECTED_DEVICES=$(bluetoothctl devices Connected | wc -l)

if [ "$CONNECTED_DEVICES" -gt 0 ]; then
    # If connected, show the number of devices
    echo "{\"text\":\" ${CONNECTED_DEVICES}\", \"tooltip\":\"${CONNECTED_DEVICES} device(s) connected\", \"class\":\"bt-connected\"}"
else
    # If on but not connected, show the "on" icon
    echo "{\"text\":\" On\", \"tooltip\":\"Bluetooth is on, not connected\", \"class\":\"bt-on\"}"
fi
