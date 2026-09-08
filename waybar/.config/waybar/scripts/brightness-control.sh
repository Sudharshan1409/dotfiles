#!/bin/bash

# Brightness Control Script with OSD Notifications
# Supports: brightnessctl, systemd-logind DBus fallback (rootless), and OSD notifications

STEP_PERCENT=5

# Detect backlight device
BACKLIGHT_DEV=$(ls -1 /sys/class/backlight 2>/dev/null | head -1)

get_brightness_percent() {
    if [ -n "$BACKLIGHT_DEV" ] && [ -f "/sys/class/backlight/$BACKLIGHT_DEV/max_brightness" ]; then
        local max cur
        max=$(cat "/sys/class/backlight/$BACKLIGHT_DEV/max_brightness" 2>/dev/null)
        cur=$(cat "/sys/class/backlight/$BACKLIGHT_DEV/brightness" 2>/dev/null)
        if [ -n "$max" ] && [ "$max" -gt 0 ] && [ -n "$cur" ]; then
            echo $(( cur * 100 / max ))
            return
        fi
    fi
    if command -v brightnessctl >/dev/null 2>&1; then
        brightnessctl -m 2>/dev/null | cut -d',' -f4 | tr -d '%'
        return
    fi
    echo "50"
}

set_brightness() {
    local action="$1"
    local handled=false

    # 1. Try brightnessctl first
    if command -v brightnessctl >/dev/null 2>&1; then
        if [ "$action" = "up" ]; then
            if brightnessctl -q set +${STEP_PERCENT}% >/dev/null 2>&1; then
                handled=true
            fi
        elif [ "$action" = "down" ]; then
            if brightnessctl -q set ${STEP_PERCENT}%- >/dev/null 2>&1; then
                handled=true
            fi
        fi
    fi

    # 2. If brightnessctl failed (e.g. Permission denied), fallback to systemd-logind DBus
    if [ "$handled" = false ] && [ -n "$BACKLIGHT_DEV" ]; then
        local max cur step new
        max=$(cat "/sys/class/backlight/$BACKLIGHT_DEV/max_brightness" 2>/dev/null)
        cur=$(cat "/sys/class/backlight/$BACKLIGHT_DEV/brightness" 2>/dev/null)
        if [ -n "$max" ] && [ "$max" -gt 0 ] && [ -n "$cur" ]; then
            step=$(( max * STEP_PERCENT / 100 ))
            [ "$step" -lt 1 ] && step=1
            if [ "$action" = "up" ]; then
                new=$(( cur + step ))
                [ "$new" -gt "$max" ] && new=$max
            elif [ "$action" = "down" ]; then
                new=$(( cur - step ))
                # Minimum 1% so the screen is never completely pitch black
                local min=$(( max / 100 ))
                [ "$min" -lt 1 ] && min=1
                [ "$new" -lt "$min" ] && new=$min
            fi
            busctl call org.freedesktop.login1 /org/freedesktop/login1/session/auto \
                org.freedesktop.login1.Session SetBrightness ssu \
                "backlight" "$BACKLIGHT_DEV" "$new" >/dev/null 2>&1
        fi
    fi
}

send_notification() {
    local percent
    percent=$(get_brightness_percent)

    local icon="display-brightness-symbolic"
    if [ "$percent" -lt 33 ]; then
        icon="display-brightness-low-symbolic"
    elif [ "$percent" -lt 67 ]; then
        icon="display-brightness-medium-symbolic"
    else
        icon="display-brightness-high-symbolic"
    fi

    notify-send \
        -h string:x-canonical-private-synchronous:brightness \
        -h int:value:"$percent" \
        -u low \
        -i "$icon" \
        "Brightness" "${percent}%"
}

case "$1" in
    up)
        set_brightness "up"
        send_notification
        ;;
    down)
        set_brightness "down"
        send_notification
        ;;
    get)
        get_brightness_percent
        ;;
    *)
        echo "Usage: $0 {up|down|get}"
        exit 1
        ;;
esac
