#!/bin/bash

# --- Configuration ---
# Dynamically find the network interfaces
ETH_INTERFACE=$(nmcli -t -f DEVICE,TYPE,STATE device status | grep "ethernet:connected" | cut -d':' -f1 | head -n1)
WIFI_INTERFACE=$(nmcli -t -f DEVICE,TYPE,STATE device status | grep "wifi:connected" | cut -d':' -f1 | head -n1)

# If not connected, find the device names by other means
if [ -z "$ETH_INTERFACE" ]; then
    ETH_INTERFACE=$(nmcli -t -f DEVICE,TYPE device | grep "ethernet" | cut -d':' -f1 | head -n1)
fi
if [ -z "$WIFI_INTERFACE" ]; then
    WIFI_INTERFACE=$(nmcli -t -f DEVICE,TYPE device | grep "wifi" | cut -d':' -f1 | head -n1)
fi

# --- Main Logic ---

# 1. Check for Ethernet connection first
if [ -n "$ETH_INTERFACE" ] && ip addr show "$ETH_INTERFACE" | grep -q "inet "; then
    IP_ADDR=$(ip addr show "$ETH_INTERFACE" | grep "inet " | awk '{print $2}' | cut -d'/' -f1)
    echo "{\"text\":\" ${IP_ADDR}\", \"tooltip\":\"Ethernet (${ETH_INTERFACE}): ${IP_ADDR}\", \"class\":\"ethernet\"}"
    exit 0
fi

# 2. If no Ethernet, check if Wi-Fi radio is off
if rfkill list wifi | grep -q "Soft blocked: yes"; then
    echo "{\"text\":\"睊 Wi-Fi Off\", \"tooltip\":\"Wi-Fi is off. Click to enable.\", \"class\":\"wifi-off\"}"
    exit 0
fi

# 3. Check for an active Wi-Fi connection
if [ -n "$WIFI_INTERFACE" ] && ip addr show "$WIFI_INTERFACE" | grep -q "inet "; then
    # If it has an IP, it's connected. Get the details.
    SSID=$(nmcli -t -f IN-USE,SSID dev wifi | grep '^*:' | cut -d ':' -f 2)
    SIGNAL=$(nmcli -t -f IN-USE,SIGNAL dev wifi | grep '^*:' | cut -d ':' -f 2)
    echo "{\"text\":\" ${SSID} (${SIGNAL}%)\", \"tooltip\":\"Connected to ${SSID}\", \"class\":\"wifi-connected\"}"
else
    # If there's no IP, the radio is on but not connected to a network.
    echo "{\"text\":\"睊 Disconnected\", \"tooltip\":\"Wi-Fi is disconnected. Click the tray icon to connect.\", \"class\":\"wifi-disconnected\"}"
fi
