#!/bin/bash

# Volume Control Script with OSD Notifications
# Supports: pamixer, wpctl fallback, auto-unmute on volume up, and OSD notifications

MAX_VOLUME=153
STEP=5

get_volume() {
    if command -v pamixer >/dev/null 2>&1; then
        pamixer --get-volume 2>/dev/null || echo "0"
    elif command -v wpctl >/dev/null 2>&1; then
        local raw
        raw=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print $2}')
        awk "BEGIN {printf \"%d\", $raw * 100}" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

is_muted() {
    if command -v pamixer >/dev/null 2>&1; then
        pamixer --get-mute 2>/dev/null
    elif command -v wpctl >/dev/null 2>&1; then
        if wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -q "\[MUTED\]"; then
            echo "true"
        else
            echo "false"
        fi
    else
        echo "false"
    fi
}

send_notification() {
    local muted
    muted=$(is_muted)
    local vol
    vol=$(get_volume)

    if [ "$muted" = "true" ]; then
        notify-send \
            -h string:x-canonical-private-synchronous:volume \
            -h int:value:0 \
            -u low \
            -i "audio-volume-muted-symbolic" \
            "Volume" "Muted"
    else
        local icon="audio-volume-high-symbolic"
        if [ "$vol" -eq 0 ]; then
            icon="audio-volume-muted-symbolic"
        elif [ "$vol" -lt 33 ]; then
            icon="audio-volume-low-symbolic"
        elif [ "$vol" -lt 67 ]; then
            icon="audio-volume-medium-symbolic"
        fi

        notify-send \
            -h string:x-canonical-private-synchronous:volume \
            -h int:value:"$vol" \
            -u low \
            -i "$icon" \
            "Volume" "${vol}%"
    fi
}

case $1 in
    up)
        if command -v pamixer >/dev/null 2>&1; then
            # If muted, unmute when increasing volume
            if [ "$(pamixer --get-mute)" = "true" ]; then
                pamixer -u
            fi
            current=$(pamixer --get-volume)
            new=$((current + STEP))
            if [ "$new" -gt "$MAX_VOLUME" ]; then
                pamixer --allow-boost --set-volume $MAX_VOLUME
            else
                pamixer --allow-boost -i $STEP
            fi
        elif command -v wpctl >/dev/null 2>&1; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ 0
            wpctl set-volume -l 1.53 @DEFAULT_AUDIO_SINK@ ${STEP}%+
        fi
        send_notification
        ;;
    down)
        if command -v pamixer >/dev/null 2>&1; then
            current=$(pamixer --get-volume)
            if [ "$current" -gt 100 ]; then
                new_volume=$((current - STEP))
                pamixer --allow-boost --set-volume $new_volume
            else
                pamixer -d $STEP
            fi
        elif command -v wpctl >/dev/null 2>&1; then
            wpctl set-volume @DEFAULT_AUDIO_SINK@ ${STEP}%-
        fi
        send_notification
        ;;
    mute|toggle)
        if command -v pamixer >/dev/null 2>&1; then
            pamixer -t
        elif command -v wpctl >/dev/null 2>&1; then
            wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        fi
        send_notification
        ;;
    get)
        get_volume
        ;;
    *)
        echo "Usage: $0 {up|down|mute|toggle|get}"
        exit 1
        ;;
esac
