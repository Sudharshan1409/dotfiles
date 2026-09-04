#!/bin/bash

# Wrapper to start monitor event listener, ensuring no stale instances

LOG_FILE="$HOME/.config/hypr/.logs/monitor_launcher.log"
mkdir -p "$(dirname "$LOG_FILE")"

echo "$(date): Launcher starting..." >> "$LOG_FILE"

# Kill any existing instances
echo "$(date): Killing existing instances..." >> "$LOG_FILE"
pkill -9 -f "monitor_event_listener.sh" 2>/dev/null

# Wait a moment
sleep 1

# Clear any stale locks
rm -f /run/user/$(id -u)/monitor_profile_*.lock 2>/dev/null

echo "$(date): Starting listener..." >> "$LOG_FILE"

# Start the listener
exec "$HOME/.config/hypr/scripts/monitor_event_listener.sh"
