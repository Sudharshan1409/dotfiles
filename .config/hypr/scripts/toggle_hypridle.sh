#!/bin/bash

if pgrep -x "hypridle" > /dev/null; then
    killall hypridle
    notify-send -i "process-stop" -a "Hypridle" "Hypridle" "Disabled"
else
    hypridle &
    notify-send -i "system-run" -a "Hypridle" "Hypridle" "Enabled"
fi
