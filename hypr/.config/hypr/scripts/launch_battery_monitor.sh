#!/bin/bash

# Wrapper to start battery_monitor.sh, killing any stale instance first.
# Mirrors the launch_monitor_listener.sh pattern.

pkill -9 -f "battery_monitor.sh" 2>/dev/null
sleep 0.5
rm -f "/run/user/$(id -u)/battery_monitor.lock" 2>/dev/null

exec "$HOME/.config/hypr/scripts/battery_monitor.sh"
