#!/bin/bash

# --- Pre-flight Check: Ensure Wi-Fi is enabled ---
# Check if the Wi-Fi is soft-blocked by rfkill.
if rfkill list wifi | grep -q "Soft blocked: yes"; then
    # If it is, unblock it before proceeding.
    rfkill unblock wifi
    # Give the hardware a second to initialize. This is crucial.
    sleep 1
    # Also, signal Waybar to update its state immediately so it changes from "Off" to "Disconnected"
    pkill -SIGRTMIN+8 waybar
fi

# Now that we know Wi-Fi is on, we can scan.
# We add a small timeout to the rescan to handle cases where the device is slow to wake up.
nmcli device wifi rescan

# Get a list of available Wi-Fi networks with their SSID, security, and signal strength.
# Use awk to format it into a clean, aligned list for Rofi.
WIFI_LIST=$(nmcli -t -f SSID,SECURITY,SIGNAL dev wifi list --rescan yes | \
    awk -F ':' '{
        if ($2 != "") {
            icon = ""
        } else {
            icon = ""
        }
        # Print formatted string: "87%   My Home WiFi"
        printf "%-4s %s %s\n", $3"%", icon, $1
    }')

# Use Rofi to present the formatted list to the user
CHOSEN_NETWORK=$(echo -e "$WIFI_LIST" | rofi -dmenu -i -p "Wi-Fi Networks" -l 10)

# Exit if the user cancelled
if [ -z "$CHOSEN_NETWORK" ]; then
    exit 0
fi

# Extract the SSID from the chosen line.
SSID=$(echo "$CHOSEN_NETWORK" | sed 's/.*[] //')

# Check if a connection for this SSID is already active
if nmcli connection show --active | grep -q "$SSID"; then
    rofi -e "Already connected to '$SSID'."
    exit 0
fi

# Connect to the selected network.
if nmcli device wifi connect "$SSID" --ask; then
    notify-send "Connection Successful" "You are now connected to '$SSID'."
else
    notify-send "Connection Failed" "Could not connect to '$SSID'."
fi
