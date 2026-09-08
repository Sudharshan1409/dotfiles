#!/bin/bash

# Caffeine / Idle Inhibitor Script for Waybar & Hyprland
# Toggles hypridle on and off, sends notifications, and signals Waybar for instant updates

SIGNAL=9

get_status() {
    if pgrep -x "hypridle" >/dev/null 2>&1; then
        # hypridle is running -> Caffeine is OFF (Screen will sleep/lock)
        cat << 'STATUS'
{"text": "󰾪", "alt": "deactivated", "tooltip": "Caffeine: OFF\nHypridle is running (sleep & lock active)\nClick to enable Caffeine (keep screen awake)", "class": "deactivated"}
STATUS
    else
        # hypridle is stopped -> Caffeine is ON (Screen stays awake)
        cat << 'STATUS'
{"text": "󰅶", "alt": "activated", "tooltip": "Caffeine: ON\nHypridle is stopped (screen will stay awake)\nClick to disable Caffeine (allow sleep & lock)", "class": "activated"}
STATUS
    fi
}

toggle() {
    if pgrep -x "hypridle" >/dev/null 2>&1; then
        # Stop hypridle
        killall -q hypridle
        sleep 0.1
        notify-send \
            -h string:x-canonical-private-synchronous:caffeine \
            -u normal \
            -i "process-stop" \
            "☕ Caffeine Enabled" \
            "Hypridle has been stopped.\nScreen will NOT dim, sleep, or lock." \
            -t 3000
    else
        # Start hypridle in background
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch exec hypridle >/dev/null 2>&1
        else
            nohup hypridle >/dev/null 2>&1 &
        fi
        sleep 0.2
        notify-send \
            -h string:x-canonical-private-synchronous:caffeine \
            -u normal \
            -i "system-run" \
            "💤 Caffeine Disabled" \
            "Hypridle is now running.\nScreen will lock and sleep after idle timeout." \
            -t 3000
    fi
    pkill -RTMIN+$SIGNAL waybar 2>/dev/null || true
}

case "$1" in
    toggle)
        toggle
        ;;
    status|*)
        get_status
        ;;
esac
