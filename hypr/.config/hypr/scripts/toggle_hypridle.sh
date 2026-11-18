#!/bin/bash

# Legacy Waybar caffeine script (stops/starts hypridle directly):
# exec "$HOME/.config/waybar/scripts/caffeine.sh" toggle

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# Ensure hypridle stays running so before_sleep_cmd / after_sleep_cmd always work
if ! pgrep -x "hypridle" >/dev/null 2>&1; then
    if command -v hyprctl >/dev/null 2>&1; then
        hyprctl repl 'hl.exec_cmd("hypridle")' >/dev/null 2>&1
    else
        nohup hypridle >/dev/null 2>&1 &
    fi
fi

# Toggle Caelestia Shell's native Wayland idle inhibitor (falls back to caffeine.sh if Caelestia isn't active)
if caelestia shell idleInhibitor toggle >/dev/null 2>&1; then
    STATE="$(caelestia shell idleInhibitor isEnabled 2>/dev/null | tr -d '[:space:]')"
    if [ "$STATE" = "true" ]; then
        notify-send \
            -a "Keep Awake" \
            -h string:x-canonical-private-synchronous:caffeine \
            -u normal \
            -i "preferences-desktop-screensaver" \
            "☕ Keep Awake Enabled" \
            "Idle timeouts paused (no auto-dim or auto-lock).\nScreen still locks on suspend or lid close." \
            -t 3000
    else
        notify-send \
            -a "Keep Awake" \
            -h string:x-canonical-private-synchronous:caffeine \
            -u normal \
            -i "system-lock-screen" \
            "💤 Keep Awake Disabled" \
            "Normal power management restored.\nScreen will dim and lock after idle timeout." \
            -t 3000
    fi
else
    exec "$HOME/.config/waybar/scripts/caffeine.sh" toggle
fi
