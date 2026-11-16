#!/bin/bash

# Battery monitor: low-charge notifications + auto power-profile switching.
# Polls every $POLL_INTERVAL seconds; runs as a long-lived background process
# started from autostart.conf.
#
# Behavior:
#   AC plugged in  -> powerprofilesctl performance (or balanced if perf absent)
#   On battery >30 -> balanced
#   On battery ≤30 -> power-saver
# Threshold one-shots (only re-fire after AC has been plugged in):
#   ≤20% normal urgency, ≤10% critical, ≤5% urgent
# AC transitions and full-charge get their own short toasts.

POLL_INTERVAL=30
LOCK_FILE="/run/user/$(id -u)/battery_monitor.lock"

# Single-instance lock
if [ -f "$LOCK_FILE" ]; then
    pid=$(cat "$LOCK_FILE" 2>/dev/null)
    if [ -n "$pid" ] && ps -p "$pid" -o cmd= 2>/dev/null | grep -q battery_monitor; then
        exit 0
    fi
    rm -f "$LOCK_FILE"
fi
echo $$ > "$LOCK_FILE"
trap 'rm -f "$LOCK_FILE"; exit 0' EXIT INT TERM

# Auto-detect battery and AC paths (handles BAT0/BAT1, AC/ADP1/ACAD)
BAT=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
AC=$(ls -d /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/ACAD* 2>/dev/null | head -1)

if [ -z "$BAT" ]; then
    # No battery -> nothing to monitor, exit quietly
    exit 0
fi

profile_available() {
    powerprofilesctl list 2>/dev/null | grep -qE "^[[:space:]]*\*?[[:space:]]*$1:"
}

apply_profile() {
    command -v powerprofilesctl >/dev/null 2>&1 || return
    local desired="$1"
    local current
    current=$(powerprofilesctl get 2>/dev/null)
    [ "$current" = "$desired" ] && return
    powerprofilesctl set "$desired" 2>/dev/null
}

# In-memory state (resets when the script restarts — that's intentional)
last_ac=""
notified_20=0
notified_10=0
notified_5=0
notified_full=0

while true; do
    [ -f "$BAT/capacity" ] || { sleep "$POLL_INTERVAL"; continue; }

    capacity=$(cat "$BAT/capacity" 2>/dev/null)
    status=$(cat "$BAT/status" 2>/dev/null)
    ac_online=0
    [ -n "$AC" ] && ac_online=$(cat "$AC/online" 2>/dev/null)

    # --- AC state transition ---
    if [ "$ac_online" != "$last_ac" ]; then
        if [ -n "$last_ac" ]; then  # skip the first iteration so we don't spam on boot
            if [ "$ac_online" = "1" ]; then
                notify-send "Power" "🔌 Charging" -i battery-good -t 3000
                # Reset low-battery one-shots — they'll re-arm on next discharge
                notified_20=0; notified_10=0; notified_5=0
            else
                notify-send "Power" "🔋 On battery ($capacity%)" -i battery -t 3000
            fi
        fi
        last_ac="$ac_online"
    fi

    # --- Auto power profile ---
    if [ "$ac_online" = "1" ]; then
        if profile_available performance; then
            apply_profile performance
        else
            apply_profile balanced
        fi
    else
        if [ "$capacity" -le 30 ] && profile_available power-saver; then
            apply_profile power-saver
        else
            apply_profile balanced
        fi
    fi

    # --- Low-battery thresholds (only when discharging) ---
    if [ "$ac_online" = "0" ]; then
        if [ "$capacity" -le 5 ] && [ "$notified_5" = "0" ]; then
            notify-send "Battery Critical" \
                "🚨 Battery at $capacity%!\nPlug in NOW or save your work." \
                -i battery-empty -u critical -t 10000
            notified_5=1
        elif [ "$capacity" -le 10 ] && [ "$notified_10" = "0" ]; then
            notify-send "Battery Critical" \
                "⚠️ Battery at $capacity%\nPlug in soon." \
                -i battery-caution -u critical -t 7000
            notified_10=1
        elif [ "$capacity" -le 20 ] && [ "$notified_20" = "0" ]; then
            notify-send "Battery Low" \
                "🔋 Battery at $capacity%" \
                -i battery-low -u normal -t 5000
            notified_20=1
        fi
    fi

    # --- Full charge (one-shot, re-arms when capacity drops) ---
    if [ "$capacity" -ge 100 ] && [ "$status" = "Full" ]; then
        if [ "$notified_full" = "0" ]; then
            notify-send "Battery" "✅ Battery fully charged" -i battery-full -t 4000
            notified_full=1
        fi
    else
        notified_full=0
    fi

    sleep "$POLL_INTERVAL"
done
