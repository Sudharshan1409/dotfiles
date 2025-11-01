#!/bin/bash

# --- Configuration ---
ETH_INTERFACE="enp3s0"
WIFI_INTERFACE="wlo1"

# --- Main Logic ---

# 1. Check for Ethernet connection first (This part is already working perfectly)
if ip addr show "$ETH_INTERFACE" | grep -q "inet "; then
    IP_ADDR=$(ip addr show "$ETH_INTERFACE" | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    echo "{\"text\":\" ${IP_ADDR}\", \"tooltip\":\"Ethernet (${ETH_INTERFACE}): ${IP_ADDR}\", \"class\":\"ethernet\"}"
    exit 0
fi

# 2. If no Ethernet, check if Wi-Fi radio is off (This part is also working perfectly)
if rfkill list wifi | grep -q "Soft blocked: yes"; then
    echo "{\"text\":\"睊 Wi-Fi Off\", \"tooltip\":\"Wi-Fi is off. Click to enable.\", \"class\":\"wifi-off\"}"
    exit 0
fi

# 3. THIS IS THE CORRECTED PART: Check for an active Wi-Fi connection
# We check if the Wi-Fi interface has an IP address. This is the most reliable method.
if ip addr show "$WIFI_INTERFACE" | grep -q "inet "; then
    # If it has an IP, it's connected. Get the details.
    SSID=$(nmcli -t -f IN-USE,SSID dev wifi | grep '^\*:' | cut -d ':' -f 2)
    SIGNAL=$(nmcli -t -f IN-USE,SIGNAL dev wifi | grep '^\*:' | cut -d ':' -f 2)
    echo "{\"text\":\" ${SSID} (${SIGNAL}%)\", \"tooltip\":\"Connected to ${SSID}\", \"class\":\"wifi-connected\"}"
else
    # If there's no IP, the radio is on but not connected to a network.
    echo "{\"text\":\"睊 Disconnected\", \"tooltip\":\"Wi-Fi is disconnected. Click the tray icon to connect.\", \"class\":\"wifi-disconnected\"}"
fi
