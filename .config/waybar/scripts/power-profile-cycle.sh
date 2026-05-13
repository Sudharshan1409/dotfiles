#!/bin/bash

NOTIF_APP="Power Profile"

if ! command -v powerprofilesctl &> /dev/null; then
    notify-send -a "$NOTIF_APP" -i "dialog-error" -u critical -t 4000 \
        "Power Profile Unavailable" \
        "powerprofilesctl is not installed."
    exit 0
fi

curr=$(powerprofilesctl get 2>/dev/null)
case "$curr" in
    power-saver) next=balanced ;;
    balanced)    next=performance ;;
    performance) next=power-saver ;;
    *)           next=balanced ;;
esac

if powerprofilesctl set "$next" 2>/dev/null; then
    case "$next" in
        power-saver)
            icon="power-profile-power-saver-symbolic"
            title="🍃 Power Saver"
            body="Battery-friendly mode\nPerformance reduced to extend battery life."
            ;;
        balanced)
            icon="power-profile-balanced-symbolic"
            title="⚖️ Balanced"
            body="Standard mode\nDefault performance and battery balance."
            ;;
        performance)
            icon="power-profile-performance-symbolic"
            title="🚀 Performance"
            body="Maximum performance\nHigher power draw — best when plugged in."
            ;;
    esac
    notify-send -a "$NOTIF_APP" -i "$icon" -u normal -t 3000 \
        -h "string:x-canonical-private-synchronous:power-profile" \
        "$title" "$body"
else
    notify-send -a "$NOTIF_APP" -i "dialog-error" -u critical -t 3000 \
        "Failed to switch profile" \
        "Could not set power profile to $next."
fi
