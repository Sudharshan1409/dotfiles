#!/bin/bash

# Wrapper to start monitor event listener with proper environment
# This ensures DBUS and DISPLAY are available for notifications

# Source the systemd user environment
if [ -d /run/user/$(id -u) ]; then
    # Try to find DBUS session bus
    for bus in /run/user/$(id -u)/bus; do
        if [ -S "$bus" ]; then
            export DBUS_SESSION_BUS_ADDRESS="unix:path=$bus"
            break
        fi
    done
fi

# Set DISPLAY if available
if [ -z "$DISPLAY" ]; then
    for disp in :0 :1; do
        if [ -S "/tmp/.X11-unix/X${disp#:}" ]; then
            export DISPLAY="$disp"
            break
        fi
    done
fi

# Set WAYLAND_DISPLAY if not set
if [ -z "$WAYLAND_DISPLAY" ] && [ -S "/run/user/$(id -u)/wayland-0" ]; then
    export WAYLAND_DISPLAY="wayland-0"
fi

# Wait for swaync to be ready (notification daemon)
for i in {1..30}; do
    if pgrep -x "swaync" > /dev/null; then
        break
    fi
    sleep 0.5
done

# Log the environment for debugging
echo "$(date): Starting monitor listener with DISPLAY=$DISPLAY, DBUS=$DBUS_SESSION_BUS_ADDRESS" >> "$HOME/.config/hypr/.logs/monitor_wrapper.log"

# Test if notifications are working
if notify-send "Monitor Profile" "Monitor event listener started" 2>/dev/null; then
    echo "$(date): Test notification sent successfully" >> "$HOME/.config/hypr/.logs/monitor_wrapper.log"
else
    echo "$(date): Test notification failed" >> "$HOME/.config/hypr/.logs/monitor_wrapper.log"
fi

# Start the actual listener
exec "$HOME/.config/hypr/scripts/monitor_event_listener.sh"
