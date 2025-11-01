#!/bin/bash

# This script installs the sudoers rules required for the Waybar scripts.
# It must be run with sudo.

if [ -z "$SUDO_USER" ] || [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run with sudo." >&2
  exit 1
fi

# Define the sudoers rules, using the user who invoked sudo
USERNAME=$SUDO_USER
WAYBAR_CONFIG_DIR=$(dirname "$0")/..
# Get absolute path
WAYBAR_CONFIG_DIR=$(cd "$WAYBAR_CONFIG_DIR" && pwd)

# Find the path to rfkill
RFKILL_PATH=$(command -v rfkill)
if [ -z "$RFKILL_PATH" ]; then
  echo "Error: rfkill command not found." >&2
  exit 1
fi

SUDO_RULES="
# Sudo rules for Waybar scripts for user $USERNAME

# Allow toggling bluetooth and wifi without password from Waybar scripts
$USERNAME ALL=(ALL) NOPASSWD: $RFKILL_PATH toggle bluetooth
$USERNAME ALL=(ALL) NOPASSWD: $RFKILL_PATH toggle wifi

# Allow running the wifi menu script without password
$USERNAME ALL=(ALL) NOPASSWD: $WAYBAR_CONFIG_DIR/scripts/wifi-menu.sh
"

# Path to the new sudoers file
SUDOERS_FILE="/etc/sudoers.d/waybar-scripts-$USERNAME"

# Write the rules to the file
echo "Creating sudoers file at $SUDOERS_FILE..."
echo "$SUDO_RULES" > "$SUDOERS_FILE"

# Set the correct permissions
chmod 0440 "$SUDOERS_FILE"

echo "Sudoers file created successfully."
echo "The following rules have been added:"
echo "$SUDO_RULES"
