#!/bin/bash

export PATH="$HOME/.local/bin:/usr/local/bin:$PATH"

# Toggle Caelestia Shell's native Wayland idle inhibitor
if caelestia shell idleInhibitor toggle >/dev/null 2>&1; then
    STATE="$(caelestia shell idleInhibitor isEnabled 2>/dev/null | tr -d '[:space:]')"
    if [ "$STATE" = "true" ]; then
        notify-send \
            -a "Keep Awake" \
            -h string:x-canonical-private-synchronous:caffeine \
            -u normal \
            -i "preferences-desktop-screensaver" \
            "☕ Keep Awake Enabled" \
            "Idle timeouts paused (no auto-lock or screen blanking).\nScreen still locks on suspend or lid close." \
            -t 3000
    else
        notify-send \
            -a "Keep Awake" \
            -h string:x-canonical-private-synchronous:caffeine \
            -u normal \
            -i "system-lock-screen" \
            "💤 Keep Awake Disabled" \
            "Normal power management restored.\nScreen will lock and power off after idle timeout." \
            -t 3000
    fi
fi
