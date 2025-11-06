#!/bin/bash

players=$(playerctl -l 2>/dev/null)

# Prioritize players that are currently playing
for player in $players; do
    status=$(playerctl -p "$player" status 2>/dev/null)
    if [ "$status" = "Playing" ]; then
        echo "󰎈 Now Playing: $(playerctl -p "$player" metadata artist) - $(playerctl -p "$player" metadata title)"
        exit
    fi
done

# If no player is playing, check for paused players
for player in $players; do
    status=$(playerctl -p "$player" status 2>/dev/null)
    if [ "$status" = "Paused" ]; then
        echo "󰏤 Paused: $(playerctl -p "$player" metadata artist) - $(playerctl -p "$player" metadata title)"
        exit
    fi
done

echo ""