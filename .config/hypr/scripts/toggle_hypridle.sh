#!/bin/bash

if pgrep -x "hypridle" > /dev/null; then
    killall hypridle
    notify-send \
        --app-name="Hypridle" \
        --icon="process-stop" \
        --urgency=normal \
        "😴 Screen Lock Disabled" \
        "Hypridle has been stopped.\nScreen will not lock automatically." \
        -t 4000
else
    hypridle &
    notify-send \
        --app-name="Hypridle" \
        --icon="system-run" \
        --urgency=normal \
        "🔒 Screen Lock Enabled" \
        "Hypridle is now running.\nScreen will lock after idle timeout." \
        -t 4000
fi
