#!/bin/bash
# assign_workspaces.sh - Dynamically assign workspaces to monitors
# Called by kanshi after applying a monitor profile
#
# Usage: assign_workspaces.sh <profile_name> laptop=eDP-1 main=DP-1 [secondary=HDMI-A-1]
#
# Workspace distribution:
#   - 1 monitor:  All workspaces on that monitor
#   - 2 monitors: 1,3,5,7,9 on laptop; 2,4,6,8 on main
#   - 3 monitors: 1,4,7 on laptop; 2,5,8 on main; 3,6,9 on secondary

# Ensure we have access to the user's D-Bus session for notifications
if [[ -z "$DBUS_SESSION_BUS_ADDRESS" ]]; then
    export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"
fi

# First argument is the profile name
PROFILE_NAME="$1"
shift

# Parse remaining arguments
declare -A MONITORS
for arg in "$@"; do
    key="${arg%%=*}"
    value="${arg#*=}"
    MONITORS[$key]="$value"
done

LAPTOP="${MONITORS[laptop]}"
MAIN="${MONITORS[main]}"
SECONDARY="${MONITORS[secondary]}"

# Count connected external monitors
MONITOR_COUNT=0
[[ -n "$LAPTOP" ]] && ((MONITOR_COUNT++))
[[ -n "$MAIN" ]] && ((MONITOR_COUNT++))
[[ -n "$SECONDARY" ]] && ((MONITOR_COUNT++))

# Small delay to ensure monitors are ready
sleep 0.5

assign_workspace() {
    local ws=$1
    local monitor=$2
    hyprctl keyword workspace "$ws,monitor:$monitor" >/dev/null 2>&1
}

case $MONITOR_COUNT in
    1)
        # Single monitor - all workspaces
        for ws in {1..9}; do
            assign_workspace $ws "$LAPTOP"
        done
        ;;
    2)
        # Two monitors - laptop gets odd, main gets even
        for ws in 1 3 5 7 9; do
            assign_workspace $ws "$LAPTOP"
        done
        for ws in 2 4 6 8; do
            assign_workspace $ws "$MAIN"
        done
        ;;
    3)
        # Three monitors - distribute evenly
        for ws in 1 4 7; do
            assign_workspace $ws "$LAPTOP"
        done
        for ws in 2 5 8; do
            assign_workspace $ws "$MAIN"
        done
        for ws in 3 6 9; do
            assign_workspace $ws "$SECONDARY"
        done
        ;;
esac

# Log the configuration
logger -t kanshi-workspaces "Profile: $PROFILE_NAME | laptop=$LAPTOP main=$MAIN secondary=$SECONDARY (count=$MONITOR_COUNT)"

# Build layout string
LAYOUT=""
[[ -n "$LAPTOP" ]] && LAYOUT="$LAPTOP"
[[ -n "$MAIN" ]] && LAYOUT="$LAYOUT  $MAIN"
[[ -n "$SECONDARY" ]] && LAYOUT="$LAYOUT  $SECONDARY"

# Send notification with swaync-compatible options
notify-send \
    --app-name="kanshi" \
    --icon="video-display" \
    --urgency=normal \
    --expire-time=4000 \
    "Monitor Profile: $PROFILE_NAME" \
    "$MONITOR_COUNT monitor(s) - $LAYOUT"
