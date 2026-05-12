#!/bin/bash

# Focus Mode: toggle a "leave me alone" desktop state.
#
# ON:
#   - swaync DND on (notifications queued silently, replayed on exit)
#   - waybar hidden (SIGUSR1 is waybar's built-in visibility toggle)
#   - inactive windows dimmed so the focused window stands out
# OFF reverses all three.
#
# State is tracked via /tmp/focus_mode.state so the same key toggles cleanly.

STATE_FILE="/tmp/focus_mode.state"

if [ -f "$STATE_FILE" ]; then
    # --- Disable focus mode ---
    swaync-client -df >/dev/null 2>&1
    pkill -SIGUSR1 waybar
    hyprctl keyword decoration:dim_inactive false >/dev/null
    rm -f "$STATE_FILE"

    notify-send "Focus Mode" \
        "✓ Focus mode OFF\nBack to normal." \
        -i emblem-default -t 3000
else
    # --- Enable focus mode ---
    # Send the on-notification BEFORE enabling DND so it's actually visible.
    notify-send "Focus Mode" \
        "🎯 Focus mode ON\nNotifications silenced, distractions hidden." \
        -i emblem-important -t 3000

    # Small delay so the toast renders before DND mutes the channel.
    sleep 0.2

    swaync-client -dn >/dev/null 2>&1
    pkill -SIGUSR1 waybar
    hyprctl keyword decoration:dim_inactive true >/dev/null

    touch "$STATE_FILE"
fi
