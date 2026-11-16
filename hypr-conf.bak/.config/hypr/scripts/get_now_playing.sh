#!/bin/bash

# Soft pastel colors
GREEN="<span foreground='#8FBC8F'>"   # soft sage green
YELLOW="<span foreground='#E6DDAA'>"  # muted warm yellow
RESET="</span>"

players=$(playerctl -l 2>/dev/null)

# Check for playing players
for player in $players; do
    status=$(playerctl -p "$player" status 2>/dev/null)
    if [ "$status" = "Playing" ]; then
        artist=$(playerctl -p "$player" metadata artist)
        title=$(playerctl -p "$player" metadata title)
        echo "${GREEN}󰎈 Now Playing:${RESET} $artist - $title"
        exit
    fi
done

# Check for paused players
for player in $players; do
    status=$(playerctl -p "$player" status 2>/dev/null)
    if [ "$status" = "Paused" ]; then
        artist=$(playerctl -p "$player" metadata artist)
        title=$(playerctl -p "$player" metadata title)
        echo "${YELLOW}󰏤 Paused:${RESET} $artist - $title"
        exit
    fi
done

echo ""

